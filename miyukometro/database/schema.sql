-- ============================================
-- MIYUKOMETRO - SCHEMA DO BANCO DE DADOS
-- ============================================
-- Sistema de monitoramento com avaliações, comentários e níveis de perigo
-- Criado para Supabase PostgreSQL
-- Data: 22 de novembro de 2025
-- ============================================

-- Habilitar extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- TABELA: users
-- Armazena informações dos usuários (anônimos ou identificados)
-- ============================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL DEFAULT 'Anônimo',
    email VARCHAR(255) UNIQUE,
    is_anonymous BOOLEAN DEFAULT TRUE,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints de validação
    CONSTRAINT users_name_check CHECK (char_length(name) >= 1 AND char_length(name) <= 255),
    CONSTRAINT users_email_check CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' OR email IS NULL)
);

-- Índices para otimização de queries
CREATE INDEX idx_users_email ON public.users(email) WHERE email IS NOT NULL;
CREATE INDEX idx_users_created_at ON public.users(created_at DESC);
CREATE INDEX idx_users_is_anonymous ON public.users(is_anonymous);

-- ============================================
-- TABELA: reviews
-- Armazena todas as avaliações (comentários + votos)
-- ============================================
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    comment_text TEXT,
    is_positive BOOLEAN DEFAULT FALSE, -- true = like, false = dislike
    score_value INTEGER DEFAULT 10, -- pontos adicionados ao score de perigo
    ip_address INET, -- endereço IP para prevenir abuso
    user_agent TEXT, -- informações do navegador para análise
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ, -- soft delete para manter histórico
    
    -- Constraints de validação
    CONSTRAINT reviews_comment_length_check CHECK (
        char_length(comment_text) <= 5000 OR comment_text IS NULL
    ),
    CONSTRAINT reviews_score_check CHECK (score_value >= 0 AND score_value <= 100)
    -- Nota: Validação de "comentário OU arquivo" deve ser feita no nível da aplicação
    -- pois PostgreSQL não permite subqueries em CHECK constraints
);

-- Índices para otimização
CREATE INDEX idx_reviews_user_id ON public.reviews(user_id);
CREATE INDEX idx_reviews_created_at ON public.reviews(created_at DESC);
CREATE INDEX idx_reviews_is_positive ON public.reviews(is_positive);
CREATE INDEX idx_reviews_deleted_at ON public.reviews(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_reviews_ip_address ON public.reviews(ip_address);

-- ============================================
-- TABELA: files
-- Armazena metadados de arquivos anexados às avaliações
-- ============================================
CREATE TABLE IF NOT EXISTS public.files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID NOT NULL REFERENCES public.reviews(id) ON DELETE CASCADE,
    file_name VARCHAR(500) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    file_type VARCHAR(100),
    mime_type VARCHAR(100),
    storage_path TEXT NOT NULL, -- caminho no Supabase Storage
    storage_bucket VARCHAR(100) DEFAULT 'miyukometro-uploads',
    checksum VARCHAR(64), -- hash SHA-256 para verificar integridade
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints de validação
    CONSTRAINT files_name_check CHECK (char_length(file_name) >= 1 AND char_length(file_name) <= 500),
    CONSTRAINT files_size_check CHECK (file_size_bytes > 0 AND file_size_bytes <= 52428800), -- max 50MB
    CONSTRAINT files_storage_path_unique UNIQUE(storage_path)
);

-- Índices para otimização
CREATE INDEX idx_files_review_id ON public.files(review_id);
CREATE INDEX idx_files_uploaded_at ON public.files(uploaded_at DESC);
CREATE INDEX idx_files_file_type ON public.files(file_type);
CREATE INDEX idx_files_checksum ON public.files(checksum);

-- ============================================
-- TABELA: danger_levels
-- Registra histórico dos níveis de perigo do sistema
-- ============================================
CREATE TABLE IF NOT EXISTS public.danger_levels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    total_score INTEGER NOT NULL DEFAULT 0,
    level_name VARCHAR(20) NOT NULL, -- BAIXO, MÉDIO, ALTO, CRÍTICO
    level_percentage DECIMAL(5,2) NOT NULL, -- 0.00 a 100.00
    total_reviews INTEGER DEFAULT 0,
    total_dislikes INTEGER DEFAULT 0,
    total_likes INTEGER DEFAULT 0,
    calculated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints de validação
    CONSTRAINT danger_levels_score_check CHECK (total_score >= 0),
    CONSTRAINT danger_levels_percentage_check CHECK (level_percentage >= 0 AND level_percentage <= 100),
    CONSTRAINT danger_levels_name_check CHECK (
        level_name IN ('BAIXO', 'MÉDIO', 'ALTO', 'CRÍTICO')
    ),
    CONSTRAINT danger_levels_reviews_check CHECK (
        total_reviews >= 0 AND 
        total_dislikes >= 0 AND 
        total_likes >= 0 AND
        (total_dislikes + total_likes) = total_reviews
    )
);

-- Índices para otimização
CREATE INDEX idx_danger_levels_calculated_at ON public.danger_levels(calculated_at DESC);
CREATE INDEX idx_danger_levels_level_name ON public.danger_levels(level_name);
CREATE INDEX idx_danger_levels_total_score ON public.danger_levels(total_score DESC);

-- ============================================
-- TABELA: sessions
-- Rastreamento de sessões para controle de uso
-- ============================================
CREATE TABLE IF NOT EXISTS public.sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_token VARCHAR(255) UNIQUE NOT NULL,
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    ip_address INET,
    user_agent TEXT,
    last_activity TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '24 hours'),
    
    -- Constraints de validação
    CONSTRAINT sessions_token_check CHECK (char_length(session_token) >= 32)
);

-- Índices para otimização
CREATE INDEX idx_sessions_token ON public.sessions(session_token);
CREATE INDEX idx_sessions_user_id ON public.sessions(user_id);
CREATE INDEX idx_sessions_expires_at ON public.sessions(expires_at);
CREATE INDEX idx_sessions_last_activity ON public.sessions(last_activity DESC);

-- ============================================
-- TABELA: abuse_reports
-- Sistema de detecção e prevenção de abuso
-- ============================================
CREATE TABLE IF NOT EXISTS public.abuse_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ip_address INET NOT NULL,
    abuse_type VARCHAR(50) NOT NULL, -- spam, flood, malicious_content, etc
    review_id UUID REFERENCES public.reviews(id) ON DELETE SET NULL,
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    severity VARCHAR(20) DEFAULT 'low', -- low, medium, high, critical
    details JSONB,
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMPTZ,
    reported_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints de validação
    CONSTRAINT abuse_type_check CHECK (
        abuse_type IN ('spam', 'flood', 'malicious_content', 'suspicious_activity', 'rate_limit_exceeded', 'other')
    ),
    CONSTRAINT abuse_severity_check CHECK (
        severity IN ('low', 'medium', 'high', 'critical')
    )
);

-- Índices para otimização
CREATE INDEX idx_abuse_ip_address ON public.abuse_reports(ip_address);
CREATE INDEX idx_abuse_reported_at ON public.abuse_reports(reported_at DESC);
CREATE INDEX idx_abuse_is_resolved ON public.abuse_reports(is_resolved) WHERE is_resolved = FALSE;
CREATE INDEX idx_abuse_severity ON public.abuse_reports(severity);

-- ============================================
-- FUNÇÕES AUXILIARES
-- ============================================

-- Função para atualizar o campo updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Função para calcular o nível de perigo baseado no score
CREATE OR REPLACE FUNCTION calculate_danger_level(score INTEGER)
RETURNS VARCHAR(20) AS $$
BEGIN
    IF score < 30 THEN
        RETURN 'BAIXO';
    ELSIF score < 60 THEN
        RETURN 'MÉDIO';
    ELSIF score < 90 THEN
        RETURN 'ALTO';
    ELSE
        RETURN 'CRÍTICO';
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Função para registrar nível de perigo após nova avaliação
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

-- Função para detectar potencial abuso (rate limiting)
CREATE OR REPLACE FUNCTION check_rate_limit(
    p_ip_address INET,
    p_time_window INTERVAL DEFAULT '5 minutes',
    p_max_requests INTEGER DEFAULT 10
)
RETURNS BOOLEAN AS $$
DECLARE
    v_request_count INTEGER;
BEGIN
    -- Contar requisições recentes do mesmo IP
    SELECT COUNT(*)
    INTO v_request_count
    FROM public.reviews
    WHERE ip_address = p_ip_address
        AND created_at > (NOW() - p_time_window)
        AND deleted_at IS NULL;
    
    -- Se exceder o limite, registrar abuso e retornar FALSE
    IF v_request_count >= p_max_requests THEN
        INSERT INTO public.abuse_reports (ip_address, abuse_type, severity, details)
        VALUES (
            p_ip_address,
            'rate_limit_exceeded',
            'medium',
            jsonb_build_object(
                'request_count', v_request_count,
                'time_window', p_time_window::TEXT,
                'max_allowed', p_max_requests
            )
        );
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Função para obter estatísticas gerais do sistema
CREATE OR REPLACE FUNCTION get_system_stats()
RETURNS TABLE (
    total_users BIGINT,
    total_reviews BIGINT,
    total_files BIGINT,
    current_danger_score INTEGER,
    current_danger_level VARCHAR(20),
    total_storage_bytes BIGINT,
    avg_review_length NUMERIC,
    most_active_hour INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT u.id)::BIGINT,
        COUNT(DISTINCT r.id)::BIGINT,
        COUNT(DISTINCT f.id)::BIGINT,
        COALESCE(SUM(r.score_value), 0)::INTEGER,
        calculate_danger_level(COALESCE(SUM(r.score_value), 0)::INTEGER),
        COALESCE(SUM(f.file_size_bytes), 0)::BIGINT,
        ROUND(AVG(LENGTH(r.comment_text)), 2),
        MODE() WITHIN GROUP (ORDER BY EXTRACT(HOUR FROM r.created_at))::INTEGER
    FROM public.users u
    LEFT JOIN public.reviews r ON u.id = r.user_id AND r.deleted_at IS NULL
    LEFT JOIN public.files f ON r.id = f.review_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger para atualizar updated_at em users
CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger para atualizar updated_at em reviews
CREATE TRIGGER trigger_reviews_updated_at
    BEFORE UPDATE ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger para registrar nível de perigo após inserção de review
CREATE TRIGGER trigger_log_danger_level_insert
    AFTER INSERT ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION log_danger_level();

-- Trigger para registrar nível de perigo após atualização de review
CREATE TRIGGER trigger_log_danger_level_update
    AFTER UPDATE ON public.reviews
    FOR EACH ROW
    WHEN (OLD.score_value IS DISTINCT FROM NEW.score_value OR OLD.deleted_at IS DISTINCT FROM NEW.deleted_at)
    EXECUTE FUNCTION log_danger_level();

-- Trigger para atualizar sessão ao modificar atividade
CREATE TRIGGER trigger_sessions_activity
    BEFORE UPDATE ON public.sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VIEWS ÚTEIS
-- ============================================

-- View para listar reviews com informações do usuário e arquivos
CREATE OR REPLACE VIEW public.reviews_with_details AS
SELECT 
    r.id,
    r.user_id,
    u.name AS user_name,
    u.is_anonymous,
    r.comment_text,
    r.is_positive,
    r.score_value,
    r.created_at,
    r.updated_at,
    COALESCE(
        json_agg(
            json_build_object(
                'id', f.id,
                'file_name', f.file_name,
                'file_size', f.file_size_bytes,
                'file_type', f.file_type,
                'storage_path', f.storage_path
            )
        ) FILTER (WHERE f.id IS NOT NULL),
        '[]'::json
    ) AS files
FROM public.reviews r
JOIN public.users u ON r.user_id = u.id
LEFT JOIN public.files f ON r.id = f.review_id
WHERE r.deleted_at IS NULL
GROUP BY r.id, u.name, u.is_anonymous
ORDER BY r.created_at DESC;

-- View para dashboard de estatísticas em tempo real
CREATE OR REPLACE VIEW public.dashboard_stats AS
SELECT 
    (SELECT COUNT(*) FROM public.reviews WHERE deleted_at IS NULL) AS total_reviews,
    (SELECT COUNT(*) FROM public.users) AS total_users,
    (SELECT COUNT(*) FROM public.files) AS total_files,
    (SELECT COALESCE(SUM(score_value), 0) FROM public.reviews WHERE deleted_at IS NULL) AS current_score,
    (SELECT calculate_danger_level(COALESCE(SUM(score_value), 0)::INTEGER) FROM public.reviews WHERE deleted_at IS NULL) AS current_level,
    (SELECT COUNT(*) FROM public.reviews WHERE is_positive = FALSE AND deleted_at IS NULL) AS total_dislikes,
    (SELECT COUNT(*) FROM public.reviews WHERE is_positive = TRUE AND deleted_at IS NULL) AS total_likes,
    (SELECT COALESCE(SUM(file_size_bytes), 0) FROM public.files) AS total_storage_used;

-- ============================================
-- POLÍTICAS DE SEGURANÇA (RLS)
-- Serão configuradas no próximo arquivo
-- ============================================

-- Comentários para documentação
COMMENT ON TABLE public.users IS 'Tabela de usuários do sistema (anônimos e identificados)';
COMMENT ON TABLE public.reviews IS 'Tabela de avaliações/comentários com sistema de pontuação';
COMMENT ON TABLE public.files IS 'Metadados de arquivos anexados às avaliações';
COMMENT ON TABLE public.danger_levels IS 'Histórico dos níveis de perigo do sistema';
COMMENT ON TABLE public.sessions IS 'Controle de sessões de usuários';
COMMENT ON TABLE public.abuse_reports IS 'Sistema de detecção e reporte de abuso';

COMMENT ON FUNCTION calculate_danger_level(INTEGER) IS 'Calcula o nível de perigo baseado no score total';
COMMENT ON FUNCTION check_rate_limit(INET, INTERVAL, INTEGER) IS 'Verifica se um IP excedeu o rate limit permitido';
COMMENT ON FUNCTION get_system_stats() IS 'Retorna estatísticas gerais do sistema';
