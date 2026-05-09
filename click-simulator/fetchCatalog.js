/**
 * fetchCatalog.js
 * Busca itens reais do catálogo do Roblox e gera src/shared/Catalog.luau
 * Uso: node fetchCatalog.js
 */

const https = require('https');
const fs    = require('fs');
const path  = require('path');

// ─────────────────────────────────────────────────────────────
// Configuração
// ─────────────────────────────────────────────────────────────

const ITEMS_PER_SUBCATEGORY = 60;
const MAX_PRICE             = null;   // null = sem filtro
const SORT_TYPE             = 3;      // 3 = MostFavorited

const CATEGORIES = [
  { name: 'Hair',        category: 11, subcategory: 19 },
  { name: 'Hats',        assetType: 8 },                    // subcategoria 9 foi removida
  { name: 'FaceAcc',     category: 11, subcategory: 18 },
  { name: 'NeckAcc',     category: 11, subcategory: 22 },
  { name: 'ShoulderAcc', category: 11, subcategory: 23 },
  { name: 'WaistAcc',    category: 11, subcategory: 26 },
  { name: 'Shirts',      category: 3,  subcategory: 56 },
  { name: 'Pants',       category: 3,  subcategory: 57 },
  { name: 'TShirts',     category: 3,  subcategory: 55 },
];

// Nota: IDs de Shirts/Pants são IDs de produto (template lookup removido para evitar rate limit)

// ─────────────────────────────────────────────────────────────
// Utilitários
// ─────────────────────────────────────────────────────────────

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function sanitizeName(name) {
  if (!name) return 'Unknown';
  return name
    .replace(/["\\\x00-\x1F\x7F]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 60) || 'Unknown';
}

// ─────────────────────────────────────────────────────────────
// HTTP genérico com timeout
// ─────────────────────────────────────────────────────────────

function httpGet(url) {
  return new Promise((resolve, reject) => {
    const req = https.get(url, {
      headers: {
        'User-Agent':      'Roblox/WinInet',
        'Accept':          'application/json',
        'Accept-Language': 'en-US,en;q=0.9',
        'X-CSRF-Token':    '',
      },
    }, (res) => {
      if (res.statusCode === 429) { reject(new Error('rate_limited')); return; }
      if (res.statusCode !== 200) { reject(new Error(`HTTP ${res.statusCode}`)); return; }
      let raw = '';
      res.on('data', c => raw += c);
      res.on('end', () => {
        try { resolve(JSON.parse(raw)); }
        catch (e) { reject(new Error(`JSON: ${e.message} | ${raw.slice(0, 80)}`)); }
      });
    });
    req.on('error', reject);
    req.setTimeout(12000, () => { req.destroy(); reject(new Error('timeout')); });
  });
}

// ─────────────────────────────────────────────────────────────
// Busca de página do catálogo com retry
// ─────────────────────────────────────────────────────────────

function buildCatalogUrl(cat, cursor) {
  let url = `https://catalog.roblox.com/v1/search/items/details`;
  if (cat.assetType !== undefined) {
    // Hats e outros via AssetType direto (subcategoria foi removida da API)
    url += `?AssetType=${cat.assetType}&SortType=${SORT_TYPE}&Limit=30`;
  } else {
    url += `?Category=${cat.category}&Subcategory=${cat.subcategory}`
         + `&SortType=${SORT_TYPE}&Limit=30`;
  }
  if (MAX_PRICE !== null) url += `&MaxPrice=${MAX_PRICE}`;
  if (cursor)             url += `&Cursor=${encodeURIComponent(cursor)}`;
  return url;
}

async function fetchPageWithRetry(cat, cursor) {
  const delays = [500, 1500, 3000, 5000, 8000];  // 5 retries
  for (let i = 0; i <= delays.length; i++) {
    try {
      return await httpGet(buildCatalogUrl(cat, cursor));
    } catch (err) {
      if (i === delays.length) throw err;
      const wait = err.message === 'rate_limited' ? 15000 : delays[i];
      console.log(`  ⚠️  Tentativa ${i + 1} falhou (${err.message}). Aguardando ${wait}ms…`);
      await sleep(wait);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Coleta de uma categoria
// ─────────────────────────────────────────────────────────────

async function fetchCategory(cat) {
  const catName = cat.name;
  console.log(`\n📦 Buscando ${catName}…`);
  const items  = [];
  let   cursor = null;

  while (items.length < ITEMS_PER_SUBCATEGORY) {
    const data = await fetchPageWithRetry(cat, cursor);
    if (!data.data || data.data.length === 0) break;

    for (const item of data.data) {
      if (item.itemType !== 'Asset') continue;
      if (items.length >= ITEMS_PER_SUBCATEGORY) break;

      items.push({
        id:    item.id,
        name:  sanitizeName(item.name),
        price: item.price || 0,
      });
    }

    process.stdout.write(`  → ${items.length} / ${ITEMS_PER_SUBCATEGORY}\r`);

    cursor = data.nextPageCursor;
    if (!cursor || items.length >= ITEMS_PER_SUBCATEGORY) break;

    await sleep(250);
  }

  console.log(`  ✅ ${items.length} itens coletados para ${catName}          `);
  return items;
}

// ─────────────────────────────────────────────────────────────
// Geração do Catalog.luau
// ─────────────────────────────────────────────────────────────

function generateLuau(catalog) {
  const lines = [
    '-- Gerado automaticamente por fetchCatalog.js',
    '-- NÃO EDITE MANUALMENTE — rode `node fetchCatalog.js` para atualizar',
    '-- Nota: IDs de Shirts/Pants são IDs de produto.',
    '-- Se InsertService falhar ao carregar um item, ele é ignorado silenciosamente.',
    '',
    'local Catalog = {}',
    '',
  ];

  for (const [catName, items] of Object.entries(catalog)) {
    lines.push(`Catalog.${catName} = {`);
    for (const item of items) {
      lines.push(`\t{ id = ${item.id}, name = "${item.name}", price = ${item.price} },`);
    }
    lines.push('}');
    lines.push('');
  }

  lines.push(
    '-- Retorna um item aleatório de uma categoria (respeitando blacklist do admin)',
    'function Catalog.getRandom(categoryName: string)',
    '\tlocal list = (Catalog :: any)[categoryName]',
    '\tif not list or #list == 0 then return nil end',
    '\tlocal blacklist = (_G and _G.CatalogBlacklist) or {}',
    '\tlocal available = {}',
    '\tfor _, item in ipairs(list) do',
    '\t\tif not blacklist[item.id] then',
    '\t\t\ttable.insert(available, item)',
    '\t\tend',
    '\tend',
    '\tif #available == 0 then return nil end',
    '\treturn available[math.random(1, #available)]',
    'end',
    '',
    '-- Escolhe categoria aleatória da lista, depois item aleatório dentro dela.',
    '-- Retorna o item com campo extra "category" preenchido.',
    'function Catalog.getRandomFromCategories(categoryList: { string })',
    '\tif #categoryList == 0 then return nil end',
    '\tlocal cat  = categoryList[math.random(1, #categoryList)]',
    '\tlocal item = Catalog.getRandom(cat)',
    '\tif not item then return nil end',
    '\treturn { id = item.id, name = item.name, price = item.price, category = cat }',
    'end',
    '',
    'return Catalog',
  );

  return lines.join('\n');
}

// ─────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────

async function main() {
  console.log('🚀 Iniciando busca no catálogo do Roblox…');
  console.log(`   ITEMS_PER_SUBCATEGORY = ${ITEMS_PER_SUBCATEGORY}`);
  console.log(`   MAX_PRICE             = ${MAX_PRICE ?? 'sem limite'}`);
  console.log(`   Categorias            = ${CATEGORIES.length}`);

  const catalog = {};

  for (const cat of CATEGORIES) {
    try {
      catalog[cat.name] = await fetchCategory(cat);
    } catch (err) {
      console.error(`  ❌ Erro fatal ao buscar ${cat.name}: ${err.message}`);
      catalog[cat.name] = [];
    }
    await sleep(5000);  // 5s entre categorias para evitar rate limit
  }

  const outputPath = path.join(__dirname, 'src', 'shared', 'Catalog.luau');
  fs.writeFileSync(outputPath, generateLuau(catalog), 'utf8');

  const total = Object.values(catalog).reduce((s, a) => s + a.length, 0);
  console.log(`\n🎉 Catalog.luau gerado: ${outputPath}`);
  console.log(`📊 Total: ${total} itens em ${Object.keys(catalog).length} categorias`);

  console.log('\n📊 Resumo:');
  for (const [name, items] of Object.entries(catalog)) {
    const fallbacks = items.filter(i => i.templateFallback).length;
    const warn = items.length < 30
      ? '  ⚠️  POUCOS ITENS'
      : fallbacks > 0
        ? `  ⚠️  ${fallbacks} sem template`
        : '';
    console.log(`  ${name.padEnd(15)} ${String(items.length).padStart(3)} itens${warn}`);
  }

  const vazias = Object.entries(catalog).filter(([, v]) => v.length === 0).map(([k]) => k);
  if (vazias.length > 0) {
    console.warn(`⚠️  Categorias vazias: ${vazias.join(', ')}`);
  }

  console.log('\n✅ Rode: rojo serve click-simulator');
  console.log('   Depois Play no Studio pra ver as mudanças');
}

main().catch(err => {
  console.error('❌ Erro inesperado:', err);
  process.exit(1);
});
