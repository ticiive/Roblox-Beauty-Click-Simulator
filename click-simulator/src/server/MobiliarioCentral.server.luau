-- ═══════════════════════════════════════════════════════════════
-- MobiliarioCentral — carrega balcão e tapete da Roblox e posiciona
-- no interior da loja. Usa bounding box para apoiar no piso (Y=0).
-- ═══════════════════════════════════════════════════════════════

local InsertService = game:GetService("InsertService")
local Workspace     = game:GetService("Workspace")

-- ─────────────────────────────────────────────────────────────
-- CONFIGURAÇÕES
-- ─────────────────────────────────────────────────────────────
local ID_BALCAO = 71607790019809
local ID_TAPETE = 75340081898198

-- Coordenadas do PISO (centro da loja em Environment_Pobre é 0,0,0; piso em Y=0)
local PISO_Y           = 0
local POS_BALCAO_XZ    = Vector2.new(0, -12)   -- centro-fundo
local POS_TAPETE_XZ    = Vector2.new(0,   0)   -- centro exato

-- Rotação Y (ajuste se a face vier virada para o lado errado)
local ROT_BALCAO = 0
local ROT_TAPETE = 0

-- Pequena elevação extra do tapete para evitar z-fighting com o piso
local LIFT_TAPETE = 0.05

local DELAY_ENTRE_LOADS = 3

-- ─────────────────────────────────────────────────────────────
-- PASTA ISOLADA
-- ─────────────────────────────────────────────────────────────
local raiz = Workspace:FindFirstChild("MobiliarioCentral") or Instance.new("Folder")
raiz.Name   = "MobiliarioCentral"
raiz.Parent = Workspace

-- ─────────────────────────────────────────────────────────────
-- HELPER: carrega asset e apoia no piso
-- ─────────────────────────────────────────────────────────────
-- targetXZ: Vector2 (X, Z) do ponto de apoio
-- pisoY:   nível do chão; o modelo é elevado para que sua base toque esse Y
-- liftExtra: offset adicional opcional (ex: tapete fica 0.05 acima para não conflitar)
local function carregarAsset(assetId, nome, targetXZ, pisoY, rotY, canCollide, liftExtra)
	local ok, container = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok or not container then
		warn(string.format("[MobiliarioCentral] Falha LoadAsset(%d) — asset pode não ser público ou não pertencer ao dono do place: %s", assetId, tostring(container)))
		return nil
	end

	local model = container:FindFirstChildOfClass("Model")
	if not model then
		-- Caso o asset venha como Part solto, embrulha num Model
		local first = container:GetChildren()[1]
		if first and first:IsA("BasePart") then
			model = Instance.new("Model")
			first.Parent = model
		end
	end
	if not model then
		warn("[MobiliarioCentral] Asset vazio ou formato inesperado:", assetId)
		container:Destroy()
		return nil
	end

	model.Parent = nil
	container:Destroy()
	model.Name = nome

	-- Ancora todas as partes; aplica colisão
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored   = true
			p.CanCollide = canCollide
		end
	end

	-- Garante PrimaryPart para PivotTo/GetBoundingBox funcionarem
	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
	end
	if not model.PrimaryPart then
		warn("[MobiliarioCentral] Asset sem BasePart:", assetId)
		model:Destroy()
		return nil
	end

	-- Calcula bounding box para apoiar no piso
	local _, size = model:GetBoundingBox()
	local centerY = pisoY + size.Y / 2 + (liftExtra or 0)
	local target  = CFrame.new(targetXZ.X, centerY, targetXZ.Y) * CFrame.Angles(0, rotY, 0)

	model:PivotTo(target)
	model.Parent = raiz

	print(string.format(
		"[MobiliarioCentral] %s carregado — size=(%.1f, %.1f, %.1f), pivot em (%.1f, %.1f, %.1f)",
		nome, size.X, size.Y, size.Z, targetXZ.X, centerY, targetXZ.Y))
	return model
end

-- ─────────────────────────────────────────────────────────────
-- INICIALIZAÇÃO
-- ─────────────────────────────────────────────────────────────
task.spawn(function()
	carregarAsset(ID_BALCAO, "Balcao", POS_BALCAO_XZ, PISO_Y, ROT_BALCAO, true,  0)
	task.wait(DELAY_ENTRE_LOADS)
	carregarAsset(ID_TAPETE, "Tapete", POS_TAPETE_XZ, PISO_Y, ROT_TAPETE, false, LIFT_TAPETE)
	print("[MobiliarioCentral] Pronto.")
end)
