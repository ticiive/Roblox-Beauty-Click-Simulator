-- ═══════════════════════════════════════════════════════════════
-- PrateleirasParede — carrega asset 2770430570 e distribui nas 4
-- paredes da loja, recolorindo para combinar com o tema (creme +
-- dourado). Sem modelo customizado: clona o asset e troca cor/material.
-- ═══════════════════════════════════════════════════════════════

local InsertService = game:GetService("InsertService")
local Workspace     = game:GetService("Workspace")

-- ─────────────────────────────────────────────────────────────
-- CONFIGURAÇÕES
-- ─────────────────────────────────────────────────────────────
local ID_PRATELEIRA = 2770430570

-- Posição/dimensões da loja (centro e extensão)
local CENTRO_LOJA   = Vector3.new(0, 0, 0)
local LOJA_LARGURA  = 40   -- eixo X
local LOJA_COMPRIM  = 60   -- eixo Z

-- Quantidade de prateleiras por parede
local POR_PAREDE = {
	Norte = 3,  -- parede em Z = -COMPRIM/2
	Sul   = 3,  -- parede em Z = +COMPRIM/2
	Leste = 3,  -- parede em X = +LARGURA/2
	Oeste = 3,  -- parede em X = -LARGURA/2
}

-- Distância da prateleira até a parede (encostada)
local OFFSET_PAREDE = 1.5

-- Tema visual (cosméticos: creme + dourado)
local COR_PRINCIPAL = Color3.fromRGB(245, 232, 215)  -- creme
local COR_ACENTO    = Color3.fromRGB(212, 175,  55)  -- dourado
local MATERIAL      = Enum.Material.SmoothPlastic

-- ─────────────────────────────────────────────────────────────
-- PASTA ISOLADA
-- ─────────────────────────────────────────────────────────────
local raiz = Workspace:FindFirstChild("PrateleirasParede") or Instance.new("Folder")
raiz.Name   = "PrateleirasParede"
raiz.Parent = Workspace

-- ─────────────────────────────────────────────────────────────
-- CARREGA O ASSET UMA VEZ E CLONA NAS POSIÇÕES
-- ─────────────────────────────────────────────────────────────
local function carregarTemplate()
	local ok, container = pcall(function()
		return InsertService:LoadAsset(ID_PRATELEIRA)
	end)
	if not ok or not container then
		warn("[PrateleirasParede] Falha LoadAsset:", container)
		return nil
	end

	local model = container:FindFirstChildOfClass("Model") or container:GetChildren()[1]
	if not model then
		warn("[PrateleirasParede] Asset vazio")
		container:Destroy()
		return nil
	end

	model.Parent = nil
	container:Destroy()
	return model
end

-- Aplica a paleta da loja em todas as partes do modelo.
-- Mantém o formato original do asset; apenas troca cor e material.
local function retexturar(modelo)
	local i = 0
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored   = true
			p.CanCollide = true
			p.Material   = MATERIAL
			-- Alterna entre cor principal e acento dourado para dar contraste
			i += 1
			p.Color = (i % 5 == 0) and COR_ACENTO or COR_PRINCIPAL
		elseif p:IsA("Decal") or p:IsA("Texture") then
			-- Remove texturas originais para que a nova cor apareça limpa
			p:Destroy()
		elseif p:IsA("SurfaceAppearance") then
			p:Destroy()
		end
	end
end

local function spawnPrateleira(template, cf, idx)
	local copia = template:Clone()
	copia.Name  = "Prateleira_" .. idx

	retexturar(copia)

	if not copia.PrimaryPart then
		copia.PrimaryPart = copia:FindFirstChildWhichIsA("BasePart", true)
	end
	if copia.PrimaryPart then
		copia:PivotTo(cf)
	end

	copia.Parent = raiz
	return copia
end

-- ─────────────────────────────────────────────────────────────
-- DISTRIBUIÇÃO NAS 4 PAREDES
-- ─────────────────────────────────────────────────────────────
local function distribuir(template)
	local cx, cy, cz = CENTRO_LOJA.X, CENTRO_LOJA.Y, CENTRO_LOJA.Z
	local idx = 0

	-- Norte: parede em Z mínimo, face apontando para +Z
	local zN = cz - LOJA_COMPRIM / 2 + OFFSET_PAREDE
	for i = 1, POR_PAREDE.Norte do
		idx += 1
		local x = cx - LOJA_LARGURA / 2 + (LOJA_LARGURA / (POR_PAREDE.Norte + 1)) * i
		spawnPrateleira(template,
			CFrame.new(x, cy, zN) * CFrame.Angles(0, 0, 0), idx)
	end

	-- Sul: parede em Z máximo, face apontando para -Z (rot 180°)
	local zS = cz + LOJA_COMPRIM / 2 - OFFSET_PAREDE
	for i = 1, POR_PAREDE.Sul do
		idx += 1
		local x = cx - LOJA_LARGURA / 2 + (LOJA_LARGURA / (POR_PAREDE.Sul + 1)) * i
		spawnPrateleira(template,
			CFrame.new(x, cy, zS) * CFrame.Angles(0, math.pi, 0), idx)
	end

	-- Leste: parede em X máximo, face apontando para -X (rot -90°)
	local xL = cx + LOJA_LARGURA / 2 - OFFSET_PAREDE
	for i = 1, POR_PAREDE.Leste do
		idx += 1
		local z = cz - LOJA_COMPRIM / 2 + (LOJA_COMPRIM / (POR_PAREDE.Leste + 1)) * i
		spawnPrateleira(template,
			CFrame.new(xL, cy, z) * CFrame.Angles(0, -math.pi / 2, 0), idx)
	end

	-- Oeste: parede em X mínimo, face apontando para +X (rot 90°)
	local xO = cx - LOJA_LARGURA / 2 + OFFSET_PAREDE
	for i = 1, POR_PAREDE.Oeste do
		idx += 1
		local z = cz - LOJA_COMPRIM / 2 + (LOJA_COMPRIM / (POR_PAREDE.Oeste + 1)) * i
		spawnPrateleira(template,
			CFrame.new(xO, cy, z) * CFrame.Angles(0, math.pi / 2, 0), idx)
	end

	return idx
end

-- ─────────────────────────────────────────────────────────────
-- INICIALIZAÇÃO
-- ─────────────────────────────────────────────────────────────
task.spawn(function()
	local template = carregarTemplate()
	if not template then return end

	local total = distribuir(template)
	template:Destroy()  -- libera o template original; só os clones ficam

	print(string.format("[PrateleirasParede] %d prateleiras distribuídas nas 4 paredes.", total))
end)
