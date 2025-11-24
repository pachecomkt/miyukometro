const fs = require('fs');
const path = require('path');

// Criar diretório public (sempre garantir que existe)
const publicDir = 'public';
try {
  if (!fs.existsSync(publicDir)) {
    fs.mkdirSync(publicDir, { recursive: true });
    console.log('✓ Diretório public criado');
  } else {
    console.log('✓ Diretório public já existe');
  }
} catch (error) {
  console.error('✗ Erro ao criar diretório public:', error);
  process.exit(1);
}

// Copiar arquivos HTML
['miyukometro.html', 'index.html', 'dados-miyukometro.json'].forEach(file => {
  if (fs.existsSync(file)) {
    const dest = path.join(publicDir, file);
    fs.copyFileSync(file, dest);
    console.log(`Copiado: ${file} -> ${dest}`);
  } else {
    console.log(`Arquivo não encontrado: ${file}`);
  }
});

// Copiar diretório imgs
if (fs.existsSync('imgs')) {
  const imgsDest = path.join(publicDir, 'imgs');
  if (!fs.existsSync(imgsDest)) {
    fs.mkdirSync(imgsDest, { recursive: true });
  }
  fs.readdirSync('imgs').forEach(file => {
    fs.copyFileSync(
      path.join('imgs', file),
      path.join(imgsDest, file)
    );
    console.log(`Copiado: imgs/${file} -> ${imgsDest}/${file}`);
  });
} else {
  console.log('Diretório imgs não encontrado');
}

// Verificar se o diretório public foi criado
if (fs.existsSync(publicDir)) {
  console.log(`✓ Diretório ${publicDir} existe`);
  try {
    const files = fs.readdirSync(publicDir);
    console.log(`✓ Arquivos em ${publicDir}:`, files.join(', '));
    console.log(`✓ Total de arquivos: ${files.length}`);
  } catch (error) {
    console.error('Erro ao listar arquivos:', error);
  }
} else {
  console.error(`✗ Erro: Diretório ${publicDir} não foi criado!`);
  // Tentar criar novamente
  try {
    fs.mkdirSync(publicDir, { recursive: true });
    console.log(`✓ Diretório ${publicDir} criado na segunda tentativa`);
  } catch (error) {
    console.error(`✗ Erro ao criar diretório na segunda tentativa:`, error);
    process.exit(1);
  }
}

// Verificação final
if (!fs.existsSync(publicDir)) {
  console.error(`✗ ERRO CRÍTICO: Diretório ${publicDir} não existe após o build!`);
  process.exit(1);
}

console.log('✓ Build concluído com sucesso!');

