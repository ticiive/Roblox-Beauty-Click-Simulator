local InsertService     = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local Shared        = ReplicatedStorage:WaitForChild("Shared")
local LootboxConfig = require(Shared:WaitForChild("LootboxConfig"))

-- LootboxService cria o Remotes e o evento; espera aqui pra garantir ordem
local Remotes                    = ReplicatedStorage:WaitForChild("Remotes")
local RequestPurchaseConfirmEvent = Remotes:WaitForChild("RequestPurchaseConfirmEvent")

-- ─────────────────────────────────────────────────────────────
-- Pasta isolada — não toca em nada fora dela
-- ─────────────────────────────────────────────────────────────

local lootboxFolder = Instance.new("Folder")
lootboxFolder.Name   = "Lootboxes"
lootboxFolder.Parent = Workspace

-- ─────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────

local function colorizeModel(root, color)
	local targets = root:IsA("BasePart") and { root } or root:GetDescendants()
	for _, p in targets do
		if p:IsA("BasePart") then
			p.Color    = color
			p.Material = Enum.Material.Neon
		end
	end
end

local function anchorModel(root)
	local targets = root:IsA("BasePart") and { root } or root:GetDescendants()
	for _, p in targets do
		if p:IsA("BasePart") then
			p.Anchored   = true
			p.CanCollide = true
		end
	end
end

-- ─────────────────────────────────────────────────────────────
-- Caixa fallback (Part simples, caso o mesh não carregue)
-- ─────────────────────────────────────────────────────────────

local function criarFallback(box)
	local model = Instance.new("Model")
	model.Name = box.id

	local part = Instance.new("Part")
	part.Name       = "Body"
	part.Size       = Vector3.new(5, 5, 5) * box.scale
	part.Color      = box.color
	part.Material   = Enum.Material.Neon
	part.Anchored   = true
	part.CanCollide = true
	part.Parent     = model

	model.PrimaryPart = part
	return model
end

-- ─────────────────────────────────────────────────────────────
-- Carrega mesh template uma vez
-- ─────────────────────────────────────────────────────────────

local meshTemplate = nil

local ok, loaded = pcall(function()
	return InsertService:LoadAsset(LootboxConfig.MeshAssetId)
end)

if ok and loaded then
	local child = loaded:GetChildren()[1]
	if child then
		child.Parent = nil  -- tira do container antes de destruí-lo
		meshTemplate = child
		print("[LootboxSpawner] Mesh carregado:", meshTemplate.Name, "|", meshTemplate.ClassName)
	else
		warn("[LootboxSpawner] Asset vazio — usando fallback")
	end
	loaded:Destroy()
else
	warn("[LootboxSpawner] Falha ao carregar mesh:", tostring(loaded), "— usando fallback")
end

-- ─────────────────────────────────────────────────────────────
-- Spawna cada caixa
-- ─────────────────────────────────────────────────────────────

for _, box in LootboxConfig.Boxes do
	local model

	if meshTemplate then
		local clone = meshTemplate:Clone()
		clone.Name = box.id

		-- Escala
		if clone:IsA("Model") then
			clone:ScaleTo(box.scale)
		elseif clone:IsA("BasePart") then
			clone.Size = clone.Size * box.scale
		end

		colorizeModel(clone, box.color)
		anchorModel(clone)

		-- Garante que é um Model para facilitar o PivotTo
		if clone:IsA("BasePart") then
			local wrapper = Instance.new("Model")
			wrapper.Name = box.id
			clone.Parent = wrapper
			wrapper.PrimaryPart = clone
			model = wrapper
		else
			model = clone
		end
	else
		model = criarFallback(box)
	end

	-- Posição
	local pos = LootboxConfig.SpawnOrigin + box.spawnOffset
	model:PivotTo(CFrame.new(pos))
	model.Parent = lootboxFolder

	-- Parte central para efeitos
	local centerPart = model.PrimaryPart
		or model:FindFirstChildWhichIsA("BasePart", true)

	if centerPart then
		-- Luz pontual
		local light = Instance.new("PointLight")
		light.Color      = box.glowColor
		light.Brightness = 2
		light.Range      = 12
		light.Shadows    = true
		light.Parent     = centerPart

		-- Partículas sutis subindo
		local particles = Instance.new("ParticleEmitter")
		particles.Color          = ColorSequence.new(box.glowColor)
		particles.LightEmission  = 0.8
		particles.LightInfluence = 0
		particles.Rate           = 8
		particles.Lifetime       = NumberRange.new(1.5, 2.5)
		particles.Speed          = NumberRange.new(1.5, 2.5)
		particles.Size           = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 0),
		})
		particles.Transparency   = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		particles.SpreadAngle    = Vector2.new(25, 25)
		particles.Parent         = centerPart
	end

	-- Placa de ativação à frente da caixa
	local padPos = pos + LootboxConfig.PadOffset
	local pad = Instance.new("Part")
	pad.Name         = "Pad"
	pad.Size         = LootboxConfig.PadSize
	pad.CFrame       = CFrame.new(padPos)
	pad.Material     = Enum.Material.Neon
	pad.Color        = box.color
	pad.Transparency = 0.3
	pad.Anchored     = true
	pad.CanCollide   = false
	pad.CastShadow   = false
	pad.Parent       = model

	-- Billboard flutuante acima da placa
	local bb = Instance.new("BillboardGui")
	bb.Size        = UDim2.fromOffset(210, 58)
	bb.StudsOffset = Vector3.new(0, 3.5, 0)
	bb.AlwaysOnTop = false
	bb.Parent      = pad

	local bg = Instance.new("Frame")
	bg.Size                   = UDim2.fromScale(1, 1)
	bg.BackgroundColor3       = Color3.fromRGB(18, 12, 28)
	bg.BackgroundTransparency = 0.15
	bg.BorderSizePixel        = 0
	bg.Parent                 = bb

	local bbCorner = Instance.new("UICorner")
	bbCorner.CornerRadius = UDim.new(0, 8)
	bbCorner.Parent       = bg

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Text              = box.emoji .. " " .. box.name
	titleLbl.TextSize          = 15
	titleLbl.Font              = Enum.Font.GothamBold
	titleLbl.TextColor3        = Color3.new(1, 1, 1)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Size              = UDim2.new(1, 0, 0.55, 0)
	titleLbl.TextXAlignment    = Enum.TextXAlignment.Center
	titleLbl.Parent            = bg

	local priceLbl = Instance.new("TextLabel")
	priceLbl.Text              = "💰 " .. tostring(box.cost) .. "  •  [E] Comprar"
	priceLbl.TextSize          = 11
	priceLbl.Font              = Enum.Font.Gotham
	priceLbl.TextColor3        = Color3.fromRGB(212, 175, 55)
	priceLbl.BackgroundTransparency = 1
	priceLbl.Size              = UDim2.new(1, 0, 0.45, 0)
	priceLbl.Position          = UDim2.new(0, 0, 0.55, 0)
	priceLbl.TextXAlignment    = Enum.TextXAlignment.Center
	priceLbl.Parent            = bg

	-- ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText            = "Comprar"
	prompt.ObjectText            = box.name .. "  💰 " .. tostring(box.cost)
	prompt.HoldDuration          = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight   = false
	prompt.Parent                = pad

	prompt.Triggered:Connect(function(player)
		RequestPurchaseConfirmEvent:FireClient(player, box.id)
	end)

	print(string.format("[LootboxSpawner] '%s' em %s", box.id, tostring(pos)))
end

-- Limpa template da memória
if meshTemplate then meshTemplate:Destroy() end

print(string.format("[LootboxSpawner] %d caixas spawnadas.", #LootboxConfig.Boxes))
