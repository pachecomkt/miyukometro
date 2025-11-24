// API Handler para excluir comentário
const fs = require('fs');
const path = require('path');

const ARQUIVO_DADOS = path.join(process.cwd(), 'dados-miyukometro.json');

function lerDados() {
    try {
        if (fs.existsSync(ARQUIVO_DADOS)) {
            const conteudo = fs.readFileSync(ARQUIVO_DADOS, 'utf-8');
            return JSON.parse(conteudo);
        }
    } catch (erro) {
        console.error('Erro ao ler dados:', erro);
    }
    
    return {
        configuracoes: {
            pontuacaoAtual: 0,
            pontosPorAvaliacao: 10,
            senhaExclusao: "bola123",
            nivelPerigo: {
                valor: 0,
                classificacao: "BAIXO"
            }
        },
        avaliacoes: {
            totalComentarios: 0,
            totalDeslikes: 0,
            comentarios: []
        }
    };
}

function salvarDados(dados) {
    try {
        dados.dataUltimaAtualizacao = new Date().toISOString();
        fs.writeFileSync(ARQUIVO_DADOS, JSON.stringify(dados, null, 2), 'utf-8');
        return true;
    } catch (erro) {
        console.error('Erro ao salvar dados:', erro);
        return false;
    }
}

function obterClassificacaoPerigo(pontuacao) {
    if (pontuacao < 30) return 'BAIXO';
    if (pontuacao < 60) return 'MÉDIO';
    if (pontuacao < 90) return 'ALTO';
    return 'CRÍTICO';
}

module.exports = async (req, res) => {
    // Configurar CORS
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }
    
    if (req.method !== 'DELETE') {
        return res.status(405).json({ erro: 'Método não permitido' });
    }
    
    try {
        const { id } = req.query;
        const { senha } = req.body;
        
        const comentarioId = parseInt(id);

        const dados = lerDados();

        // Validação de senha
        if (senha !== dados.configuracoes.senhaExclusao) {
            return res.status(401).json({ erro: 'Senha incorreta' });
        }

        const comentarioExistia = dados.avaliacoes.comentarios.some(c => c.id === comentarioId);
        
        dados.avaliacoes.comentarios = dados.avaliacoes.comentarios.filter(c => c.id !== comentarioId);
        
        if (comentarioExistia) {
            dados.avaliacoes.totalComentarios = dados.avaliacoes.comentarios.length;
            dados.avaliacoes.totalDeslikes = dados.avaliacoes.comentarios.length;
            dados.configuracoes.pontuacaoAtual = Math.max(0, dados.configuracoes.pontuacaoAtual - dados.configuracoes.pontosPorAvaliacao);
            dados.configuracoes.nivelPerigo.valor = dados.configuracoes.pontuacaoAtual;
            dados.configuracoes.nivelPerigo.classificacao = obterClassificacaoPerigo(dados.configuracoes.pontuacaoAtual);
        }

        const sucesso = salvarDados(dados);
        
        if (!sucesso) {
            return res.status(500).json({ erro: 'Erro ao excluir comentário' });
        }

        return res.status(200).json({ 
            sucesso: true, 
            pontuacao: dados.configuracoes.pontuacaoAtual 
        });
    } catch (erro) {
        console.error('Erro ao excluir comentário:', erro);
        return res.status(500).json({ erro: 'Erro ao excluir comentário' });
    }
};
