-- ============================================
-- MIYUKOMETRO - POLÍTICAS DE SEGURANÇA (RLS)
-- ============================================
-- Row Level Security para controle de acesso granular
-- Data: 22 de novembro de 2025
-- ============================================

-- ============================================
-- HABILITAR RLS EM TODAS AS TABELAS
-- ============================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.danger_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.abuse_reports ENABLE ROW LEVEL SECURITY;

-- ============================================
-- POLÍTICAS PARA TABELA: users
-- ============================================

-- Permitir que qualquer pessoa crie um usuário (anônimo ou não)
CREATE POLICY "users_insert_policy"
ON public.users
FOR INSERT
TO public
WITH CHECK (true);

-- Usuários podem visualizar seus próprios dados
CREATE POLICY "users_select_own_policy"
ON public.users
FOR SELECT
TO public
USING (
    id = auth.uid() OR
    is_anonymous = true
);

-- Usuários podem atualizar apenas seus próprios dados
CREATE POLICY "users_update_own_policy"
ON public.users
FOR UPDATE
TO public
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Apenas administradores podem deletar usuários
CREATE POLICY "users_delete_admin_policy"
ON public.users
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid()
        AND email LIKE '%@admin.miyukometro.com'
    )
);

-- ============================================
-- POLÍTICAS PARA TABELA: reviews
-- ============================================

-- Qualquer pessoa pode inserir reviews (mas com rate limit via função)
CREATE POLICY "reviews_insert_policy"
ON public.reviews
FOR INSERT
TO public
WITH CHECK (
    -- Validar que o usuário existe
    EXISTS (SELECT 1 FROM public.users WHERE id = reviews.user_id)
    -- Rate limit será aplicado via função no backend
);

-- Qualquer pessoa pode visualizar reviews não deletados
CREATE POLICY "reviews_select_policy"
ON public.reviews
FOR SELECT
TO public
USING (deleted_at IS NULL);

-- Usuários podem atualizar apenas seus próprios reviews
CREATE POLICY "reviews_update_own_policy"
ON public.reviews
FOR UPDATE
TO public
USING (
    user_id = auth.uid() OR
    user_id IN (SELECT id FROM public.users WHERE is_anonymous = true AND id = reviews.user_id)
)
WITH CHECK (
    user_id = auth.uid() OR
    user_id IN (SELECT id FROM public.users WHERE is_anonymous = true AND id = reviews.user_id)
);

-- Soft delete: usuários podem marcar suas próprias reviews como deletadas
CREATE POLICY "reviews_soft_delete_own_policy"
ON public.reviews
FOR UPDATE
TO public
USING (
    user_id = auth.uid() OR
    user_id IN (SELECT id FROM public.users WHERE is_anonymous = true AND id = reviews.user_id)
)
WITH CHECK (deleted_at IS NOT NULL);

-- Apenas administradores podem fazer hard delete
CREATE POLICY "reviews_delete_admin_policy"
ON public.reviews
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid()
        AND email LIKE '%@admin.miyukometro.com'
    )
);

-- ============================================
-- POLÍTICAS PARA TABELA: files
-- ============================================

-- Inserção de arquivos permitida apenas para reviews existentes
CREATE POLICY "files_insert_policy"
ON public.files
FOR INSERT
TO public
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.reviews r
        WHERE r.id = files.review_id
        AND r.deleted_at IS NULL
    )
);

-- Qualquer pessoa pode visualizar metadados de arquivos de reviews não deletados
CREATE POLICY "files_select_policy"
ON public.files
FOR SELECT
TO public
USING (
    EXISTS (
        SELECT 1 FROM public.reviews r
        WHERE r.id = files.review_id
        AND r.deleted_at IS NULL
    )
);

-- Apenas o dono da review pode atualizar metadados do arquivo
CREATE POLICY "files_update_own_policy"
ON public.files
FOR UPDATE
TO public
USING (
    EXISTS (
        SELECT 1 FROM public.reviews r
        WHERE r.id = files.review_id
        AND (r.user_id = auth.uid() OR r.user_id IN (
            SELECT id FROM public.users WHERE is_anonymous = true AND id = r.user_id
        ))
    )
);

-- Apenas administradores ou donos da review podem deletar arquivos
CREATE POLICY "files_delete_policy"
ON public.files
FOR DELETE
TO public
USING (
    EXISTS (
        SELECT 1 FROM public.reviews r
        WHERE r.id = files.review_id
        AND (
            r.user_id = auth.uid() OR
            r.user_id IN (SELECT id FROM public.users WHERE is_anonymous = true AND id = r.user_id)
        )
    )
    OR
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid()
        AND email LIKE '%@admin.miyukometro.com'
    )
);

-- ============================================
-- POLÍTICAS PARA TABELA: danger_levels
-- ============================================

-- Qualquer pessoa pode visualizar o histórico de níveis de perigo
CREATE POLICY "danger_levels_select_policy"
ON public.danger_levels
FOR SELECT
TO public
USING (true);

-- Inserção permitida apenas para funções do sistema (triggers)
-- Desabilitar RLS para esta tabela permite que triggers funcionem
-- IMPORTANTE: Mantenha esta tabela protegida removendo permissões diretas de INSERT abaixo
CREATE POLICY "danger_levels_insert_system_only"
ON public.danger_levels
FOR INSERT
TO public
WITH CHECK (true); -- Permite inserção via triggers, mas removeremos GRANT INSERT abaixo

-- Ninguém pode atualizar ou deletar registros históricos
-- (dados imutáveis para auditoria)
CREATE POLICY "danger_levels_no_update"
ON public.danger_levels
FOR UPDATE
TO public
USING (false);

CREATE POLICY "danger_levels_no_delete"
ON public.danger_levels
FOR DELETE
TO public
USING (false);

-- ============================================
-- POLÍTICAS PARA TABELA: sessions
-- ============================================

-- Apenas o próprio usuário pode criar suas sessões
CREATE POLICY "sessions_insert_own_policy"
ON public.sessions
FOR INSERT
TO public
WITH CHECK (
    user_id = auth.uid() OR
    user_id IS NULL -- Permitir sessões anônimas
);

-- Usuários só podem ver suas próprias sessões
CREATE POLICY "sessions_select_own_policy"
ON public.sessions
FOR SELECT
TO public
USING (
    user_id = auth.uid() OR
    (user_id IS NULL AND session_token = current_setting('app.session_token', true))
);

-- Usuários só podem atualizar suas próprias sessões
CREATE POLICY "sessions_update_own_policy"
ON public.sessions
FOR UPDATE
TO public
USING (
    user_id = auth.uid() OR
    (user_id IS NULL AND session_token = current_setting('app.session_token', true))
);

-- Usuários só podem deletar suas próprias sessões (logout)
CREATE POLICY "sessions_delete_own_policy"
ON public.sessions
FOR DELETE
TO public
USING (
    user_id = auth.uid() OR
    (user_id IS NULL AND session_token = current_setting('app.session_token', true))
);

-- ============================================
-- POLÍTICAS PARA TABELA: abuse_reports
-- ============================================

-- Apenas administradores podem visualizar reportes de abuso
CREATE POLICY "abuse_reports_select_admin_policy"
ON public.abuse_reports
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid()
        AND email LIKE '%@admin.miyukometro.com'
    )
);

-- Sistema pode inserir reportes automaticamente (via função)
CREATE POLICY "abuse_reports_insert_system_policy"
ON public.abuse_reports
FOR INSERT
TO public
WITH CHECK (true);

-- Apenas administradores podem atualizar reportes (resolver casos)
CREATE POLICY "abuse_reports_update_admin_policy"
ON public.abuse_reports
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid()
        AND email LIKE '%@admin.miyukometro.com'
    )
);

-- Apenas administradores podem deletar reportes
CREATE POLICY "abuse_reports_delete_admin_policy"
ON public.abuse_reports
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid()
        AND email LIKE '%@admin.miyukometro.com'
    )
);

-- ============================================
-- POLÍTICAS PARA STORAGE (Supabase Storage)
-- ============================================

-- Nota: Estas políticas devem ser configuradas no Supabase Dashboard
-- ou via API do Supabase Storage

/*
Bucket: miyukometro-uploads

1. POLÍTICA DE UPLOAD:
   - Permitir upload apenas para usuários autenticados ou anônimos com sessão válida
   - Limitar tamanho de arquivo a 50MB
   - Limitar tipos de arquivo permitidos (imagens, PDFs, documentos)

2. POLÍTICA DE DOWNLOAD:
   - Permitir download público de todos os arquivos
   - Arquivos de reviews deletados devem ser inacessíveis

3. POLÍTICA DE DELETE:
   - Apenas o dono do arquivo ou administradores podem deletar
   - Delete em cascata quando review é deletado

Exemplo de política de upload no Storage:
```
CREATE POLICY "Upload files for reviews"
ON storage.objects FOR INSERT
TO public
WITH CHECK (
    bucket_id = 'miyukometro-uploads' AND
    (auth.role() = 'authenticated' OR 
     EXISTS (SELECT 1 FROM public.sessions WHERE session_token = current_setting('app.session_token', true)))
);
```

Exemplo de política de download no Storage:
```
CREATE POLICY "Public download"
ON storage.objects FOR SELECT
TO public
USING (
    bucket_id = 'miyukometro-uploads' AND
    EXISTS (
        SELECT 1 FROM public.files f
        JOIN public.reviews r ON f.review_id = r.id
        WHERE f.storage_path = name AND r.deleted_at IS NULL
    )
);
```
*/

-- ============================================
-- FUNÇÕES DE SEGURANÇA ADICIONAIS
-- ============================================

-- Função para verificar se usuário é admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid()
        AND email LIKE '%@admin.miyukometro.com'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para validar sessão anônima
CREATE OR REPLACE FUNCTION validate_anonymous_session(p_session_token VARCHAR)
RETURNS BOOLEAN AS $$
DECLARE
    v_valid BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.sessions
        WHERE session_token = p_session_token
        AND expires_at > NOW()
    ) INTO v_valid;
    
    RETURN v_valid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para sanitizar input de texto (prevenção XSS)
CREATE OR REPLACE FUNCTION sanitize_text(p_text TEXT)
RETURNS TEXT AS $$
BEGIN
    IF p_text IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Remove tags HTML básicas e scripts
    RETURN regexp_replace(
        regexp_replace(
            p_text,
            '<script[^>]*>.*?</script>',
            '',
            'gi'
        ),
        '<[^>]+>',
        '',
        'g'
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Função para gerar token de sessão seguro
CREATE OR REPLACE FUNCTION generate_session_token()
RETURNS VARCHAR AS $$
BEGIN
    RETURN encode(gen_random_bytes(32), 'hex');
END;
$$ LANGUAGE plpgsql;

-- Função para criar sessão anônima
CREATE OR REPLACE FUNCTION create_anonymous_session(
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS TABLE (
    session_id UUID,
    session_token VARCHAR,
    user_id UUID,
    expires_at TIMESTAMPTZ
) AS $$
DECLARE
    v_user_id UUID;
    v_session_id UUID;
    v_session_token VARCHAR;
    v_expires_at TIMESTAMPTZ;
BEGIN
    -- Criar usuário anônimo
    INSERT INTO public.users (name, is_anonymous)
    VALUES ('Anônimo', true)
    RETURNING id INTO v_user_id;
    
    -- Gerar token de sessão
    v_session_token := generate_session_token();
    v_expires_at := NOW() + INTERVAL '24 hours';
    
    -- Criar sessão
    INSERT INTO public.sessions (
        session_token,
        user_id,
        ip_address,
        user_agent,
        expires_at
    ) VALUES (
        v_session_token,
        v_user_id,
        p_ip_address,
        p_user_agent,
        v_expires_at
    ) RETURNING id INTO v_session_id;
    
    RETURN QUERY
    SELECT v_session_id, v_session_token, v_user_id, v_expires_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para limpar sessões expiradas (executar periodicamente)
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM public.sessions
    WHERE expires_at < NOW();
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- GRANTS E PERMISSÕES
-- ============================================

-- Revogar todas as permissões padrão
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;

-- Conceder permissões específicas para usuários autenticados
GRANT SELECT, INSERT ON public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.reviews TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.files TO authenticated;
GRANT SELECT ON public.danger_levels TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.sessions TO authenticated;

-- Conceder permissões para usuários anônimos (via RLS)
GRANT SELECT, INSERT ON public.users TO anon;
GRANT SELECT, INSERT ON public.reviews TO anon;
GRANT SELECT, INSERT ON public.files TO anon;
GRANT SELECT ON public.danger_levels TO anon;
GRANT SELECT, INSERT ON public.sessions TO anon;

-- Conceder acesso a views
GRANT SELECT ON public.reviews_with_details TO authenticated, anon;
GRANT SELECT ON public.dashboard_stats TO authenticated, anon;

-- Conceder execução de funções públicas
GRANT EXECUTE ON FUNCTION calculate_danger_level(INTEGER) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION check_rate_limit(INET, INTERVAL, INTEGER) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_system_stats() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION sanitize_text(TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION validate_anonymous_session(VARCHAR) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION create_anonymous_session(INET, TEXT) TO authenticated, anon;

-- Funções apenas para admins
GRANT EXECUTE ON FUNCTION is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_expired_sessions() TO authenticated;

-- ============================================
-- ÍNDICES ADICIONAIS DE SEGURANÇA
-- ============================================

-- Índice para detecção rápida de IPs suspeitos
CREATE INDEX idx_reviews_ip_created ON public.reviews(ip_address, created_at DESC)
WHERE deleted_at IS NULL;

-- Índice para auditoria de sessões
CREATE INDEX idx_sessions_user_created ON public.sessions(user_id, created_at DESC);

-- Índice para análise de abuso por IP
CREATE INDEX idx_abuse_ip_reported ON public.abuse_reports(ip_address, reported_at DESC)
WHERE is_resolved = FALSE;

-- ============================================
-- COMENTÁRIOS DE DOCUMENTAÇÃO
-- ============================================

COMMENT ON POLICY "users_insert_policy" ON public.users IS 
'Permite criação de usuários anônimos ou autenticados';

COMMENT ON POLICY "reviews_insert_policy" ON public.reviews IS 
'Permite inserção de reviews com validação de rate limit no backend';

COMMENT ON POLICY "files_select_policy" ON public.files IS 
'Permite visualização pública de metadados de arquivos de reviews ativos';

COMMENT ON FUNCTION is_admin() IS 
'Verifica se o usuário atual tem privilégios de administrador';

COMMENT ON FUNCTION create_anonymous_session(INET, TEXT) IS 
'Cria um usuário anônimo e sessão temporária para uso sem autenticação';

COMMENT ON FUNCTION sanitize_text(TEXT) IS 
'Remove tags HTML e scripts potencialmente perigosos do texto';
