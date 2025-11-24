// API Handler para atualizar alerta visual
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
            alertaVisualAtivo: true
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
        const { ativo } = req.body;
        const dados = lerDados();
        
        dados.configuracoes.alertaVisualAtivo = ativo === true;
        
        const sucesso = salvarDados(dados);
        
        if (!sucesso) {
            return res.status(500).json({ erro: 'Erro ao atualizar alerta' });
        }

        return res.status(200).json({ sucesso: true });
    } catch (erro) {
        console.error('Erro ao atualizar alerta:', erro);
        return res.status(500).json({ erro: 'Erro ao atualizar alerta' });
    }
};
