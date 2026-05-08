-- ═══════════════════════════════════════════════════════════════
-- BalcaoFundo.server.luau — Script em ServerScriptService
-- AJUSTE: carrega o asset 71607790019809 (balcão) via InsertService
-- e posiciona encostado na parede de trás da loja, com a face
-- apontando para o interior. Usa pcall para tratar falhas de load.
-- ═══════════════════════════════════════════════════════════════

local InsertService = game:GetService("InsertService")
local Workspace     = game:GetService("Workspace")

-- AJUSTE: ID do asset solicitado
local ID_BALCAO = 71607790019809

-- AJUSTE: dimensões da loja (Environment_Pobre.server.luau usa W=45, D=50,
-- centro 0,0,0, piso em Y=0). A parede de trás fica em Z = -D = -50.
local PAREDE_Z_FUNDO = -50
local PISO_Y         = 0
local POS_X          = 0   -- centro horizontal da parede de trás

-- AJUSTE: rotação Y do balcão. 0 = face do modelo aponta para +Z (interior
-- da loja). Se o asset vier modelado virado para -Z, troque para math.pi.
local ROT_Y = 0

-- ─────────────────────────────────────────────────────────────
-- PASTA ISOLADA
-- ─────────────────────────────────────────────────────────────
local raiz = Workspace:FindFirstChild("BalcaoFundo") or Instance.new("Folder")
raiz.Name   = "BalcaoFundo"
raiz.Parent = Workspace

-- ─────────────────────────────────────────────────────────────
-- AJUSTE: pcall trata erros de carregamento (asset privado, asset
-- inexistente, falha de rede do InsertService, etc.)
-- ─────────────────────────────────────────────────────────────
local ok, container = pcall(function()
	return InsertService:LoadAsset(ID_BALCAO)
end)

if not ok or not container then
	warn(string.format(
		"[BalcaoFundo] Falha ao carregar asset %d: %s. " ..
		"Verifique se é um modelo público ou pertence ao dono do experience.",
		ID_BALCAO, tostring(container)))
	return
end

-- ─────────────────────────────────────────────────────────────
-- Extrai o modelo do container retornado pelo InsertService
-- ─────────────────────────────────────────────────────────────
local model = container:FindFirstChildOfClass("Model")
if not model then
	-- Caso o asset venha como Part solto, embrulha em um Model
	local first = container:GetChildren()[1]
	if first and first:IsA("BasePart") then
		model = Instance.new("Model")
		first.Parent = model
	end
end

if not model then
	warn("[BalcaoFundo] Asset vazio ou em formato inesperado:", ID_BALCAO)
	container:Destroy()
	return
end

model.Parent = nil
container:Destroy()
model.Name = "Balcao"

-- ─────────────────────────────────────────────────────────────
-- Ancora todas as partes (não cai pela gravidade nem move por física)
-- ─────────────────────────────────────────────────────────────
for _, p in model:GetDescendants() do
	if p:IsA("BasePart") then
		p.Anchored   = true
		p.CanCollide = true
	end
end

-- Garante que existe um PrimaryPart para PivotTo/GetBoundingBox funcionar
if not model.PrimaryPart then
	model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
end

if not model.PrimaryPart then
	warn("[BalcaoFundo] Asset não contém nenhum BasePart:", ID_BALCAO)
	model:Destroy()
	return
end

-- ─────────────────────────────────────────────────────────────
-- AJUSTE: posicionamento em duas etapas
-- 1) Aplica a rotação no pivot atual para que GetBoundingBox retorne
--    o tamanho do modelo NO MUNDO (já considerando a orientação).
-- 2) Translada o modelo para que:
--      • a base toque o piso (Y=0)
--      • a face traseira encoste na parede do fundo (Z=-50)
--      • a face frontal aponte para o interior da loja (+Z)
-- ─────────────────────────────────────────────────────────────
model:PivotTo(model:GetPivot() * CFrame.Angles(0, ROT_Y, 0))

local _, size = model:GetBoundingBox()
local centerY = PISO_Y + size.Y / 2
local centerZ = PAREDE_Z_FUNDO + size.Z / 2  -- AJUSTE: encosta o fundo do bbox na parede

local atual    = model:GetPivot()
local destino  = CFrame.new(POS_X, centerY, centerZ) * (atual - atual.Position)
model:PivotTo(destino)

model.Parent = raiz

print(string.format(
	"[BalcaoFundo] Balcão %d posicionado — size=(%.1f, %.1f, %.1f), centro=(%.1f, %.1f, %.1f)",
	ID_BALCAO, size.X, size.Y, size.Z, POS_X, centerY, centerZ))
