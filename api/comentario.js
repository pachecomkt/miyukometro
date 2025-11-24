// API Handler para adicionar comentários
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
        versao: "1.0.0",
        dataUltimaAtualizacao: new Date().toISOString(),
        configuracoes: {
            pontuacaoAtual: 0,
            alertaVisualAtivo: true,
            nivelPerigo: {
                valor: 0,
                classificacao: "BAIXO",
                limites: { baixo: 30, medio: 60, alto: 90, critico: 90 }
            },
            pontosPorAvaliacao: 10,
            senhaExclusao: "bola123"
        },
        avaliacoes: {
            totalComentarios: 0,
            totalLikes: 0,
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

function sanitizarTexto(texto) {
    if (!texto) return '';
    return texto
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;')
        .substring(0, 1000);
}

module.exports = async (req, res) => {
    // Configurar CORS
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }
    
    if (req.method !== 'POST') {
        return res.status(405).json({ erro: 'Método não permitido' });
    }
    
    try {
        const { texto, autor, anonimo, arquivo } = req.body;

        // Validação de segurança
        if (!texto && !arquivo) {
            return res.status(400).json({ erro: 'Comentário vazio' });
        }

        if (arquivo && arquivo.dados && arquivo.dados.length > 10 * 1024 * 1024) {
            return res.status(400).json({ erro: 'Arquivo muito grande (máximo 10MB)' });
        }

        const dados = lerDados();
        
        const novoComentario = {
            id: Date.now(),
            texto: sanitizarTexto(texto),
            autor: anonimo ? 'Anônimo' : sanitizarTexto(autor) || 'Anônimo',
            anonimo: anonimo === true,
            tipoAvaliacao: 'deslike',
            dataHora: new Date().toLocaleString('pt-BR'),
            timestamp: Date.now(),
            arquivo: arquivo || null
        };

        dados.avaliacoes.comentarios.unshift(novoComentario);
        dados.avaliacoes.totalComentarios = dados.avaliacoes.comentarios.length;
        dados.avaliacoes.totalDeslikes = dados.avaliacoes.comentarios.length;
        
        dados.configuracoes.pontuacaoAtual += dados.configuracoes.pontosPorAvaliacao;
        dados.configuracoes.nivelPerigo.valor = dados.configuracoes.pontuacaoAtual;
        dados.configuracoes.nivelPerigo.classificacao = obterClassificacaoPerigo(dados.configuracoes.pontuacaoAtual);

        const sucesso = salvarDados(dados);
        
        if (!sucesso) {
            return res.status(500).json({ erro: 'Erro ao salvar comentário' });
        }

        return res.status(200).json({ 
            sucesso: true, 
            comentario: novoComentario,
            pontuacao: dados.configuracoes.pontuacaoAtual
        });
    } catch (erro) {
        console.error('Erro ao processar comentário:', erro);
        return res.status(500).json({ erro: 'Erro ao salvar comentário' });
    }
};
