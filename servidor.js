const express = require('express');
const fs = require('fs').promises;
const path = require('path');
const cors = require('cors');

const app = express();
const PORTA = 3000;
const ARQUIVO_DADOS = path.join(__dirname, 'dados-miyukometro.json');

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.static(__dirname));

async function lerDados() {
    try {
        const conteudo = await fs.readFile(ARQUIVO_DADOS, 'utf-8');
        return JSON.parse(conteudo);
    } catch (erro) {
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
            perfil: {
                nome: "Miyuki",
                idade: 30,
                altura: "1,78m",
                caracteristicas: ["Gordo", "Calvo"],
                habitatNatural: ["CDL", "Bonfire"],
                zoologico: {
                    url: "https://discord.gg/G5FydZmxt2",
                    descricao: "Discord Server"
                },
                status: "Sob Monitoramento Constante"
            },
            relacionamentos: {
                arquiInimigos: ["Locutor", "Dio", "Dev Titan", "Erick", "Dry", "Mãe dele"],
                coisasQueGosta: ["Pennelope", "Hotroll", "Pizza", "Coquinha", "Pedir esmola", "Joguinho na Steam"],
                apelidos: ["Gordo", "Bola", "Mendigo", "Gorduky", "Mijuki", "Balão d'água"]
            },
            avaliacoes: {
                totalComentarios: 0,
                totalLikes: 0,
                totalDeslikes: 0,
                comentarios: []
            },
            metadados: {
                criadoEm: new Date().toISOString(),
                versaoSchema: "1.0.0",
                descricao: "Arquivo de persistência de dados do Miyukometro",
                autor: "Sistema Miyukometro"
            }
        };
    }
}

async function salvarDados(dados) {
    dados.dataUltimaAtualizacao = new Date().toISOString();
    await fs.writeFile(ARQUIVO_DADOS, JSON.stringify(dados, null, 2), 'utf-8');
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

app.get('/api/dados', async (req, res) => {
    try {
        const dados = await lerDados();
        res.json(dados);
    } catch (erro) {
        res.status(500).json({ erro: 'Erro ao carregar dados' });
    }
});

app.post('/api/comentario', async (req, res) => {
    try {
        const { texto, autor, anonimo, arquivo } = req.body;

        if (!texto && !arquivo) {
            return res.status(400).json({ erro: 'Comentário vazio' });
        }

        if (arquivo && arquivo.dados && arquivo.dados.length > 10 * 1024 * 1024) {
            return res.status(400).json({ erro: 'Arquivo muito grande (máximo 10MB)' });
        }

        const dados = await lerDados();
        
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

        await salvarDados(dados);

        res.json({ 
            sucesso: true, 
            comentario: novoComentario,
            pontuacao: dados.configuracoes.pontuacaoAtual
        });
    } catch (erro) {
        res.status(500).json({ erro: 'Erro ao salvar comentário' });
    }
});

app.delete('/api/comentario/:id', async (req, res) => {
    try {
        const { senha } = req.body;
        const comentarioId = parseInt(req.params.id);

        const dados = await lerDados();

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

        await salvarDados(dados);

        res.json({ 
            sucesso: true, 
            pontuacao: dados.configuracoes.pontuacaoAtual 
        });
    } catch (erro) {
        res.status(500).json({ erro: 'Erro ao excluir comentário' });
    }
});

app.post('/api/alerta', async (req, res) => {
    try {
        const { ativo } = req.body;
        const dados = await lerDados();
        
        dados.configuracoes.alertaVisualAtivo = ativo === true;
        
        await salvarDados(dados);

        res.json({ sucesso: true });
    } catch (erro) {
        res.status(500).json({ erro: 'Erro ao atualizar alerta' });
    }
});

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'miyukometro.html'));
});

app.listen(PORTA, () => {
    console.log(`\n========================================`);
    console.log(`Site do bolota rodando!`);
    console.log(`========================================`);
    console.log(`URL: http://localhost:${PORTA}`);
    console.log(`Arquivo de dados: dados-miyukometro.json`);
    console.log(`========================================\n\n`);
    console.log(`Cuidado, se o miyuk abrir, o site pode sobrecarregar pelo peso extremo.\n`);
});
