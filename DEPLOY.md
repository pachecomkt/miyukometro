# 🚀 Guia de Deploy na Vercel - Miyukometro

## ✅ Preparação Concluída

O projeto já está configurado para deploy na Vercel com as seguintes alterações:

### 📁 Estrutura de Arquivos Criada:

1. **`vercel.json`** - Configuração de rotas e builds da Vercel
2. **`api/dados.js`** - Serverless function para obter dados
3. **`api/comentario.js`** - Serverless function para adicionar comentários
4. **`api/excluir/[id].js`** - Serverless function para excluir comentários
5. **`api/alerta.js`** - Serverless function para alternar alerta visual
6. **`index.html`** - Página de redirecionamento
7. **`.gitignore`** - Arquivos a serem ignorados no Git

### 🔧 Alterações Realizadas:

- ✅ Convertido servidor Express para Vercel Serverless Functions
- ✅ Ajustado API_URL no HTML de `localhost:3000` para rotas relativas `/api`
- ✅ Corrigida rota de exclusão de comentário
- ✅ Configurado CORS para permitir requisições
- ✅ Adicionado tratamento de erros em todas as funções
- ✅ Sanitização de inputs para segurança
- ✅ Validações de tamanho de arquivo (max 10MB)

---

## 📋 Passos para Deploy na Vercel

### 1️⃣ Criar conta na Vercel (se não tiver)
Acesse: https://vercel.com/signup

### 2️⃣ Instalar Vercel CLI (Opcional)
```bash
npm install -g vercel
```

### 3️⃣ Deploy via CLI (Opção A)
No diretório do projeto, execute:
```bash
vercel
```

Siga as instruções:
- Login com sua conta
- Configure o projeto conforme as perguntas
- Aguarde o deploy

### 4️⃣ Deploy via GitHub/GitLab (Opção B - Recomendado)

1. **Crie um repositório no GitHub:**
   - Acesse https://github.com/new
   - Dê um nome (ex: `miyukometro`)
   - Crie o repositório

2. **Faça push do código:**
   ```bash
   git init
   git add .
   git commit -m "Deploy inicial - Miyukometro"
   git branch -M main
   git remote add origin https://github.com/SEU_USUARIO/miyukometro.git
   git push -u origin main
   ```

3. **Conecte na Vercel:**
   - Acesse https://vercel.com/new
   - Selecione "Import Git Repository"
   - Escolha seu repositório `miyukometro`
   - Clique em "Import"
   - Configure (ou deixe padrão)
   - Clique em "Deploy"

---

## ⚠️ IMPORTANTE - Persistência de Dados

**ATENÇÃO:** A Vercel usa serverless functions que são **stateless** (sem estado). Isso significa que:

- ❌ O arquivo `dados-miyukometro.json` **NÃO persiste** entre deploys
- ❌ Os comentários serão **perdidos** ao reiniciar a função
- ❌ Dados são **temporários** na execução atual

### 🔄 Soluções Recomendadas:

#### **Opção 1: Supabase (Recomendado)**
Use o Supabase para persistência real de dados:
- Gratuito até 500MB
- PostgreSQL completo
- API REST automática
- Segurança RLS integrada

**Próximos passos:** 
- Criar projeto no Supabase
- Implementar queries SQL
- Conectar API com cliente Supabase

#### **Opção 2: Vercel KV (Redis)**
- Banco de dados chave-valor
- Plano gratuito: 256MB
- Latência ultra-baixa

#### **Opção 3: MongoDB Atlas**
- Banco NoSQL
- Plano gratuito: 512MB
- Fácil integração

---

## 🧪 Testando Localmente

Para testar o projeto localmente antes do deploy:

```bash
# Instalar dependências
npm install

# Iniciar servidor local (modo desenvolvimento)
npm run dev

# Ou com servidor normal
npm run iniciar
```

Acesse: http://localhost:3000

---

## 🔒 Segurança

### Pontos Implementados:
- ✅ Sanitização de HTML (XSS Protection)
- ✅ Validação de tamanho de arquivo
- ✅ CORS configurado
- ✅ Senha de exclusão protegida
- ✅ Limite de caracteres (1000)

### Melhorias Futuras Sugeridas:
- [ ] Rate limiting para evitar spam
- [ ] Captcha em formulários
- [ ] Variáveis de ambiente para senha
- [ ] Autenticação JWT
- [ ] Criptografia de dados sensíveis

---

## 🌐 Após o Deploy

Sua URL da Vercel será algo como:
```
https://miyukometro.vercel.app
```

Você pode configurar um domínio customizado nas configurações do projeto na Vercel.

---

## 📊 Monitoramento

Após o deploy, você pode:
- Ver logs em tempo real no dashboard da Vercel
- Monitorar uso de funções serverless
- Ver analytics de visitantes
- Configurar notificações de erro

---

## 🐛 Troubleshooting

### Erro 404: NOT_FOUND
**Causa:** Rotas não configuradas corretamente
**Solução:** Verificar `vercel.json` e estrutura de pastas

### Dados não persistem
**Causa:** Serverless functions são stateless
**Solução:** Implementar banco de dados externo (Supabase/MongoDB)

### Erro de CORS
**Causa:** Headers não configurados
**Solução:** Verificar `Access-Control-Allow-Origin` nas APIs

---

## 📝 Notas Finais

Este projeto está **pronto para deploy**, mas com **limitação de persistência de dados**.

Para um sistema de produção real, **é altamente recomendado** integrar com um banco de dados externo como Supabase, MongoDB Atlas ou Vercel KV.

---

## 🆘 Suporte

Se encontrar problemas:
1. Verifique os logs da Vercel
2. Teste localmente primeiro
3. Revise o arquivo `vercel.json`
4. Confirme que todas as APIs estão respondendo

**Boa sorte com o deploy do Miyukometro! 🎉**
