-- FASE 1: Estética Loja Pobrinha
-- Para ajustar: mude as cores e materiais nas seções acima
-- Este script roda toda vez que o servidor inicia

local Lighting  = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- ─────────────────────────────────────────────────────────────
-- Aguarda modelo carregar (até 10s)
-- ─────────────────────────────────────────────────────────────

local loja = nil
for _ = 1, 10 do
	loja = Workspace:FindFirstChild("Loja-Roupa")
	if loja then break end
	task.wait(1)
end

if not loja then
	warn("[LojaEstetica] Modelo 'Loja-Roupa' não encontrado — abortando")
	return
end

local pivot = loja:GetPivot()
print("[LojaEstetica] Modelo encontrado em:", pivot.Position)
print("[LojaEstetica] Total de descendants:", #loja:GetDescendants())

local count = 0
for _, part in ipairs(loja:GetDescendants()) do
	if part:IsA("BasePart") and count < 5 then
		count += 1
		print(string.format("  Part %d: %s | Size: %.1f x %.1f x %.1f | Pos Y: %.1f",
			count, part.ClassName,
			part.Size.X, part.Size.Y, part.Size.Z,
			part.Position.Y))
	end
end

-- ─────────────────────────────────────────────────────────────
-- Classificação e aplicação de estética
-- ─────────────────────────────────────────────────────────────

local nChao, nTeto, nParede, nEstrutura, nPequeno, total = 0, 0, 0, 0, 0, 0

local partsPorTipo = {
	chao      = {},
	teto      = {},
	parede    = {},
	estrutura = {},
}

for _, part in loja:GetDescendants() do
	if not (part:IsA("BasePart") or part:IsA("UnionOperation") or part:IsA("MeshPart")) then
		continue
	end

	total += 1
	local size = part.Size
	local maior = math.max(size.X, size.Y, size.Z)
	local pos  = part.Position
	local tipo = "objeto_pequeno"

	-- Teto tem prioridade sobre chão quando Y for alto
	if size.Y < 2 and size.X > 10 and size.Z > 10 and pos.Y > 10 then
		tipo = "teto"
	elseif size.Y < 2 and size.X > 10 and size.Z > 10 then
		tipo = "chao"
	elseif (size.X < 2 and size.Y > 5 and size.Z > 5)
		or (size.Z < 2 and size.Y > 5 and size.X > 5) then
		tipo = "parede"
	elseif maior < 5 then
		tipo = "objeto_pequeno"
	else
		tipo = "estrutura"
	end

	if tipo ~= "objeto_pequeno" then
		table.insert(partsPorTipo[tipo], part)
	end

	if     tipo == "chao"      then nChao     += 1
	elseif tipo == "teto"      then nTeto     += 1
	elseif tipo == "parede"    then nParede   += 1
	elseif tipo == "estrutura" then nEstrutura += 1
	else                            nPequeno  += 1
	end
end

-- Aplica materiais e cores
local function aplicar(parts, material, color)
	for _, part in parts do
		pcall(function()
			part.Material    = material
			part.Color       = color
			part.Reflectance = 0
		end)
	end
end

aplicar(partsPorTipo.chao,
	Enum.Material.WoodPlanks,
	Color3.fromRGB(89, 60, 35))

aplicar(partsPorTipo.teto,
	Enum.Material.Wood,
	Color3.fromRGB(75, 50, 28))

aplicar(partsPorTipo.parede,
	Enum.Material.SmoothPlastic,
	Color3.fromRGB(180, 160, 130))

aplicar(partsPorTipo.estrutura,
	Enum.Material.Wood,
	Color3.fromRGB(101, 68, 40))

-- ─────────────────────────────────────────────────────────────
-- Iluminação suja
-- ─────────────────────────────────────────────────────────────

pcall(function()
	Lighting.Ambient          = Color3.fromRGB(80, 65, 45)
	Lighting.OutdoorAmbient   = Color3.fromRGB(60, 50, 35)
	Lighting.Brightness       = 0.8
	Lighting.ColorShift_Top   = Color3.fromRGB(255, 200, 120)
end)

-- ─────────────────────────────────────────────────────────────
-- 3 luzes fracas dentro da loja
-- ─────────────────────────────────────────────────────────────

-- Coleta BaseParts da loja pra usar como âncora
local partsList = {}
for _, p in loja:GetDescendants() do
	if p:IsA("BasePart") then
		table.insert(partsList, p)
	end
end

-- Distribui 3 luzes em partes com índices espaçados
local count = #partsList
if count > 0 then
	local indices = {
		math.max(1, math.floor(count * 0.2)),
		math.max(1, math.floor(count * 0.5)),
		math.max(1, math.floor(count * 0.8)),
	}
	for _, idx in ipairs(indices) do
		pcall(function()
			local anchor = partsList[idx]
			local light  = Instance.new("PointLight")
			light.Brightness = 1.5
			light.Color      = Color3.fromRGB(255, 180, 80)
			light.Range      = 20
			light.Shadows    = false
			light.Parent     = anchor
		end)
	end
else
	-- Fallback: attachment no pivô da loja
	pcall(function()
		local attach = Instance.new("Attachment")
		attach.WorldPosition = loja:GetPivot().Position
		attach.Parent        = loja

		local light  = Instance.new("PointLight")
		light.Brightness = 1.5
		light.Color      = Color3.fromRGB(255, 180, 80)
		light.Range      = 20
		light.Parent     = attach
	end)
end

-- ─────────────────────────────────────────────────────────────
-- Poeira flutuando
-- ─────────────────────────────────────────────────────────────

pcall(function()
	local pivot  = loja:GetPivot()
	local attach = Instance.new("Attachment")
	attach.WorldPosition = pivot.Position + Vector3.new(0, 3, 0)
	attach.Parent        = loja

	local poeira = Instance.new("ParticleEmitter")
	poeira.Color = ColorSequence.new(Color3.fromRGB(204, 204, 178))
	poeira.LightEmission  = 0
	poeira.LightInfluence = 1
	poeira.Rate           = 5
	poeira.Lifetime       = NumberRange.new(4, 8)
	poeira.Speed          = NumberRange.new(0.2, 0.5)
	poeira.Size           = NumberSequence.new({
		NumberSequenceKeypoint.new(0,   0.05),
		NumberSequenceKeypoint.new(0.5, 0.15),
		NumberSequenceKeypoint.new(1,   0.05),
	})
	poeira.Transparency   = NumberSequence.new({
		NumberSequenceKeypoint.new(0,   0.7),
		NumberSequenceKeypoint.new(0.85, 0.9),
		NumberSequenceKeypoint.new(1,   1.0),
	})
	poeira.SpreadAngle    = Vector2.new(180, 180)
	poeira.RotSpeed       = NumberRange.new(-10, 10)
	poeira.Parent         = attach
end)

-- ─────────────────────────────────────────────────────────────
-- Diagnóstico
-- ─────────────────────────────────────────────────────────────

print(string.format(
	"[LojaEstetica] Chão: %d | Teto: %d | Parede: %d | Estrutura: %d | Pequenos: %d | Total: %d",
	nChao, nTeto, nParede, nEstrutura, nPequeno, total
))
