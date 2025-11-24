-- ============================================
-- HOTFIX: Corrigir RLS da tabela danger_levels
-- ============================================
-- Problema: Triggers não conseguem inserir em danger_levels
-- Solução: Marcar função como SECURITY DEFINER e ajustar política
-- Data: 22 de novembro de 2025
-- ============================================

-- PASSO 1: Recriar função log_danger_level() com SECURITY DEFINER
DROP FUNCTION IF EXISTS log_danger_level() CASCADE;

CREATE OR REPLACE FUNCTION log_danger_level()
RETURNS TRIGGER AS $$
DECLARE
    v_total_score INTEGER;
    v_total_reviews INTEGER;
    v_total_dislikes INTEGER;
    v_total_likes INTEGER;
    v_level_name VARCHAR(20);
    v_percentage DECIMAL(5,2);
BEGIN
    -- Calcular estatísticas atuais (apenas reviews não deletados)
    SELECT 
        COALESCE(SUM(score_value), 0),
        COUNT(*),
        COUNT(*) FILTER (WHERE is_positive = FALSE),
        COUNT(*) FILTER (WHERE is_positive = TRUE)
    INTO v_total_score, v_total_reviews, v_total_dislikes, v_total_likes
    FROM public.reviews
    WHERE deleted_at IS NULL;
    
    -- Calcular nível e percentual
    v_level_name := calculate_danger_level(v_total_score);
    v_percentage := LEAST(v_total_score::DECIMAL, 100.00);
    
    -- Registrar no histórico
    INSERT INTO public.danger_levels (
        total_score,
        level_name,
        level_percentage,
        total_reviews,
        total_dislikes,
        total_likes
    ) VALUES (
        v_total_score,
        v_level_name,
        v_percentage,
        v_total_reviews,
        v_total_dislikes,
        v_total_likes
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASSO 2: Recriar os triggers (pois foram dropados em CASCADE)
CREATE TRIGGER trigger_log_danger_level_insert
    AFTER INSERT ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION log_danger_level();

CREATE TRIGGER trigger_log_danger_level_update
    AFTER UPDATE ON public.reviews
    FOR EACH ROW
    WHEN (OLD.score_value IS DISTINCT FROM NEW.score_value OR OLD.deleted_at IS DISTINCT FROM NEW.deleted_at)
    EXECUTE FUNCTION log_danger_level();

-- PASSO 3: Atualizar política de inserção
DROP POLICY IF EXISTS "danger_levels_insert_trigger_only" ON public.danger_levels;
DROP POLICY IF EXISTS "danger_levels_insert_system_only" ON public.danger_levels;

CREATE POLICY "danger_levels_insert_system_only"
ON public.danger_levels
FOR INSERT
TO public
WITH CHECK (true); -- Permite via SECURITY DEFINER, mas sem GRANT direto

-- ============================================
-- VERIFICAÇÃO
-- ============================================
-- Execute este SELECT para confirmar que tudo está OK:
-- SELECT routine_name, security_type 
-- FROM information_schema.routines 
-- WHERE routine_name = 'log_danger_level';
-- 
-- Deve retornar: security_type = 'DEFINER'
-- ============================================
