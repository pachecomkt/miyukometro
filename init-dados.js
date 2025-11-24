// Script para inicializar o arquivo de dados
const fs = require('fs');
const path = require('path');

const ARQUIVO_DADOS = path.join(__dirname, 'dados-miyukometro.json');

const dadosIniciais = {
    versao: "1.0.0",
    dataUltimaAtualizacao: new Date().toISOString(),
    configuracoes: {
        pontuacaoAtual: 0,
        alertaVisualAtivo: true,
        nivelPerigo: {
            valor: 0,
            classificacao: "BAIXO",
            limites: { 
                baixo: 30, 
                medio: 60, 
                alto: 90, 
                critico: 90 
            }
        },
        pontosPorAvaliacao: 10,
        senhaExclusao: process.env.SENHA_EXCLUSAO || "bola123"
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
        arquiInimigos: [
            "Locutor", 
            "Dio", 
            "Dev Titan", 
            "Erick", 
            "Dry", 
            "Mãe dele"
        ],
        coisasQueGosta: [
            "Pennelope", 
            "Hotroll", 
            "Pizza", 
            "Coquinha", 
            "Pedir esmola", 
            "Joguinho na Steam"
        ],
        apelidos: [
            "Gordo", 
            "Bola", 
            "Mendigo", 
            "Gorduky", 
            "Mijuki", 
            "Balão d'água"
        ]
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

// Verificar se o arquivo já existe
if (!fs.existsSync(ARQUIVO_DADOS)) {
    fs.writeFileSync(
        ARQUIVO_DADOS, 
        JSON.stringify(dadosIniciais, null, 2), 
        'utf-8'
    );
    console.log('✅ Arquivo dados-miyukometro.json criado com sucesso!');
} else {
    console.log('ℹ️  Arquivo dados-miyukometro.json já existe.');
}
