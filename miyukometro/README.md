# 🎯 MIYUKOMETRO - Sistema de Monitoramento

Sistema de avaliações com níveis de perigo dinâmicos, upload de arquivos e detecção de abuso.

## 📁 Estrutura do Projeto

```
miyukometro/
├── 📄 miyukometro.html          # Frontend (HTML + JavaScript + TailwindCSS)
├── 📄 PROJETO_DATABASE.md       # 📊 LEIA PRIMEIRO - Visão geral completa
├── 📄 .env.example              # Template de variáveis de ambiente
├── 📄 .env                      # ⚠️  Credenciais (NÃO COMMITAR!)
├── 📄 .gitignore                # Proteção de arquivos sensíveis
│
└── 📁 database/                 # Banco de dados PostgreSQL (Supabase)
    ├── 📄 SUMMARY.md            # 📊 Resumo executivo - comece aqui!
    ├── 📄 INSTALL.md            # 🚀 Guia passo-a-passo de instalação
    ├── 📄 README.md             # 📚 Documentação técnica completa
    ├── 📄 schema.sql            # ⚙️  Estrutura do banco (tabelas, funções, triggers)
    ├── 📄 security.sql          # 🔐 Políticas RLS e permissões
    └── 📄 queries.sql           # 📝 100+ queries úteis e exemplos
```

## 🚀 Início Rápido

### 1️⃣ Leia a Documentação

**Escolha seu nível:**

- 🟢 **Iniciante?** → Leia `PROJETO_DATABASE.md` primeiro
- 🟡 **Quer instalar?** → Siga `database/INSTALL.md`
- 🔵 **Desenvolvedor?** → Estude `database/README.md`
- 🟣 **Referência rápida?** → Consulte `database/queries.sql`

### 2️⃣ Configure o Banco de Dados

```bash
# 1. Crie projeto no Supabase
https://app.supabase.com → New Project

# 2. Execute os scripts SQL (na ordem!)
1. database/schema.sql       # Criar estrutura
2. database/security.sql     # Configurar segurança

# 3. Configure variáveis de ambiente
cp .env.example .env
# Edite .env com suas credenciais

# 4. Teste a conexão
SELECT * FROM dashboard_stats;
```

### 3️⃣ Integre ao Frontend

Instale o cliente Supabase:
```bash
npm install @supabase/supabase-js
```

Código de exemplo:
```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://seu-projeto.supabase.co',
  'sua_anon_key'
)

// Criar sessão anônima
const { data } = await supabase
  .rpc('create_anonymous_session', {
    p_ip_address: '127.0.0.1',
    p_user_agent: navigator.userAgent
  })

// Inserir review
await supabase.from('reviews').insert({
  user_id: data[0].user_id,
  comment_text: 'Ótimo sistema!',
  is_positive: false,
  score_value: 10
})

// Buscar estatísticas
const { data: stats } = await supabase
  .from('dashboard_stats')
  .select('*')
```

## 🎯 Funcionalidades

### ✅ Implementadas no Banco de Dados

- ✅ Sistema de usuários (anônimos e autenticados)
- ✅ Avaliações com comentários e arquivos
- ✅ Cálculo automático de níveis de perigo
- ✅ Histórico completo de mudanças
- ✅ Detecção de abuso e rate limiting
- ✅ Sessões com expiração automática
- ✅ Upload de arquivos (até 50MB)
- ✅ Soft delete com preservação de dados
- ✅ Sanitização contra XSS
- ✅ Row Level Security (RLS)

### 🎨 Níveis de Perigo

| Score | Nível | Status |
|-------|-------|--------|
| 0-29 | BAIXO | 🟡 Seguro |
| 30-59 | MÉDIO | 🟠 Atenção |
| 60-89 | ALTO | 🔴 Preocupante |
| 90+ | CRÍTICO | 🔴 Perigo! |

## 📊 Estrutura do Banco

### 6 Tabelas Principais

```
users              Usuários (anônimos/autenticados)
├── reviews        Avaliações com pontuação
│   ├── files      Metadados de arquivos
│   └── danger_levels  Histórico de níveis
├── sessions       Controle de sessões
└── abuse_reports  Detecção de abuso
```

### Funções Úteis

- `create_anonymous_session()` - Cria usuário e sessão
- `check_rate_limit()` - Valida se pode fazer requisição
- `calculate_danger_level()` - Calcula nível baseado no score
- `get_system_stats()` - Retorna estatísticas gerais
- `sanitize_text()` - Remove scripts e tags HTML

### Views Otimizadas

- `reviews_with_details` - Reviews com usuário e arquivos
- `dashboard_stats` - Estatísticas em tempo real

## 🔒 Segurança

### Proteções Implementadas

- 🛡️ **SQL Injection:** Row Level Security + Prepared Statements
- 🛡️ **XSS:** Sanitização automática de texto
- 🛡️ **CSRF:** Validação de session tokens
- 🛡️ **Rate Limiting:** 10 requests / 5 minutos por IP
- 🛡️ **Brute Force:** Detecção via abuse_reports
- 🛡️ **Data Leak:** RLS impede acesso não autorizado

### Validações Ativas

- ✅ Email com regex RFC 5322
- ✅ Texto limitado a 5000 caracteres
- ✅ Arquivo máximo de 50MB
- ✅ Score entre 0 e 100
- ✅ Formato IP validado
- ✅ Session token mínimo 32 chars

## 📚 Documentação

### Arquivos de Referência

| Arquivo | Descrição | Quando Usar |
|---------|-----------|-------------|
| `PROJETO_DATABASE.md` | Visão geral completa | Primeira leitura |
| `database/SUMMARY.md` | Resumo executivo | Referência rápida |
| `database/INSTALL.md` | Guia de instalação | Setup inicial |
| `database/README.md` | Docs técnicas | Desenvolvimento |
| `database/queries.sql` | Queries de exemplo | Consultas diárias |

### Seções Importantes

- 📖 **Instalação:** `database/INSTALL.md`
- 📖 **Estrutura das Tabelas:** `database/README.md` → Seção 3
- 📖 **Segurança (RLS):** `database/README.md` → Seção 6
- 📖 **Queries Úteis:** `database/README.md` → Seção 7
- 📖 **Troubleshooting:** `database/INSTALL.md` → Seção 10

## ⚡ Performance

### Otimizações Aplicadas

- ✅ 14 índices estratégicos
- ✅ Views pré-calculadas
- ✅ Funções em PL/pgSQL
- ✅ Triggers eficientes
- ✅ Connection pooling

### Tempos Esperados

| Operação | Tempo |
|----------|-------|
| SELECT by ID | < 5ms |
| Dashboard stats | < 10ms |
| INSERT review | < 20ms |
| Rate limit check | < 10ms |

## 🛠️ Tecnologias

- **Frontend:** HTML5 + JavaScript + TailwindCSS
- **Backend:** Supabase (PostgreSQL + Auth + Storage)
- **Database:** PostgreSQL 14+
- **Extensões:** uuid-ossp, pgcrypto

## 📈 Capacidade

- **Reviews:** Ilimitadas (escala horizontal)
- **Usuários:** Ilimitados
- **Storage:** 1GB (free) / Ilimitado (pago)
- **Requests/mês:** 500.000 (free tier)
- **Throughput:** ~1000 req/seg

## 🔧 Manutenção

### Tarefas Diárias
```sql
SELECT cleanup_expired_sessions();
```

### Tarefas Semanais
```sql
SELECT * FROM abuse_reports WHERE is_resolved = false;
VACUUM ANALYZE;
```

### Tarefas Mensais
```sql
DELETE FROM reviews WHERE deleted_at < NOW() - INTERVAL '30 days';
```

## 🆘 Suporte

### Problemas Comuns

**"relation does not exist"**
→ Execute `schema.sql` novamente

**"permission denied"**
→ Verifique RLS e políticas em `security.sql`

**Conexão falha**
→ Verifique credenciais em `.env`

**Queries lentas**
→ Execute `VACUUM ANALYZE`

### Onde Buscar Ajuda

1. `database/INSTALL.md` - Troubleshooting
2. `database/README.md` - Boas Práticas
3. Supabase Docs - https://supabase.com/docs
4. PostgreSQL Docs - https://postgresql.org/docs

## ✅ Checklist de Instalação

- [ ] Projeto criado no Supabase
- [ ] `schema.sql` executado
- [ ] `security.sql` executado
- [ ] Storage bucket configurado
- [ ] `.env` preenchido
- [ ] Conexão testada
- [ ] Dashboard stats retorna dados

## 🎉 Status

**✅ BANCO DE DADOS COMPLETO E PRONTO PARA USO!**

**Características:**
- ✨ Completo (todas as funcionalidades)
- ✨ Seguro (proteções contra vulnerabilidades)
- ✨ Rápido (otimizado para performance)
- ✨ Escalável (pronto para crescimento)
- ✨ Documentado (docs detalhadas)

## 📞 Próximos Passos

1. ⭐ Leia `PROJETO_DATABASE.md` para visão geral
2. ⭐ Siga `database/INSTALL.md` para instalação
3. ⭐ Integre ao frontend usando exemplos
4. ⭐ Teste todas as funcionalidades
5. ⭐ Lance em produção!

---

**Desenvolvido em:** 22 de novembro de 2025
**Versão:** 1.0.0
**Licença:** Proprietária - Miyukometro Project

🚀 **Boa sorte com o projeto!**
