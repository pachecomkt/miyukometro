# ============================================
# INSTRUÇÕES DE INSTALAÇÃO - MIYUKOMETRO DB
# ============================================

Este guia passo-a-passo irá configurar completamente o banco de dados do Miyukometro no Supabase.

## 📋 PRÉ-REQUISITOS

1. ✅ Conta no Supabase (gratuita): https://supabase.com
2. ✅ Navegador web
3. ✅ Editor de texto (VS Code recomendado)

## 🚀 PASSO 1: Criar Projeto no Supabase

1. Acesse https://app.supabase.com
2. Faça login ou crie uma conta
3. Clique no botão **"New Project"**
4. Preencha os dados:
   - **Organization:** Selecione ou crie uma organização
   - **Name:** `miyukometro`
   - **Database Password:** Crie uma senha forte (GUARDE EM LOCAL SEGURO!)
   - **Region:** Escolha a região mais próxima (ex: South America - São Paulo)
   - **Pricing Plan:** Free tier (suficiente para começar)
5. Clique em **"Create new project"**
6. ⏱️ Aguarde 2-3 minutos enquanto o projeto é provisionado

## 🗄️ PASSO 2: Executar Script do Schema

1. No dashboard do Supabase, clique em **"SQL Editor"** no menu lateral
2. Clique em **"New Query"**
3. Abra o arquivo `database/schema.sql` neste projeto
4. Copie TODO o conteúdo do arquivo
5. Cole no editor SQL do Supabase
6. Clique em **"Run"** (ou pressione Ctrl+Enter)
7. ✅ Aguarde a mensagem de sucesso

**Verificação:**
Execute este query para confirmar:
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```
Você deve ver 6 tabelas: abuse_reports, danger_levels, files, reviews, sessions, users

## 🔐 PASSO 3: Configurar Segurança (RLS)

1. No SQL Editor, clique em **"New Query"** novamente
2. Abra o arquivo `database/security.sql`
3. Copie TODO o conteúdo
4. Cole no editor SQL
5. Clique em **"Run"**
6. ✅ Aguarde a mensagem de sucesso

**Verificação:**
Execute:
```sql
SELECT tablename, policyname FROM pg_policies 
WHERE schemaname = 'public';
```
Você deve ver múltiplas políticas configuradas

## 📦 PASSO 4: Configurar Storage

1. No menu lateral, clique em **"Storage"**
2. Clique em **"Create a new bucket"**
3. Configure:
   - **Name:** `miyukometro-uploads`
   - **Public bucket:** ✅ Marque esta opção
   - **File size limit:** `50 MB`
   - **Allowed MIME types:** Deixe em branco (ou configure manualmente)
4. Clique em **"Create bucket"**

**Configurar políticas do Storage:**

1. Clique no bucket `miyukometro-uploads`
2. Vá para aba **"Policies"**
3. Clique em **"New Policy"**

**Política de Upload:**
```sql
CREATE POLICY "Allow uploads for everyone"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (bucket_id = 'miyukometro-uploads');
```

**Política de Download:**
```sql
CREATE POLICY "Public downloads"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'miyukometro-uploads');
```

**Política de Delete:**
```sql
CREATE POLICY "Allow delete for owners"
ON storage.objects
FOR DELETE
TO public
USING (bucket_id = 'miyukometro-uploads');
```

## 🔑 PASSO 5: Obter Credenciais

1. No menu lateral, clique em **"Settings"** (ícone de engrenagem)
2. Clique em **"API"**
3. Copie as seguintes informações:

   📋 **Project URL:**
   ```
   Exemplo: https://xxxxxxxxxxx.supabase.co
   ```

   📋 **anon public (anon key):**
   ```
   Exemplo: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

   📋 **service_role (service_role key):**
   ```
   Exemplo: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ⚠️ MANTENHA SECRETO! Nunca exponha no frontend!
   ```

## 📝 PASSO 6: Configurar Variáveis de Ambiente

1. No projeto Miyukometro, copie o arquivo `.env.example`:
   ```bash
   cp .env.example .env
   ```

2. Abra o arquivo `.env` e preencha com suas credenciais:

   ```env
   SUPABASE_URL=https://seu-projeto.supabase.co
   SUPABASE_ANON_KEY=sua_anon_key_aqui
   SUPABASE_SERVICE_ROLE_KEY=sua_service_role_key_aqui
   ```

3. Configure outras variáveis conforme necessário

4. ⚠️ **IMPORTANTE:** Adicione `.env` ao `.gitignore`:
   ```
   # .gitignore
   .env
   .env.local
   .env.production
   ```

## ✅ PASSO 7: Testar Conexão

### Teste Manual no Supabase:

1. No SQL Editor, execute:
   ```sql
   -- Deve retornar estatísticas iniciais (zeros)
   SELECT * FROM dashboard_stats;
   
   -- Deve retornar vazio (nenhum review ainda)
   SELECT * FROM reviews_with_details;
   
   -- Criar um usuário de teste
   INSERT INTO users (name, email, is_anonymous)
   VALUES ('Usuário Teste', 'teste@example.com', false)
   RETURNING *;
   
   -- Verificar criação
   SELECT * FROM users;
   ```

### Teste via Código (JavaScript/TypeScript):

Crie um arquivo `test-connection.js`:

```javascript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://seu-projeto.supabase.co'
const supabaseKey = 'sua_anon_key_aqui'
const supabase = createClient(supabaseUrl, supabaseKey)

async function testConnection() {
  console.log('🧪 Testando conexão com Supabase...')
  
  // Teste 1: Dashboard stats
  const { data: stats, error: statsError } = await supabase
    .from('dashboard_stats')
    .select('*')
  
  if (statsError) {
    console.error('❌ Erro ao buscar stats:', statsError)
  } else {
    console.log('✅ Stats obtidas:', stats)
  }
  
  // Teste 2: Criar sessão anônima
  const { data: session, error: sessionError } = await supabase
    .rpc('create_anonymous_session', {
      p_ip_address: '127.0.0.1',
      p_user_agent: 'Test Browser'
    })
  
  if (sessionError) {
    console.error('❌ Erro ao criar sessão:', sessionError)
  } else {
    console.log('✅ Sessão criada:', session)
  }
  
  console.log('🎉 Todos os testes passaram!')
}

testConnection()
```

Execute:
```bash
node test-connection.js
```

## 🔧 PASSO 8: Configurar Cron Jobs (Opcional)

Para limpeza automática de sessões expiradas:

1. No Supabase, vá para **Database** → **Extensions**
2. Habilite a extensão **pg_cron**
3. No SQL Editor, execute:

```sql
-- Limpar sessões expiradas diariamente às 2h da manhã
SELECT cron.schedule(
  'cleanup-expired-sessions',
  '0 2 * * *',
  $$ 
  SELECT cleanup_expired_sessions(); 
  $$
);

-- Verificar jobs agendados
SELECT * FROM cron.job;
```

## 🎨 PASSO 9: Configurar Realtime (Opcional)

Para atualizações em tempo real:

1. No Supabase, vá para **Database** → **Replication**
2. Selecione a tabela `reviews`
3. Marque **"Enable Realtime"**
4. Clique em **"Save"**
5. Repita para `danger_levels` se desejar

## 📊 PASSO 10: Seed com Dados de Teste (Opcional)

Para popular o banco com dados de exemplo:

```sql
-- Criar usuários de teste
INSERT INTO users (name, email, is_anonymous) VALUES
  ('João Silva', 'joao@example.com', false),
  ('Maria Santos', 'maria@example.com', false),
  ('Anônimo 1', NULL, true),
  ('Anônimo 2', NULL, true);

-- Criar reviews de teste
INSERT INTO reviews (user_id, comment_text, is_positive, score_value, ip_address)
SELECT 
  u.id,
  'Este é um comentário de teste número ' || gs.n,
  false,
  10,
  ('192.168.1.' || (gs.n % 255))::inet
FROM users u
CROSS JOIN generate_series(1, 5) gs(n);

-- Verificar
SELECT * FROM reviews_with_details;
SELECT * FROM dashboard_stats;
```

## 🎯 Próximos Passos

Após completar a instalação:

1. ✅ Integre o Supabase ao frontend (HTML/JavaScript)
2. ✅ Configure autenticação de usuários (se necessário)
3. ✅ Implemente upload de arquivos
4. ✅ Teste o sistema de rate limiting
5. ✅ Configure monitoramento e logs

## 🆘 Troubleshooting

### Erro: "relation does not exist"
**Solução:** Execute novamente o `schema.sql`

### Erro: "permission denied"
**Solução:** Verifique se RLS está habilitado e políticas configuradas (`security.sql`)

### Erro ao fazer upload de arquivo
**Solução:** 
1. Verifique se o bucket `miyukometro-uploads` foi criado
2. Confirme que as políticas de storage estão ativas
3. Verifique tamanho do arquivo (max 50MB)

### Views não aparecem
**Solução:** Execute:
```sql
SELECT * FROM pg_views WHERE schemaname = 'public';
```
Se estiver vazio, execute `schema.sql` novamente

### Triggers não funcionam
**Solução:** Verifique se foram criados:
```sql
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public';
```

## 📚 Documentação Adicional

- 📖 Documentação completa: `database/README.md`
- 🔐 Políticas de segurança: `database/security.sql`
- 🗄️ Schema do banco: `database/schema.sql`
- 🌐 Supabase Docs: https://supabase.com/docs

## ✅ Checklist de Instalação

- [ ] Projeto criado no Supabase
- [ ] Schema executado (6 tabelas criadas)
- [ ] Políticas RLS configuradas
- [ ] Storage bucket criado e configurado
- [ ] Credenciais copiadas
- [ ] Arquivo .env configurado
- [ ] Conexão testada com sucesso
- [ ] Cron jobs configurados (opcional)
- [ ] Realtime habilitado (opcional)
- [ ] Dados de teste inseridos (opcional)

🎉 **Parabéns! Seu banco de dados está pronto para uso!**
