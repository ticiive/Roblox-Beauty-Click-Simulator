-- ═══════════════════════════════════════════════════════════════
-- MobiliarioCentral — carrega balcão e tapete da Roblox e posiciona
-- no interior da loja. Sem modelo customizado: usa os assets como vêm.
-- ═══════════════════════════════════════════════════════════════

local InsertService = game:GetService("InsertService")
local Workspace     = game:GetService("Workspace")

-- ─────────────────────────────────────────────────────────────
-- CONFIGURAÇÕES
-- ─────────────────────────────────────────────────────────────
local ID_BALCAO = 71607790019809
local ID_TAPETE = 75340081898198

-- Posições no mundo
local POSICAO_BALCAO = Vector3.new(0, 0, -12)  -- centro-fundo da loja
local POSICAO_TAPETE = Vector3.new(0, 0,   0)  -- centro exato da loja

-- Rotação opcional em Y (radianos) — ajuste se a face do asset não estiver virada para o lado correto
local ROT_BALCAO = 0
local ROT_TAPETE = 0

-- Delay entre LoadAsset para evitar rate limit do InsertService
local DELAY_ENTRE_LOADS = 3

-- ─────────────────────────────────────────────────────────────
-- PASTA ISOLADA
-- ─────────────────────────────────────────────────────────────
local raiz = Workspace:FindFirstChild("MobiliarioCentral") or Instance.new("Folder")
raiz.Name   = "MobiliarioCentral"
raiz.Parent = Workspace

-- ─────────────────────────────────────────────────────────────
-- HELPER: carrega asset, posiciona e ancora
-- ─────────────────────────────────────────────────────────────
local function carregarAsset(assetId, nome, posicao, rotY, canCollide)
	local ok, container = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok or not container then
		warn("[MobiliarioCentral] Falha LoadAsset", assetId, ":", container)
		return nil
	end

	local model = container:FindFirstChildOfClass("Model") or container:GetChildren()[1]
	if not model then
		warn("[MobiliarioCentral] Asset vazio:", assetId)
		container:Destroy()
		return nil
	end

	model.Parent = nil
	container:Destroy()

	model.Name = nome

	-- Ancora todas as partes; aplica colisão conforme parâmetro
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored   = true
			p.CanCollide = canCollide
		end
	end

	-- Garante PrimaryPart para PivotTo funcionar
	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
	end
	if model.PrimaryPart then
		model:PivotTo(CFrame.new(posicao) * CFrame.Angles(0, rotY, 0))
	end

	model.Parent = raiz
	print(string.format("[MobiliarioCentral] %s posicionado em %s", nome, tostring(posicao)))
	return model
end

-- ─────────────────────────────────────────────────────────────
-- INICIALIZAÇÃO
-- ─────────────────────────────────────────────────────────────
task.spawn(function()
	-- Balcão sólido (jogadores não atravessam)
	carregarAsset(ID_BALCAO, "Balcao", POSICAO_BALCAO, ROT_BALCAO, true)

	task.wait(DELAY_ENTRE_LOADS)

	-- Tapete sem colisão (jogadores andam por cima)
	carregarAsset(ID_TAPETE, "Tapete", POSICAO_TAPETE, ROT_TAPETE, false)

	print("[MobiliarioCentral] Pronto.")
end)
