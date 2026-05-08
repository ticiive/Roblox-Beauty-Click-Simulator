-- ═══════════════════════════════════════════════════════════════
-- LojaDecorPro — Espelhos, Manequins, Araras, Prateleiras
-- ServerScriptService
-- ═══════════════════════════════════════════════════════════════

-- ┌─────────────────────────────────────────────────────────────┐
-- │ CONFIGURAÇÕES                                               │
-- └─────────────────────────────────────────────────────────────┘
local QUANTIDADE_ESPELHOS    = 4
local QUANTIDADE_MANEQUINS   = 3
local QUANTIDADE_ARARAS      = 3
-- AJUSTE: mínimo recomendado 12; distribuído em 3 fileiras paralelas com ≥6 studs entre prateleiras
local QUANTIDADE_PRATELEIRAS = 12

local POSICAO_INICIAL  = Vector3.new(0, 0, 0)  -- centro da loja
local LOJA_LARGURA     = 40   -- eixo X (paredes esquerda/direita)
local LOJA_COMPRIMENTO = 60   -- eixo Z (paredes frente/fundo)
local LOJA_ALTURA      = 10   -- do chão ao teto

-- IDs de roupas por manequim (0 = sem roupa)
-- Substitua pelos IDs reais dos assets de Shirt/Pants da Roblox
local ROUPAS_MANEQUINS = {
	[1] = { shirt = 0, pants = 0 },
	[2] = { shirt = 0, pants = 0 },
	[3] = { shirt = 0, pants = 0 },
}

-- Cores das roupas decorativas penduradas nas araras
local CORES_ARARAS = {
	Color3.fromRGB(220,  80,  80),
	Color3.fromRGB( 80, 120, 220),
	Color3.fromRGB( 80, 180,  80),
	Color3.fromRGB(220, 180,  50),
	Color3.fromRGB(180,  80, 180),
	Color3.fromRGB(220, 140,  80),
}

-- Cores dos produtos decorativos nas prateleiras
local CORES_PRODUTOS = {
	Color3.fromRGB(200,  60,  60),
	Color3.fromRGB( 60,  60, 200),
	Color3.fromRGB( 60, 160,  60),
	Color3.fromRGB(200, 160,  40),
	Color3.fromRGB(160,  60, 160),
	Color3.fromRGB( 60, 160, 160),
	Color3.fromRGB(200, 200, 200),
}

-- ┌─────────────────────────────────────────────────────────────┐
-- │ SERVIÇOS E PASTA RAIZ                                       │
-- └─────────────────────────────────────────────────────────────┘
local Workspace = game:GetService("Workspace")

local raiz = Workspace:FindFirstChild("LojaDecorPro") or Instance.new("Folder")
raiz.Name   = "LojaDecorPro"
raiz.Parent = Workspace

-- ┌─────────────────────────────────────────────────────────────┐
-- │ HELPER: cria Part ancorada e sem colisão                    │
-- └─────────────────────────────────────────────────────────────┘
local function novaPart(parent, nome, tamanho, cor, material, cf)
	local p         = Instance.new("Part")
	p.Name          = nome
	p.Size          = tamanho
	p.Color         = cor
	p.Material      = material
	p.Anchored      = true
	p.CanCollide    = false
	p.CastShadow    = false
	p.CFrame        = cf
	p.Parent        = parent
	return p
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │ 1. ESPELHOS                                                 │
-- └─────────────────────────────────────────────────────────────┘
-- AJUSTE: espelhos agora ficam grudados em TODAS as 4 paredes (Norte/Sul/
-- Leste/Oeste), com a parte de trás encostada na parede e a face apontando
-- para o interior da loja. A orientação do slab muda conforme a parede:
--   • Paredes Leste/Oeste (eixo X)  → fino em X, largo em Z, alto em Y
--   • Paredes Norte/Sul   (eixo Z)  → fino em Z, largo em X, alto em Y
-- A distribuição é uniforme: QUANTIDADE_ESPELHOS / 4 por parede (com sobra
-- direcionada para Norte → Sul → Leste → Oeste, nessa ordem).

local ESP_LARG  = 3     -- largura (ao longo da parede)
local ESP_ALT   = 5     -- altura (eixo Y)
local ESP_PROF  = 0.15  -- espessura (perpendicular à parede)
local MOL_ESP   = 0.3   -- espessura da moldura

local COR_ESP   = Color3.fromRGB(190, 215, 230)  -- vidro prateado
local COR_MOL   = Color3.fromRGB(212, 175,  55)  -- dourado

-- AJUSTE: parede recebida como string "N"/"S"/"L"/"O" — define orientação do slab
local function criarEspelho(cx, cy, cz, parede)
	local m      = Instance.new("Model")
	m.Name       = "Espelho_" .. parede
	m.Parent     = raiz

	local fd = ESP_PROF + 0.02              -- profundidade da moldura (um pouco mais espessa)
	local eh = ESP_ALT  / 2 + MOL_ESP / 2  -- offset vertical para topo/base
	local ew = ESP_LARG / 2 + MOL_ESP / 2  -- offset lateral para esq/dir

	-- Tamanhos e offsets variam conforme a parede
	local espSize, topoSize, lateralSize
	local topoCF, baseCF, esqCF, dirCF

	if parede == "L" or parede == "O" then
		-- AJUSTE: paredes Leste/Oeste — slab fino em X
		espSize     = Vector3.new(ESP_PROF, ESP_ALT, ESP_LARG)
		topoSize    = Vector3.new(fd, MOL_ESP, ESP_LARG + MOL_ESP * 2)
		lateralSize = Vector3.new(fd, ESP_ALT + MOL_ESP * 2, MOL_ESP)
		topoCF      = CFrame.new(0,  eh, 0)
		baseCF      = CFrame.new(0, -eh, 0)
		esqCF       = CFrame.new(0,   0, -ew)
		dirCF       = CFrame.new(0,   0,  ew)
	else
		-- AJUSTE: paredes Norte/Sul — slab fino em Z
		espSize     = Vector3.new(ESP_LARG, ESP_ALT, ESP_PROF)
		topoSize    = Vector3.new(ESP_LARG + MOL_ESP * 2, MOL_ESP, fd)
		lateralSize = Vector3.new(MOL_ESP, ESP_ALT + MOL_ESP * 2, fd)
		topoCF      = CFrame.new(  0,  eh, 0)
		baseCF      = CFrame.new(  0, -eh, 0)
		esqCF       = CFrame.new(-ew,   0, 0)
		dirCF       = CFrame.new( ew,   0, 0)
	end

	local cf  = CFrame.new(cx, cy, cz)

	-- Superfície reflexiva (back encostada na parede, face para o interior)
	local sup = novaPart(m, "Superficie", espSize, COR_ESP, Enum.Material.Glass, cf)
	sup.Reflectance = 0.85
	m.PrimaryPart   = sup

	-- Moldura ao redor (4 barras orientadas pela parede)
	novaPart(m, "MolduraTopo", topoSize,    COR_MOL, Enum.Material.SmoothPlastic, cf * topoCF)
	novaPart(m, "MolduraBase", topoSize,    COR_MOL, Enum.Material.SmoothPlastic, cf * baseCF)
	novaPart(m, "MolduraEsq",  lateralSize, COR_MOL, Enum.Material.SmoothPlastic, cf * esqCF)
	novaPart(m, "MolduraDir",  lateralSize, COR_MOL, Enum.Material.SmoothPlastic, cf * dirCF)

	return m
end

local function spawnEspelhos()
	local cx0 = POSICAO_INICIAL.X
	local cz0 = POSICAO_INICIAL.Z
	-- Centro da moldura a 3.5 studs do chão → base em Y+1, topo em Y+6
	local cy  = POSICAO_INICIAL.Y + 3.5

	-- AJUSTE: distribui espelhos uniformemente nas 4 paredes
	local base  = math.floor(QUANTIDADE_ESPELHOS / 4)
	local resto = QUANTIDADE_ESPELHOS - base * 4
	local nN    = base + (resto >= 1 and 1 or 0)
	local nS    = base + (resto >= 2 and 1 or 0)
	local nL    = base + (resto >= 3 and 1 or 0)
	local nO    = base

	-- Coordenadas das paredes (face do espelho aponta para dentro da loja)
	local zNorte = cz0 - LOJA_COMPRIMENTO / 2 + ESP_PROF / 2 + 0.05
	local zSul   = cz0 + LOJA_COMPRIMENTO / 2 - ESP_PROF / 2 - 0.05
	local xLeste = cx0 + LOJA_LARGURA   / 2 - ESP_PROF / 2 - 0.05
	local xOeste = cx0 - LOJA_LARGURA   / 2 + ESP_PROF / 2 + 0.05

	-- Norte: varia X (parede "horizontal")
	for i = 1, nN do
		local x = cx0 - LOJA_LARGURA / 2 + (LOJA_LARGURA / (nN + 1)) * i
		criarEspelho(x, cy, zNorte, "N")
	end
	-- Sul: varia X
	for i = 1, nS do
		local x = cx0 - LOJA_LARGURA / 2 + (LOJA_LARGURA / (nS + 1)) * i
		criarEspelho(x, cy, zSul, "S")
	end
	-- Leste: varia Z (parede "vertical")
	for i = 1, nL do
		local z = cz0 - LOJA_COMPRIMENTO / 2 + (LOJA_COMPRIMENTO / (nL + 1)) * i
		criarEspelho(xLeste, cy, z, "L")
	end
	-- Oeste: varia Z
	for i = 1, nO do
		local z = cz0 - LOJA_COMPRIMENTO / 2 + (LOJA_COMPRIMENTO / (nO + 1)) * i
		criarEspelho(xOeste, cy, z, "O")
	end
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │ 2. MANEQUINS                                                │
-- └─────────────────────────────────────────────────────────────┘
-- Estrutura R6 (nomes obrigatórios para Shirt/Pants renderizarem):
--   HumanoidRootPart, Torso, Head, Left Arm, Right Arm, Left Leg, Right Leg
-- Um Humanoid é inserido para que o engine aplique as roupas.

local COR_MAN = Color3.fromRGB(220, 210, 195)  -- bege neutro

local function criarManequim(posicao, idx)
	local m    = Instance.new("Model")
	m.Name     = "Manequim_" .. idx
	m.Parent   = raiz

	local px, pz = posicao.X, posicao.Z
	local gy     = posicao.Y  -- nível do chão

	-- ── Pedestal ──────────────────────────────────────────────
	novaPart(m, "Pedestal",
		Vector3.new(1.4, 0.5, 1.4),
		Color3.fromRGB(160, 160, 160), Enum.Material.SmoothPlastic,
		CFrame.new(px, gy + 0.25, pz))

	-- ── HumanoidRootPart (invisível, âncora do rig) ───────────
	local hrp           = Instance.new("Part")
	hrp.Name            = "HumanoidRootPart"
	hrp.Size            = Vector3.new(2, 2, 1)
	hrp.Anchored        = true
	hrp.Transparency    = 1
	hrp.CanCollide      = false
	hrp.CFrame          = CFrame.new(px, gy + 2.5, pz)
	hrp.Parent          = m
	m.PrimaryPart       = hrp

	-- ── Pernas (apoiadas sobre o pedestal) ────────────────────
	local legY = gy + 0.5 + 1.0  -- pedestal (0.5) + metade da perna (1.0)
	novaPart(m, "Left Leg",  Vector3.new(1, 2, 1), COR_MAN, Enum.Material.SmoothPlastic,
		CFrame.new(px - 0.5, legY, pz))
	novaPart(m, "Right Leg", Vector3.new(1, 2, 1), COR_MAN, Enum.Material.SmoothPlastic,
		CFrame.new(px + 0.5, legY, pz))

	-- ── Torso (acima das pernas) ──────────────────────────────
	local torsoY = gy + 0.5 + 2.0 + 1.0  -- topo das pernas (0.5+2) + metade do torso (1)
	novaPart(m, "Torso", Vector3.new(2, 2, 1), COR_MAN, Enum.Material.SmoothPlastic,
		CFrame.new(px, torsoY, pz))

	-- ── Braços (mesma altura do torso) ────────────────────────
	novaPart(m, "Left Arm",  Vector3.new(1, 2, 1), COR_MAN, Enum.Material.SmoothPlastic,
		CFrame.new(px - 1.5, torsoY, pz))
	novaPart(m, "Right Arm", Vector3.new(1, 2, 1), COR_MAN, Enum.Material.SmoothPlastic,
		CFrame.new(px + 1.5, torsoY, pz))

	-- ── Cabeça (acima do torso) ───────────────────────────────
	local headY = torsoY + 1.5  -- topo do torso (torsoY+1) + metade da cabeça (0.5)
	novaPart(m, "Head", Vector3.new(2, 1, 1), COR_MAN, Enum.Material.SmoothPlastic,
		CFrame.new(px, headY, pz))

	-- ── Humanoid ──────────────────────────────────────────────
	local hum                    = Instance.new("Humanoid")
	hum.MaxHealth                = 100
	hum.Health                   = 100
	hum.DisplayDistanceType      = Enum.HumanoidDisplayDistanceType.None
	hum.NameDisplayDistance      = 0
	hum.HealthDisplayDistance    = 0
	hum.Parent                   = m

	-- ── Roupas ────────────────────────────────────────────────
	local roupas = ROUPAS_MANEQUINS[idx]
	if roupas then
		if roupas.shirt ~= 0 then
			local s         = Instance.new("Shirt")
			s.ShirtTemplate = "rbxassetid://" .. roupas.shirt
			s.Parent        = m
		end
		if roupas.pants ~= 0 then
			local p          = Instance.new("Pants")
			p.PantsTemplate  = "rbxassetid://" .. roupas.pants
			p.Parent         = m
		end
	end

	return m
end

local function spawnManequins()
	local cx0 = POSICAO_INICIAL.X
	local cz0 = POSICAO_INICIAL.Z
	local gy  = POSICAO_INICIAL.Y
	-- Lado esquerdo da loja, enfileirados ao longo de Z
	local manX = cx0 - LOJA_LARGURA / 4

	for i = 1, QUANTIDADE_MANEQUINS do
		local z = cz0 - LOJA_COMPRIMENTO / 2 + (LOJA_COMPRIMENTO / (QUANTIDADE_MANEQUINS + 1)) * i
		criarManequim(Vector3.new(manX, gy, z), i)
	end
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │ 3. ARARAS DE ROUPAS                                         │
-- └─────────────────────────────────────────────────────────────┘
-- Estrutura: 2 pés verticais + barra horizontal superior + 2 bases de apoio.
-- Cada arara tem ROUPAS_POR_ARARA peças decorativas penduradas.

local ARARA_ALT       = 5
local ROUPAS_POR_ARARA = 5
local COR_ARARA       = Color3.fromRGB(60, 60, 60)  -- metal escuro

local function criarArara(posicao, idx)
	local m    = Instance.new("Model")
	m.Name     = "Arara_" .. idx
	m.Parent   = raiz

	local px, py, pz = posicao.X, posicao.Y, posicao.Z

	-- Pés verticais
	novaPart(m, "PeEsq", Vector3.new(0.12, ARARA_ALT, 0.12), COR_ARARA, Enum.Material.Metal,
		CFrame.new(px - 2, py + ARARA_ALT / 2, pz))
	novaPart(m, "PeDir", Vector3.new(0.12, ARARA_ALT, 0.12), COR_ARARA, Enum.Material.Metal,
		CFrame.new(px + 2, py + ARARA_ALT / 2, pz))

	-- Barra horizontal superior
	novaPart(m, "BarraSup", Vector3.new(4.0, 0.12, 0.12), COR_ARARA, Enum.Material.Metal,
		CFrame.new(px, py + ARARA_ALT - 0.06, pz))

	-- Bases de apoio no chão (perpendiculares aos pés)
	novaPart(m, "BaseEsq", Vector3.new(0.12, 0.12, 2), COR_ARARA, Enum.Material.Metal,
		CFrame.new(px - 2, py + 0.06, pz))
	novaPart(m, "BaseDir", Vector3.new(0.12, 0.12, 2), COR_ARARA, Enum.Material.Metal,
		CFrame.new(px + 2, py + 0.06, pz))

	-- Roupas e cabides pendurados na barra
	local spacingX = 4.0 / (ROUPAS_POR_ARARA + 1)
	for j = 1, ROUPAS_POR_ARARA do
		local rx  = px - 2 + spacingX * j
		local cor = CORES_ARARAS[((j - 1) % #CORES_ARARAS) + 1]

		-- Haste vertical do cabide (da barra até a peça de roupa)
		novaPart(m, "Haste_" .. j,
			Vector3.new(0.06, 0.7, 0.06), COR_ARARA, Enum.Material.Metal,
			CFrame.new(rx, py + ARARA_ALT - 0.41, pz))

		-- Ombros do cabide (barra horizontal fina)
		novaPart(m, "Ombros_" .. j,
			Vector3.new(0.06, 0.06, 0.7), COR_ARARA, Enum.Material.Metal,
			CFrame.new(rx, py + ARARA_ALT - 0.82, pz))

		-- Roupa pendurada (retângulo colorido)
		novaPart(m, "Roupa_" .. j,
			Vector3.new(0.06, 1.6, 0.85), cor, Enum.Material.SmoothPlastic,
			CFrame.new(rx, py + ARARA_ALT - 1.75, pz))
	end

	return m
end

local function spawnAraras()
	local cx0 = POSICAO_INICIAL.X
	local cz0 = POSICAO_INICIAL.Z
	local gy  = POSICAO_INICIAL.Y
	-- Lado direito da loja, enfileiradas ao longo de Z
	local araraX = cx0 + LOJA_LARGURA / 4

	for i = 1, QUANTIDADE_ARARAS do
		local z = cz0 - LOJA_COMPRIMENTO / 2 + (LOJA_COMPRIMENTO / (QUANTIDADE_ARARAS + 1)) * i
		criarArara(Vector3.new(araraX, gy, z), i)
	end
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │ 4. PRATELEIRAS — EXPANSÃO DINÂMICA                          │
-- └─────────────────────────────────────────────────────────────┘
-- criarPrateleira(posicao, tamanho) — instância uma prateleira completa:
--   estrutura lateral, base, topo, fundo, N bandejas, divisórias e
--   produtos decorativos (Parts coloridas) sobre cada bandeja.

local COR_MAD_ESC = Color3.fromRGB(100,  70, 40)  -- madeira escura (estrutura)
local COR_MAD_MED = Color3.fromRGB(160, 110, 60)  -- madeira média (bandejas)
local COR_MAD_CLA = Color3.fromRGB(180, 130, 75)  -- madeira clara (divisórias/fundo)

local NIVEIS_PRATELEIRA = 3  -- bandejas internas por prateleira

local function criarPrateleira(posicao, tamanho)
	local t    = tamanho or Vector3.new(4, 5, 1)
	local larg = t.X
	local alt  = t.Y
	local prof = t.Z
	local esp  = 0.12  -- espessura das tábuas

	local m    = Instance.new("Model")
	m.Name     = "Prateleira"
	m.Parent   = raiz

	local px, py, pz = posicao.X, posicao.Y, posicao.Z

	-- Laterais (paredes dos lados)
	novaPart(m, "LadoEsq", Vector3.new(esp, alt, prof), COR_MAD_ESC, Enum.Material.Wood,
		CFrame.new(px - larg / 2, py + alt / 2, pz))
	novaPart(m, "LadoDir", Vector3.new(esp, alt, prof), COR_MAD_ESC, Enum.Material.Wood,
		CFrame.new(px + larg / 2, py + alt / 2, pz))

	-- Base
	novaPart(m, "Base", Vector3.new(larg + esp * 2, esp, prof), COR_MAD_ESC, Enum.Material.Wood,
		CFrame.new(px, py + esp / 2, pz))

	-- Topo
	novaPart(m, "Topo", Vector3.new(larg + esp * 2, esp, prof), COR_MAD_ESC, Enum.Material.Wood,
		CFrame.new(px, py + alt, pz))

	-- Fundo (painel traseiro)
	novaPart(m, "Fundo", Vector3.new(larg, alt, esp), COR_MAD_CLA, Enum.Material.Wood,
		CFrame.new(px, py + alt / 2, pz - prof / 2 + esp / 2))

	-- Bandejas internas + divisórias + produtos
	local espacoNivel = alt / (NIVEIS_PRATELEIRA + 1)
	for n = 1, NIVEIS_PRATELEIRA do
		local ny = py + espacoNivel * n

		-- Bandeja
		novaPart(m, "Nivel_" .. n, Vector3.new(larg, esp, prof), COR_MAD_MED, Enum.Material.Wood,
			CFrame.new(px, ny, pz))

		-- Divisória central
		novaPart(m, "Divisoria_" .. n,
			Vector3.new(esp, espacoNivel - esp * 2, prof),
			COR_MAD_CLA, Enum.Material.Wood,
			CFrame.new(px, ny + (espacoNivel - esp) / 2, pz))

		-- Produtos decorativos sobre a bandeja
		local numProd    = math.random(2, 4)
		local spacingProd = larg / (numProd + 1)
		for k = 1, numProd do
			local prodX  = px - larg / 2 + spacingProd * k
			local pw     = 0.25 + math.random() * 0.3
			local ph     = 0.3  + math.random() * 0.5
			local pz2    = pz + (math.random() - 0.5) * (prof * 0.3)
			local cor    = CORES_PRODUTOS[math.random(#CORES_PRODUTOS)]
			novaPart(m, "Prod_" .. n .. "_" .. k,
				Vector3.new(pw, ph, prof * 0.5),
				cor, Enum.Material.SmoothPlastic,
				CFrame.new(prodX, ny + esp / 2 + ph / 2, pz2))
		end
	end

	return m
end

-- AJUSTE: prateleiras agora ficam em 3 fileiras paralelas em X — uma corredor à
-- esquerda (entre parede oeste e manequins), uma central e uma à direita (entre
-- araras e parede leste). Cada fileira é alinhada em Z com espaçamento mínimo
-- de 6 studs entre prateleiras adjacentes. Os corredores X = ±10 ficam livres
-- para os manequins (X≈-10) e araras (X≈+10).
local FILEIRAS_PRATELEIRAS_X = { -16, 0, 16 }
local ESPACAMENTO_MIN_PRATELEIRAS = 6  -- AJUSTE: mínimo de studs entre prateleiras

local function spawnPrateleiras()
	local cx0 = POSICAO_INICIAL.X
	local cz0 = POSICAO_INICIAL.Z
	local gy  = POSICAO_INICIAL.Y
	local t   = Vector3.new(4, 5, 1)

	-- AJUSTE: distribui QUANTIDADE_PRATELEIRAS entre as fileiras X de forma equilibrada
	local numFileiras = #FILEIRAS_PRATELEIRAS_X
	local base        = math.floor(QUANTIDADE_PRATELEIRAS / numFileiras)
	local resto       = QUANTIDADE_PRATELEIRAS - base * numFileiras

	local count = 0
	for idx, x in ipairs(FILEIRAS_PRATELEIRAS_X) do
		-- AJUSTE: distribui sobra (resto) nas primeiras fileiras
		local porFileira = base + (idx <= resto and 1 or 0)
		if porFileira > 0 then
			local spacingZ = LOJA_COMPRIMENTO / (porFileira + 1)
			-- AJUSTE: avisa se o espaçamento ficou abaixo do mínimo recomendado
			if spacingZ < ESPACAMENTO_MIN_PRATELEIRAS then
				warn(string.format(
					"[LojaDecorPro] Espaçamento entre prateleiras (%.1f) na fileira X=%d abaixo do mínimo (%d). Reduza QUANTIDADE_PRATELEIRAS ou aumente LOJA_COMPRIMENTO.",
					spacingZ, x, ESPACAMENTO_MIN_PRATELEIRAS))
			end
			for j = 1, porFileira do
				count += 1
				local z = cz0 - LOJA_COMPRIMENTO / 2 + spacingZ * j
				criarPrateleira(Vector3.new(x, gy, z), t)
			end
		end
	end
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │ INICIALIZAÇÃO                                               │
-- └─────────────────────────────────────────────────────────────┘
spawnEspelhos()
spawnManequins()
spawnAraras()
spawnPrateleiras()

print(string.format(
	"[LojaDecorPro] Decoração completa — %d espelhos | %d manequins | %d araras | %d prateleiras",
	QUANTIDADE_ESPELHOS, QUANTIDADE_MANEQUINS, QUANTIDADE_ARARAS, QUANTIDADE_PRATELEIRAS
))
