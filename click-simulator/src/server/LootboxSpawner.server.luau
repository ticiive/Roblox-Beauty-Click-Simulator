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
-- Caixa construída via código — sempre funciona, sem LoadAsset
-- ─────────────────────────────────────────────────────────────

local function criarCaixaModelo(box)
	local model = Instance.new("Model")
	model.Name  = "Lootbox_" .. box.id

	local scale = box.scale or 1

	-- Base da caixa
	local base        = Instance.new("Part")
	base.Name         = "Base"
	base.Size         = Vector3.new(5, 4, 5) * scale
	base.Material     = Enum.Material.SmoothPlastic
	base.Color        = box.color
	base.Anchored     = true
	base.CanCollide   = true
	base.CFrame       = CFrame.new(0, 0, 0)
	base.Parent       = model

	-- Tampa
	local lid         = Instance.new("Part")
	lid.Name          = "Lid"
	lid.Size          = Vector3.new(5.2, 1, 5.2) * scale
	lid.Material      = Enum.Material.SmoothPlastic
	lid.Color         = box.color
	lid.Anchored      = true
	lid.CanCollide    = false
	lid.CFrame        = CFrame.new(0, base.Size.Y / 2 + lid.Size.Y / 2, 0)
	lid.Parent        = model

	-- Fita decorativa
	local fita        = Instance.new("Part")
	fita.Name         = "Fita"
	fita.Size         = Vector3.new(0.5, 5.2, 5.2) * scale
	fita.Material     = Enum.Material.Neon
	fita.Color        = Color3.fromRGB(255, 255, 255)
	fita.Anchored     = true
	fita.CanCollide   = false
	fita.CFrame       = CFrame.new(0, base.Size.Y / 4, 0)
	fita.Parent       = model

	-- Luz colorida
	local light       = Instance.new("PointLight")
	light.Color       = box.glowColor or box.color
	light.Brightness  = 2
	light.Range       = 12
	light.Shadows     = true
	light.Parent      = base

	-- Partículas
	local att         = Instance.new("Attachment")
	att.Parent        = base

	local particles               = Instance.new("ParticleEmitter")
	particles.Color               = ColorSequence.new(box.glowColor or box.color)
	particles.LightEmission       = 0.8
	particles.LightInfluence      = 0
	particles.Rate                = 8
	particles.Lifetime            = NumberRange.new(1, 2)
	particles.Speed               = NumberRange.new(1, 3)
	particles.Size                = NumberSequence.new(0.3)
	particles.Transparency        = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.SpreadAngle         = Vector2.new(25, 25)
	particles.Parent              = att

	model.PrimaryPart = base
	model:SetAttribute("LidPart", "Lid")
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

	warn("[LootboxSpawner] Parede não encontrada — usando SpawnOrigin padrão")
	return nil
end

-- ─────────────────────────────────────────────────────────────
-- Posições ao longo da parede esquerda
-- ─────────────────────────────────────────────────────────────

local wall    = findLeftWall()
local N       = #LootboxConfig.Boxes
local lookDir = Vector3.new(1, 0, 0)

-- ─────────────────────────────────────────────────────────────
-- Spawna cada caixa
-- ─────────────────────────────────────────────────────────────

for i, box in ipairs(LootboxConfig.Boxes) do
	local pos

	if wall then
		local innerX  = wall.Position.X + wall.Size.X / 2 + 8
		local groundY = wall.Position.Y - wall.Size.Y / 2
		local zPos    = wall.Position.Z + (i - (N + 1) / 2) * 12
		pos = Vector3.new(innerX, groundY + 5, zPos)
	else
		pos = LootboxConfig.SpawnOrigin + box.spawnOffset
	end

	local model = criarCaixaModelo(box)
	model:PivotTo(CFrame.lookAt(pos, pos + lookDir))
	model.Parent = lootboxFolder

	-- Placa de ativação à frente da caixa
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

	-- Billboard flutuante
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

print(string.format("[LootboxSpawner] %d caixas spawnadas.", #LootboxConfig.Boxes))
