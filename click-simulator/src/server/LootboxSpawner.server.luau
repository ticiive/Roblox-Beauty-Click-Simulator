local InsertService     = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local Shared        = ReplicatedStorage:WaitForChild("Shared")
local LootboxConfig = require(Shared:WaitForChild("LootboxConfig"))

local Remotes                    = ReplicatedStorage:WaitForChild("Remotes")
local RequestPurchaseConfirmEvent = Remotes:WaitForChild("RequestPurchaseConfirmEvent")

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
			p.Transparency = 0
			local _, s, _ = p.Color:ToHSV()
			if s < 0.15 then
				p.Color = color
			end
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
-- Caixa fallback
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
-- Detecta parede esquerda (menor X) com 5 tentativas
-- ─────────────────────────────────────────────────────────────

local function findLeftWall()
	for attempt = 1, 5 do
		local bestPart = nil
		local bestX = math.huge

		for _, obj in Workspace:GetDescendants() do
			if obj:IsA("BasePart") and obj.Anchored then
				local sz = obj.Size
				if sz.Y > 8 and (sz.Z > 20 or sz.X > 20) then
					if obj.Position.X < bestX then
						bestX = obj.Position.X
						bestPart = obj
					end
				end
			end
		end

		if bestPart then
			print(string.format("[LootboxSpawner] Parede esq: %s  pos=%s  size=%s  (tentativa %d)",
				bestPart.Name, tostring(bestPart.Position), tostring(bestPart.Size), attempt))
			return bestPart
		end

		if attempt < 5 then
			warn(string.format("[LootboxSpawner] Tentativa %d: parede não encontrada, aguardando 1s...", attempt))
			task.wait(1)
		end
	end

	warn("[LootboxSpawner] Parede não encontrada após 5 tentativas — usando SpawnOrigin padrão")
	return nil
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
		print("[LootboxSpawner] Mesh carregado:", child.Name, "|", child.ClassName)
		print("[LootboxSpawner] Descendentes do mesh:")
		for _, desc in child:GetDescendants() do
			if desc:IsA("BasePart") then
				local sm = desc:FindFirstChildOfClass("SpecialMesh")
				local meshId = sm and (" MeshId=" .. sm.MeshId) or ""
				print(string.format("  [%s] %s | Size=%s | Transp=%.2f%s",
					desc.ClassName, desc.Name, tostring(desc.Size), desc.Transparency, meshId))
			end
		end
		child.Parent = nil
		meshTemplate = child
	else
		warn("[LootboxSpawner] Asset vazio — usando fallback")
	end
	loaded:Destroy()
else
	warn("[LootboxSpawner] Falha ao carregar mesh:", tostring(loaded), "— usando fallback")
end

-- ─────────────────────────────────────────────────────────────
-- Calcula posições ao longo da parede esquerda
-- ─────────────────────────────────────────────────────────────

local wall = findLeftWall()
local N    = #LootboxConfig.Boxes

-- Direção que as caixas devem olhar (para dentro do mapa, afastando da parede esq.)
local lookDir = Vector3.new(1, 0, 0)

-- ─────────────────────────────────────────────────────────────
-- Spawna cada caixa
-- ─────────────────────────────────────────────────────────────

for i, box in ipairs(LootboxConfig.Boxes) do
	local pos

	if wall then
		local innerX = wall.Position.X + wall.Size.X / 2 + 8
		local groundY = wall.Position.Y - wall.Size.Y / 2
		local zPos = wall.Position.Z + (i - (N + 1) / 2) * 12
		pos = Vector3.new(innerX, groundY + 5, zPos)
	else
		pos = LootboxConfig.SpawnOrigin + box.spawnOffset
	end

	local model

	if meshTemplate then
		local clone = meshTemplate:Clone()
		clone.Name = box.id

		local scaleOk = pcall(function()
			if clone:IsA("Model") then
				clone:ScaleTo(box.scale)
			elseif clone:IsA("BasePart") then
				clone.Size = clone.Size * box.scale
			end
		end)
		if not scaleOk then
			warn("[LootboxSpawner] ScaleTo falhou para", box.id)
		end

		colorizeModel(clone, box.color)
		anchorModel(clone)

		if clone:IsA("BasePart") then
			local wrapper = Instance.new("Model")
			wrapper.Name = box.id
			clone.Parent = wrapper
			wrapper.PrimaryPart = clone
			model = wrapper
		else
			model = clone
			if not model.PrimaryPart then
				model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
			end
		end
	else
		model = criarFallback(box)
	end

	model:PivotTo(CFrame.lookAt(pos, pos + lookDir))
	model.Parent = lootboxFolder

	local centerPart = model.PrimaryPart
		or model:FindFirstChildWhichIsA("BasePart", true)

	if centerPart then
		local light = Instance.new("PointLight")
		light.Color      = box.glowColor
		light.Brightness = 2
		light.Range      = 12
		light.Shadows    = true
		light.Parent     = centerPart

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

	-- Placa de ativação à frente da caixa (na direção lookDir)
	local padPos = pos
		+ lookDir        * LootboxConfig.PadOffset.Z
		+ Vector3.new(0, LootboxConfig.PadOffset.Y, 0)

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

if meshTemplate then meshTemplate:Destroy() end

print(string.format("[LootboxSpawner] %d caixas spawnadas.", #LootboxConfig.Boxes))
