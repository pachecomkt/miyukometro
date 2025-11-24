# 🎯 Miyukometro - Sistema de Monitoramento

Sistema web de monitoramento e avaliação com interface interativa e sistema de pontuação dinâmica.

## 🚀 Deploy Rápido na Vercel

### Opção 1: Via GitHub (Recomendado)

1. **Fazer push para GitHub:**
```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/miyukometro.git
git push -u origin main
```

2. **Conectar na Vercel:**
   - Acesse https://vercel.com
   - Clique em "New Project"
   - Importe seu repositório
   - Deploy automático! 🎉

### Opção 2: Via CLI

```bash
npm install -g vercel
vercel
```

## 📦 Instalação Local

```bash
# Instalar dependências
npm install

# Executar em modo desenvolvimento
npm run dev

# Ou executar servidor
npm run iniciar
```

Acesse: http://localhost:3000

## 📁 Estrutura do Projeto

```
miyukometro-main/
├── api/                    # Serverless Functions da Vercel
│   ├── dados.js           # GET - Obter dados
│   ├── comentario.js      # POST - Adicionar comentário
│   ├── alerta.js          # POST - Alternar alerta
│   └── excluir/
│       └── [id].js        # DELETE - Excluir comentário
├── imgs/                  # Imagens do projeto
├── database/              # Scripts SQL (futuro)
├── miyukometro.html       # Página principal
├── dados-miyukometro.json # Arquivo de dados (local)
├── vercel.json           # Configuração Vercel
├── package.json          # Dependências
└── README.md             # Este arquivo
```

## ⚠️ Importante - Persistência de Dados

**Atenção:** A Vercel usa serverless functions que **NÃO persistem dados** em arquivo JSON.

### Soluções:
1. **Supabase** (Recomendado) - PostgreSQL gratuito
2. **Vercel KV** - Redis serverless
3. **MongoDB Atlas** - NoSQL gratuito

Veja `DEPLOY.md` para instruções completas.

## 🔧 Funcionalidades

- ✅ Sistema de comentários com upload de imagens
- ✅ Medidor de perigo dinâmico
- ✅ Alertas visuais configuráveis
- ✅ Modo anônimo
- ✅ Exclusão protegida por senha
- ✅ Interface responsiva
- ✅ Animações interativas

## 🔒 Segurança

- Sanitização de inputs (XSS Protection)
- Validação de tamanho de arquivo (10MB max)
- CORS configurado
- Senha de exclusão

## 📚 Documentação

- `DEPLOY.md` - Guia completo de deploy
- `database/` - Documentação do banco de dados (futuro Supabase)

## 🛠️ Tecnologias

- **Frontend:** HTML, CSS (Tailwind), JavaScript
- **Backend:** Node.js + Express → Vercel Serverless Functions
- **Deploy:** Vercel
- **Futuro:** Supabase (PostgreSQL)

## 📝 Licença

MIT

---

**Desenvolvido para monitoramento do Miyuki** 😄
