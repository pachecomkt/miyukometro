// API Handler para Vercel Serverless Functions
const fs = require('fs');
const path = require('path');

// Caminho para o arquivo de dados
const ARQUIVO_DADOS = path.join(process.cwd(), 'dados-miyukometro.json');

// Função para ler dados do arquivo JSON
function lerDados() {
    try {
        if (fs.existsSync(ARQUIVO_DADOS)) {
            const conteudo = fs.readFileSync(ARQUIVO_DADOS, 'utf-8');
            return JSON.parse(conteudo);
        }
    } catch (erro) {
        console.error('Erro ao ler dados:', erro);
    }
    
    // Retornar dados padrão se não existir ou houver erro
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

// Handler principal da API
module.exports = async (req, res) => {
    // Configurar CORS
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    // Responder a requisições OPTIONS (preflight)
    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }
    
    // Apenas GET permitido
    if (req.method !== 'GET') {
        return res.status(405).json({ erro: 'Método não permitido' });
    }
    
    try {
        const dados = lerDados();
        return res.status(200).json(dados);
    } catch (erro) {
        console.error('Erro ao processar requisição:', erro);
        return res.status(500).json({ erro: 'Erro ao carregar dados' });
    }
};
