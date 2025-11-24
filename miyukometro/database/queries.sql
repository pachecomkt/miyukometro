-- ============================================
-- MIYUKOMETRO - QUERIES DE EXEMPLO
-- ============================================
-- Coleção de queries úteis para operações comuns
-- Data: 22 de novembro de 2025
-- ============================================

-- ============================================
-- SEÇÃO 1: INSERÇÃO DE DADOS
-- ============================================

-- 1.1. Criar usuário anônimo
INSERT INTO users (name, is_anonymous)
VALUES ('Anônimo', true)
RETURNING *;

-- 1.2. Criar usuário identificado
INSERT INTO users (name, email, is_anonymous)
VALUES ('João Silva', 'joao@example.com', false)
RETURNING *;

-- 1.3. Criar review (dislike)
INSERT INTO reviews (user_id, comment_text, is_positive, score_value, ip_address)
VALUES (
    'uuid-do-usuario-aqui',
    'Este é um comentário de teste',
    false,
    10,
    '192.168.1.1'::inet
)
RETURNING *;

-- 1.4. Criar review com arquivo
-- Primeiro, insira a review
WITH new_review AS (
    INSERT INTO reviews (user_id, comment_text, is_positive, score_value, ip_address)
    VALUES (
        'uuid-do-usuario-aqui',
        'Review com anexo',
        false,
        10,
        '192.168.1.1'::inet
    )
    RETURNING id
)
-- Depois, insira o arquivo
INSERT INTO files (review_id, file_name, file_size_bytes, file_type, storage_path, checksum)
SELECT 
    id,
    'documento.pdf',
    1024000,
    'pdf',
    'uploads/2025/11/documento.pdf',
    'sha256_hash_aqui'
FROM new_review
RETURNING *;

-- 1.5. Criar sessão anônima (via função)
SELECT * FROM create_anonymous_session(
    '192.168.1.1'::inet,
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
);

-- ============================================
-- SEÇÃO 2: CONSULTAS BÁSICAS
-- ============================================

-- 2.1. Listar todas as reviews ativas (não deletadas)
SELECT * FROM reviews
WHERE deleted_at IS NULL
ORDER BY created_at DESC;

-- 2.2. Listar reviews com detalhes (usando view)
SELECT * FROM reviews_with_details
LIMIT 20;

-- 2.3. Buscar review por ID
SELECT * FROM reviews_with_details
WHERE id = 'uuid-da-review-aqui';

-- 2.4. Obter estatísticas do dashboard
SELECT * FROM dashboard_stats;

-- 2.5. Buscar usuário por email
SELECT * FROM users
WHERE email = 'joao@example.com';

-- 2.6. Listar arquivos de uma review
SELECT * FROM files
WHERE review_id = 'uuid-da-review-aqui';

-- ============================================
-- SEÇÃO 3: QUERIES DE ANÁLISE
-- ============================================

-- 3.1. Estatísticas gerais do sistema
SELECT * FROM get_system_stats();

-- 3.2. Nível de perigo atual
SELECT 
    total_score,
    level_name,
    level_percentage,
    total_reviews,
    total_dislikes,
    total_likes,
    calculated_at
FROM danger_levels
ORDER BY calculated_at DESC
LIMIT 1;

-- 3.3. Histórico de evolução do nível de perigo (últimos 30 registros)
SELECT 
    calculated_at,
    level_name,
    total_score,
    total_reviews
FROM danger_levels
ORDER BY calculated_at DESC
LIMIT 30;

-- 3.4. Gráfico de evolução do score (últimas 24 horas)
SELECT 
    DATE_TRUNC('hour', calculated_at) AS hour,
    MAX(total_score) AS score,
    MAX(level_name) AS level
FROM danger_levels
WHERE calculated_at > NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', calculated_at)
ORDER BY hour DESC;

-- 3.5. Top 10 usuários por número de reviews
SELECT 
    u.id,
    u.name,
    u.is_anonymous,
    COUNT(r.id) AS total_reviews,
    SUM(r.score_value) AS total_score_contributed
FROM users u
JOIN reviews r ON u.id = r.user_id
WHERE r.deleted_at IS NULL
GROUP BY u.id, u.name, u.is_anonymous
ORDER BY total_reviews DESC
LIMIT 10;

-- 3.6. Reviews mais recentes (últimas 50)
SELECT 
    r.comment_text,
    u.name AS author,
    r.created_at,
    r.score_value,
    CASE WHEN f.id IS NOT NULL THEN true ELSE false END AS has_file
FROM reviews r
JOIN users u ON r.user_id = u.id
LEFT JOIN files f ON r.id = f.review_id
WHERE r.deleted_at IS NULL
ORDER BY r.created_at DESC
LIMIT 50;

-- 3.7. Distribuição de reviews por horário do dia
SELECT 
    EXTRACT(HOUR FROM created_at) AS hour,
    COUNT(*) AS total_reviews
FROM reviews
WHERE deleted_at IS NULL
GROUP BY EXTRACT(HOUR FROM created_at)
ORDER BY hour;

-- 3.8. Distribuição por dia da semana
SELECT 
    TO_CHAR(created_at, 'Day') AS day_name,
    EXTRACT(DOW FROM created_at) AS day_number,
    COUNT(*) AS total_reviews
FROM reviews
WHERE deleted_at IS NULL
GROUP BY day_name, day_number
ORDER BY day_number;

-- ============================================
-- SEÇÃO 4: DETECÇÃO DE ABUSO
-- ============================================

-- 4.1. Verificar rate limit para um IP
SELECT check_rate_limit('192.168.1.1'::inet, '5 minutes', 10);

-- 4.2. Listar IPs com atividade suspeita (muitas reviews recentes)
SELECT 
    ip_address,
    COUNT(*) AS total_reviews,
    COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '5 minutes') AS recent_reviews,
    MAX(created_at) AS last_review
FROM reviews
WHERE deleted_at IS NULL
GROUP BY ip_address
HAVING COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '5 minutes') > 10
ORDER BY recent_reviews DESC;

-- 4.3. Relatórios de abuso não resolvidos
SELECT 
    id,
    ip_address,
    abuse_type,
    severity,
    reported_at,
    details
FROM abuse_reports
WHERE is_resolved = FALSE
ORDER BY severity DESC, reported_at DESC;

-- 4.4. Histórico de abuso por IP
SELECT 
    ip_address,
    abuse_type,
    COUNT(*) AS occurrences,
    MAX(reported_at) AS last_occurrence
FROM abuse_reports
GROUP BY ip_address, abuse_type
ORDER BY occurrences DESC;

-- 4.5. Resolver um caso de abuso
UPDATE abuse_reports
SET is_resolved = true, resolved_at = NOW()
WHERE id = 'uuid-do-reporte-aqui';

-- ============================================
-- SEÇÃO 5: GESTÃO DE SESSÕES
-- ============================================

-- 5.1. Listar sessões ativas
SELECT 
    s.id,
    s.session_token,
    u.name AS user_name,
    s.ip_address,
    s.created_at,
    s.expires_at,
    s.last_activity
FROM sessions s
LEFT JOIN users u ON s.user_id = u.id
WHERE s.expires_at > NOW()
ORDER BY s.last_activity DESC;

-- 5.2. Contar sessões ativas vs expiradas
SELECT 
    COUNT(*) FILTER (WHERE expires_at > NOW()) AS active_sessions,
    COUNT(*) FILTER (WHERE expires_at <= NOW()) AS expired_sessions,
    COUNT(*) AS total_sessions
FROM sessions;

-- 5.3. Limpar sessões expiradas manualmente
SELECT cleanup_expired_sessions();

-- 5.4. Revogar sessão específica (logout)
DELETE FROM sessions
WHERE session_token = 'token-da-sessao-aqui';

-- 5.5. Revogar todas as sessões de um usuário
DELETE FROM sessions
WHERE user_id = 'uuid-do-usuario-aqui';

-- ============================================
-- SEÇÃO 6: GESTÃO DE ARQUIVOS
-- ============================================

-- 6.1. Listar todos os arquivos com detalhes das reviews
SELECT 
    f.id,
    f.file_name,
    f.file_size_bytes,
    ROUND(f.file_size_bytes / 1024.0 / 1024.0, 2) AS size_mb,
    f.file_type,
    f.storage_path,
    r.comment_text,
    u.name AS uploaded_by,
    f.uploaded_at
FROM files f
JOIN reviews r ON f.review_id = r.id
JOIN users u ON r.user_id = u.id
WHERE r.deleted_at IS NULL
ORDER BY f.uploaded_at DESC;

-- 6.2. Estatísticas de storage
SELECT 
    COUNT(*) AS total_files,
    SUM(file_size_bytes) AS total_bytes,
    ROUND(SUM(file_size_bytes) / 1024.0 / 1024.0, 2) AS total_mb,
    ROUND(SUM(file_size_bytes) / 1024.0 / 1024.0 / 1024.0, 2) AS total_gb,
    AVG(file_size_bytes) AS avg_file_size,
    MAX(file_size_bytes) AS largest_file
FROM files;

-- 6.3. Distribuição por tipo de arquivo
SELECT 
    file_type,
    COUNT(*) AS count,
    ROUND(SUM(file_size_bytes) / 1024.0 / 1024.0, 2) AS total_mb
FROM files
GROUP BY file_type
ORDER BY count DESC;

-- 6.4. Arquivos órfãos (reviews deletadas)
SELECT f.*
FROM files f
LEFT JOIN reviews r ON f.review_id = r.id
WHERE r.deleted_at IS NOT NULL OR r.id IS NULL;

-- 6.5. Detectar arquivos duplicados (mesmo checksum)
SELECT 
    checksum,
    COUNT(*) AS duplicates,
    array_agg(file_name) AS file_names
FROM files
WHERE checksum IS NOT NULL
GROUP BY checksum
HAVING COUNT(*) > 1;

-- ============================================
-- SEÇÃO 7: ATUALIZAÇÃO DE DADOS
-- ============================================

-- 7.1. Atualizar comentário de uma review
UPDATE reviews
SET comment_text = 'Novo texto do comentário',
    updated_at = NOW()
WHERE id = 'uuid-da-review-aqui'
  AND deleted_at IS NULL;

-- 7.2. Soft delete de uma review
UPDATE reviews
SET deleted_at = NOW()
WHERE id = 'uuid-da-review-aqui';

-- 7.3. Restaurar review deletada (soft delete)
UPDATE reviews
SET deleted_at = NULL,
    updated_at = NOW()
WHERE id = 'uuid-da-review-aqui';

-- 7.4. Atualizar perfil de usuário
UPDATE users
SET 
    name = 'Novo Nome',
    avatar_url = 'https://example.com/avatar.jpg',
    updated_at = NOW()
WHERE id = 'uuid-do-usuario-aqui';

-- 7.5. Converter usuário anônimo em identificado
UPDATE users
SET 
    name = 'João Silva',
    email = 'joao@example.com',
    is_anonymous = false,
    updated_at = NOW()
WHERE id = 'uuid-do-usuario-aqui'
  AND is_anonymous = true;

-- ============================================
-- SEÇÃO 8: DELEÇÃO DE DADOS
-- ============================================

-- 8.1. Deletar review (soft delete preferido)
UPDATE reviews SET deleted_at = NOW()
WHERE id = 'uuid-da-review-aqui';

-- 8.2. Hard delete de review (cuidado!)
DELETE FROM reviews
WHERE id = 'uuid-da-review-aqui';

-- 8.3. Deletar arquivo
DELETE FROM files
WHERE id = 'uuid-do-arquivo-aqui';

-- 8.4. Deletar usuário e todas suas reviews (CASCADE)
DELETE FROM users
WHERE id = 'uuid-do-usuario-aqui';

-- 8.5. Limpar todas as reviews deletadas há mais de 30 dias
DELETE FROM reviews
WHERE deleted_at < NOW() - INTERVAL '30 days';

-- ============================================
-- SEÇÃO 9: MANUTENÇÃO E LIMPEZA
-- ============================================

-- 9.1. Limpar sessões expiradas
SELECT cleanup_expired_sessions();

-- 9.2. Vacuum e analyze (otimização)
VACUUM ANALYZE users;
VACUUM ANALYZE reviews;
VACUUM ANALYZE files;
VACUUM ANALYZE danger_levels;
VACUUM ANALYZE sessions;

-- 9.3. Reindexar tabelas
REINDEX TABLE users;
REINDEX TABLE reviews;
REINDEX TABLE files;

-- 9.4. Estatísticas de tamanho das tabelas
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- 9.5. Ver conexões ativas
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    query_start,
    LEFT(query, 50) AS query
FROM pg_stat_activity
WHERE datname = current_database()
ORDER BY query_start DESC;

-- ============================================
-- SEÇÃO 10: BACKUP E RESTORE
-- ============================================

-- 10.1. Exportar dados de reviews (formato JSON)
SELECT json_agg(row_to_json(r))
FROM (
    SELECT * FROM reviews_with_details
    LIMIT 1000
) r;

-- 10.2. Exportar estatísticas do sistema
COPY (
    SELECT * FROM dashboard_stats
) TO '/tmp/dashboard_stats.csv' CSV HEADER;

-- 10.3. Exportar histórico de danger_levels
COPY (
    SELECT * FROM danger_levels
    ORDER BY calculated_at DESC
) TO '/tmp/danger_levels_history.csv' CSV HEADER;

-- 10.4. Backup de configuração (funções, triggers, etc)
SELECT 
    pg_get_functiondef(p.oid) AS function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public';

-- ============================================
-- SEÇÃO 11: QUERIES AVANÇADAS
-- ============================================

-- 11.1. Análise de sentimento (ratio like/dislike)
SELECT 
    COUNT(*) FILTER (WHERE is_positive = true) AS likes,
    COUNT(*) FILTER (WHERE is_positive = false) AS dislikes,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE is_positive = true) / 
        NULLIF(COUNT(*), 0),
        2
    ) AS like_percentage
FROM reviews
WHERE deleted_at IS NULL;

-- 11.2. Média de caracteres por comentário
SELECT 
    ROUND(AVG(LENGTH(comment_text)), 2) AS avg_comment_length,
    MIN(LENGTH(comment_text)) AS min_length,
    MAX(LENGTH(comment_text)) AS max_length
FROM reviews
WHERE comment_text IS NOT NULL
  AND deleted_at IS NULL;

-- 11.3. Taxa de reviews com arquivo vs sem arquivo
SELECT 
    COUNT(*) FILTER (WHERE has_file) AS with_file,
    COUNT(*) FILTER (WHERE NOT has_file) AS without_file,
    ROUND(100.0 * COUNT(*) FILTER (WHERE has_file) / NULLIF(COUNT(*), 0), 2) AS percentage_with_file
FROM (
    SELECT 
        r.id,
        EXISTS(SELECT 1 FROM files f WHERE f.review_id = r.id) AS has_file
    FROM reviews r
    WHERE r.deleted_at IS NULL
) sub;

-- 11.4. Ranking de dias com mais reviews
SELECT 
    DATE(created_at) AS review_date,
    COUNT(*) AS reviews_count,
    SUM(score_value) AS score_added
FROM reviews
WHERE deleted_at IS NULL
GROUP BY DATE(created_at)
ORDER BY reviews_count DESC
LIMIT 10;

-- 11.5. Busca full-text em comentários (exemplo com PostgreSQL)
SELECT 
    r.id,
    r.comment_text,
    u.name,
    r.created_at,
    ts_rank(
        to_tsvector('portuguese', r.comment_text),
        plainto_tsquery('portuguese', 'palavra_busca')
    ) AS relevance
FROM reviews r
JOIN users u ON r.user_id = u.id
WHERE to_tsvector('portuguese', r.comment_text) @@ plainto_tsquery('portuguese', 'palavra_busca')
  AND r.deleted_at IS NULL
ORDER BY relevance DESC;

-- ============================================
-- SEÇÃO 12: DEBUGGING E TROUBLESHOOTING
-- ============================================

-- 12.1. Verificar políticas RLS ativas
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 12.2. Verificar triggers
SELECT 
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- 12.3. Verificar constraints
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_type;

-- 12.4. Verificar índices
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 12.5. Verificar permissões
SELECT 
    grantee,
    table_schema,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
ORDER BY table_name, grantee, privilege_type;
