local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")

local Shared        = ReplicatedStorage:WaitForChild("Shared")
local LootboxConfig = require(Shared:WaitForChild("LootboxConfig"))
local Catalog       = require(Shared:WaitForChild("Catalog"))

local Remotes                     = ReplicatedStorage:WaitForChild("Remotes")
local RequestPurchaseConfirmEvent = Remotes:WaitForChild("RequestPurchaseConfirmEvent")

-- ─────────────────────────────────────────────────────────────
-- Pasta raiz
-- ─────────────────────────────────────────────────────────────

local lojaFolder = Instance.new("Folder")
lojaFolder.Name   = "Loja"
lojaFolder.Parent = Workspace

local partCount = 0

-- ─────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────

local function novaPart(parent, name, pos, size, color, material, canCollide)
	local p             = Instance.new("Part")
	p.Name              = name
	p.CFrame            = CFrame.new(pos)
	p.Size              = size
	p.Color             = color
	p.Material          = material or Enum.Material.SmoothPlastic
	p.Anchored          = true
	p.CanCollide        = canCollide ~= false
	p.CastShadow        = true
	p.TopSurface        = Enum.SurfaceType.Smooth
	p.BottomSurface     = Enum.SurfaceType.Smooth
	p.Parent            = parent
	partCount          += 1
	return p
end

local function novaWedge(parent, name, cf, size, color, material)
	local p             = Instance.new("WedgePart")
	p.Name              = name
	p.CFrame            = cf
	p.Size              = size
	p.Color             = color
	p.Material          = material or Enum.Material.SmoothPlastic
	p.Anchored          = true
	p.CanCollide        = true
	p.TopSurface        = Enum.SurfaceType.Smooth
	p.BottomSurface     = Enum.SurfaceType.Smooth
	p.Parent            = parent
	partCount          += 1
	return p
end

local function addBillboard(part, text, size, offset, fontSize)
	local bb            = Instance.new("BillboardGui")
	bb.Size             = size or UDim2.fromOffset(220, 60)
	bb.StudsOffset      = offset or Vector3.new(0, 3, 0)
	bb.AlwaysOnTop      = false
	bb.Parent           = part

	local lbl           = Instance.new("TextLabel")
	lbl.Size            = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text            = text
	lbl.TextSize        = fontSize or 16
	lbl.Font            = Enum.Font.GothamBold
	lbl.TextColor3      = Color3.new(1, 1, 1)
	lbl.TextStrokeTransparency = 0.4
	lbl.TextXAlignment  = Enum.TextXAlignment.Center
	lbl.Parent          = bb
	return bb
end

local function addThumbGui(part, assetId, bbSize, offset)
	local bb            = Instance.new("BillboardGui")
	bb.Size             = bbSize or UDim2.fromOffset(80, 80)
	bb.StudsOffset      = offset or Vector3.new(0, 0, 0)
	bb.AlwaysOnTop      = false
	bb.Parent           = part

	local img           = Instance.new("ImageLabel")
	img.Size            = UDim2.fromScale(1, 1)
	img.BackgroundTransparency = 1
	img.Image           = "rbxthumb://type=Asset&id=" .. tostring(assetId) .. "&w=150&h=150"
	img.Parent          = bb
	return bb
end

-- ─────────────────────────────────────────────────────────────
-- Paleta
-- ─────────────────────────────────────────────────────────────

local COR_PAREDE   = Color3.fromRGB(230, 215, 190)
local COR_CHAO     = Color3.fromRGB(120, 80, 45)
local COR_TETO     = Color3.fromRGB(210, 195, 170)
local COR_COLUNA   = Color3.fromRGB(160, 130, 90)
local COR_BALCAO   = Color3.fromRGB(100, 65, 35)
local COR_ARARA    = Color3.fromRGB(60, 60, 65)
local COR_VIDRO    = Color3.fromRGB(180, 220, 240)
local COR_OURO     = Color3.fromRGB(215, 178, 55)
local COR_TAPETE   = Color3.fromRGB(140, 40, 40)
local COR_PLANTA   = Color3.fromRGB(50, 130, 60)
local COR_VASO     = Color3.fromRGB(160, 100, 60)

local MAT_MADEIRA  = Enum.Material.WoodPlanks
local MAT_PLASTICO = Enum.Material.SmoothPlastic
local MAT_METAL    = Enum.Material.Metal
local MAT_VIDRO    = Enum.Material.Glass
local MAT_NEON     = Enum.Material.Neon

-- Dimensões
local W, D, H = 60, 80, 14  -- largura, profundidade, altura
local HW, HD  = W/2, D/2    -- metades

-- ─────────────────────────────────────────────────────────────
-- 1. Estrutura
-- ─────────────────────────────────────────────────────────────

local function buildEstrutura()
	local folder = Instance.new("Folder")
	folder.Name  = "Estrutura"
	folder.Parent = lojaFolder

	-- Chão
	novaPart(folder, "Chao",
		Vector3.new(0, -0.5, 0),
		Vector3.new(W, 1, D),
		COR_CHAO, MAT_MADEIRA)

	-- Teto
	novaPart(folder, "Teto",
		Vector3.new(0, H + 0.5, 0),
		Vector3.new(W, 1, D),
		COR_TETO, Enum.Material.Wood)

	-- Parede fundo (Z=+HD)
	novaPart(folder, "ParedeFundo",
		Vector3.new(0, H/2, HD + 0.5),
		Vector3.new(W, H, 1),
		COR_PAREDE, MAT_PLASTICO)

	-- Parede esquerda (X=-HW)
	novaPart(folder, "ParedeEsq",
		Vector3.new(-HW - 0.5, H/2, 0),
		Vector3.new(1, H, D),
		COR_PAREDE, MAT_PLASTICO)

	-- Parede direita (X=+HW)
	novaPart(folder, "ParedeDir",
		Vector3.new(HW + 0.5, H/2, 0),
		Vector3.new(1, H, D),
		COR_PAREDE, MAT_PLASTICO)

	-- Parede frente — parte esquerda (vão central de 20 studs)
	novaPart(folder, "ParedeFrenteEsq",
		Vector3.new(-HW/2 - 5, H/2, -HD - 0.5),
		Vector3.new(HW - 10, H, 1),
		COR_PAREDE, MAT_PLASTICO)

	-- Parede frente — parte direita
	novaPart(folder, "ParedeFrenteDir",
		Vector3.new(HW/2 + 5, H/2, -HD - 0.5),
		Vector3.new(HW - 10, H, 1),
		COR_PAREDE, MAT_PLASTICO)

	-- Verga sobre a entrada
	novaPart(folder, "Verga",
		Vector3.new(0, H - 1, -HD - 0.5),
		Vector3.new(20, 2, 1),
		COR_COLUNA, Enum.Material.Wood)

	-- 4 colunas internas nos cantos
	for _, sx in ipairs({-1, 1}) do
		for _, sz in ipairs({-1, 1}) do
			novaPart(folder, "Coluna",
				Vector3.new(sx * (HW - 4), H/2, sz * (HD - 4)),
				Vector3.new(2, H, 2),
				COR_COLUNA, Enum.Material.Wood)
		end
	end

	-- Vitrine de vidro — frente (flancos da entrada)
	novaPart(folder, "VitrineEsq",
		Vector3.new(-HW/2 - 5, 5, -HD - 0.5),
		Vector3.new(HW - 10, 8, 0.3),
		COR_VIDRO, MAT_VIDRO)
	novaPart(folder, "VitrineDir",
		Vector3.new(HW/2 + 5, 5, -HD - 0.5),
		Vector3.new(HW - 10, 8, 0.3),
		COR_VIDRO, MAT_VIDRO)

	-- Tapete de entrada
	novaPart(folder, "Tapete",
		Vector3.new(0, 0.05, -HD + 4),
		Vector3.new(16, 0.1, 6),
		COR_TAPETE, Enum.Material.Fabric)

	-- Placa da loja
	local placa = novaPart(folder, "Placa",
		Vector3.new(0, H + 3, -HD - 0.5),
		Vector3.new(20, 3, 0.5),
		COR_OURO, MAT_PLASTICO)
	addBillboard(placa, "✨ Beauty Shop ✨", UDim2.fromOffset(260, 60), Vector3.new(0, 0, 0), 20)

	print("[LojaBuilder] Estrutura concluída (chão/paredes/teto/colunas)")
end

-- ─────────────────────────────────────────────────────────────
-- 2. Lootboxes
-- ─────────────────────────────────────────────────────────────

local function buildLootboxes()
	local lootboxFolder = Instance.new("Folder")
	lootboxFolder.Name   = "Lootboxes"
	lootboxFolder.Parent = Workspace

	local boxes = LootboxConfig.Boxes
	local N     = #boxes
	local baseZ = HD - 8
	local lookDir = Vector3.new(0, 0, -1)

	for i, box in ipairs(boxes) do
		local xPos = (i - (N + 1) / 2) * 10
		local pos  = Vector3.new(xPos, 0, baseZ)

		local scale = box.scale or 1

		local model = Instance.new("Model")
		model.Name  = "Lootbox_" .. box.id

		local base        = Instance.new("Part")
		base.Name         = "Base"
		base.Size         = Vector3.new(5, 4, 5) * scale
		base.Material     = MAT_PLASTICO
		base.Color        = box.color
		base.Anchored     = true
		base.CanCollide   = true
		base.CFrame       = CFrame.new(pos + Vector3.new(0, base.Size.Y/2, 0))
		base.Parent       = model

		local lid         = Instance.new("Part")
		lid.Name          = "Lid"
		lid.Size          = Vector3.new(5.2, 1, 5.2) * scale
		lid.Material      = MAT_PLASTICO
		lid.Color         = box.color
		lid.Anchored      = true
		lid.CanCollide    = false
		lid.CFrame        = CFrame.new(pos + Vector3.new(0, base.Size.Y + lid.Size.Y/2, 0))
		lid.Parent        = model

		local fita        = Instance.new("Part")
		fita.Name         = "Fita"
		fita.Size         = Vector3.new(0.5, 5.2, 5.2) * scale
		fita.Material     = MAT_NEON
		fita.Color        = Color3.new(1, 1, 1)
		fita.Anchored     = true
		fita.CanCollide   = false
		fita.CFrame       = CFrame.new(pos + Vector3.new(0, base.Size.Y/4 + 1, 0))
		fita.Parent       = model

		local light       = Instance.new("PointLight")
		light.Color       = box.glowColor or box.color
		light.Brightness  = 2
		light.Range       = 12
		light.Shadows     = true
		light.Parent      = base

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
		model.Parent      = lootboxFolder
		partCount        += 3

		-- Pad de ativação
		local padOff = LootboxConfig.PadOffset
		local padPos = pos
			+ lookDir * padOff.Z
			+ Vector3.new(0, padOff.Y, 0)

		local pad = Instance.new("Part")
		pad.Name         = "Pad"
		pad.Size         = LootboxConfig.PadSize
		pad.CFrame       = CFrame.new(padPos)
		pad.Material     = MAT_NEON
		pad.Color        = box.color
		pad.Transparency = 0.3
		pad.Anchored     = true
		pad.CanCollide   = false
		pad.CastShadow   = false
		pad.Parent       = model
		partCount       += 1

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
	end

	print("[LojaBuilder] Lootboxes posicionadas: " .. N .. " caixas")
end

-- ─────────────────────────────────────────────────────────────
-- 3. Balcão
-- ─────────────────────────────────────────────────────────────

local function buildBalcao()
	local folder = Instance.new("Folder")
	folder.Name  = "Balcao"
	folder.Parent = lojaFolder

	local bx, bz = 0, HD - 6

	-- Superfície principal
	novaPart(folder, "Tampo",
		Vector3.new(bx, 3.5, bz),
		Vector3.new(16, 0.5, 5),
		COR_BALCAO, Enum.Material.Wood)

	-- Corpo
	novaPart(folder, "Corpo",
		Vector3.new(bx, 1.5, bz),
		Vector3.new(16, 3, 5),
		Color3.fromRGB(80, 50, 25), Enum.Material.Wood)

	-- Extensão lateral esquerda
	novaPart(folder, "CorpoEsq",
		Vector3.new(bx - 9, 1.5, bz + 3),
		Vector3.new(2, 3, 11),
		Color3.fromRGB(80, 50, 25), Enum.Material.Wood)
	novaPart(folder, "TampoEsq",
		Vector3.new(bx - 9, 3.5, bz + 3),
		Vector3.new(2, 0.5, 11),
		COR_BALCAO, Enum.Material.Wood)

	-- Gaveta decorativa
	novaPart(folder, "Gaveta",
		Vector3.new(bx - 2, 1.5, bz - 2.6),
		Vector3.new(3, 1.5, 0.3),
		Color3.fromRGB(140, 100, 60), Enum.Material.Wood)

	-- Puxador
	novaPart(folder, "Puxador",
		Vector3.new(bx - 2, 1.5, bz - 2.75),
		Vector3.new(1, 0.2, 0.2),
		COR_OURO, MAT_METAL)

	-- Caixa registradora (decorativa)
	novaPart(folder, "CaixaReg",
		Vector3.new(bx + 5, 4, bz),
		Vector3.new(2.5, 1.5, 2),
		Color3.fromRGB(30, 30, 30), MAT_PLASTICO)

	-- Tela da caixa
	local tela = novaPart(folder, "Tela",
		Vector3.new(bx + 5, 5, bz - 1.1),
		Vector3.new(2, 1.2, 0.1),
		Color3.fromRGB(0, 180, 100), MAT_NEON)
	addBillboard(tela, "$ Caixa", UDim2.fromOffset(80, 40), Vector3.new(0, 1, 0), 12)

	print("[LojaBuilder] Balcão montado")
end

-- ─────────────────────────────────────────────────────────────
-- 4. Araras (cabideiros)
-- ─────────────────────────────────────────────────────────────

local function buildArara(folder, ox, oz, catName)
	-- Base vertical
	local base = novaPart(folder, "AraraBase",
		Vector3.new(ox, 3, oz),
		Vector3.new(0.4, 6, 0.4),
		COR_ARARA, MAT_METAL)

	-- Barra horizontal
	novaPart(folder, "AraraBarra",
		Vector3.new(ox, 6, oz),
		Vector3.new(8, 0.4, 0.4),
		COR_ARARA, MAT_METAL)

	-- Pés
	novaPart(folder, "AraraBase2",
		Vector3.new(ox, 0.3, oz),
		Vector3.new(6, 0.4, 0.4),
		COR_ARARA, MAT_METAL)

	-- 5 cabides com thumbnails
	local item = Catalog.getRandom(catName)
	for k = 1, 5 do
		local hx = ox + (k - 3) * 1.4
		-- Gancho
		novaPart(folder, "Cabide",
			Vector3.new(hx, 6.5, oz),
			Vector3.new(0.3, 1, 0.3),
			COR_OURO, MAT_METAL)

		-- Peça de roupa (thumbnail)
		local hang = novaPart(folder, "Roupa",
			Vector3.new(hx, 4.5, oz),
			Vector3.new(1.2, 2, 0.1),
			Color3.fromRGB(200, 200, 210), MAT_PLASTICO)
		hang.CanCollide = false
		if item then
			addThumbGui(hang, item.id, UDim2.fromOffset(60, 80), Vector3.new(0, 0, -0.1))
		end
	end

	return base
end

local function buildAraras()
	local folder = Instance.new("Folder")
	folder.Name  = "Araras"
	folder.Parent = lojaFolder

	buildArara(folder, -18, -15, "Shirts")
	buildArara(folder, 18,  -15, "Pants")
	buildArara(folder, -18,  12, "Hair")
	buildArara(folder,  18,  12, "Hats")

	print("[LojaBuilder] Araras montadas: 4")
end

-- ─────────────────────────────────────────────────────────────
-- 5. Prateleiras de parede
-- ─────────────────────────────────────────────────────────────

local function buildPrateleiras()
	local folder = Instance.new("Folder")
	folder.Name  = "Prateleiras"
	folder.Parent = lojaFolder

	local cats = { "FaceAcc", "NeckAcc", "ShoulderAcc", "WaistAcc", "TShirts" }
	local catIdx = 1

	for _, sx in ipairs({-1, 1}) do
		local wx = sx * (HW + 0.3)
		for shelf = 1, 3 do
			local sy = 2 + shelf * 3
			-- Prateleira
			novaPart(folder, "Shelf",
				Vector3.new(wx - sx * 0.85, sy, 0),
				Vector3.new(0.3, 0.3, 20),
				COR_BALCAO, Enum.Material.Wood)

			-- Suporte
			for _, sz in ipairs({-8, 0, 8}) do
				novaPart(folder, "Suporte",
					Vector3.new(wx - sx * 0.6, sy - 0.8, sz),
					Vector3.new(0.2, 1.4, 0.2),
					COR_COLUNA, MAT_METAL)
			end

			-- Itens decorativos (caixinhas)
			local cat = cats[catIdx] or "Hair"
			catIdx = (catIdx % #cats) + 1
			local item = Catalog.getRandom(cat)
			for k = 1, 4 do
				local itemZ = -6 + k * 3.5
				local box = novaPart(folder, "ItemBox",
					Vector3.new(wx - sx * 0.85, sy + 0.6, itemZ),
					Vector3.new(0.8, 0.8, 0.8),
					Color3.fromRGB(200 - k*20, 180, 160 + k*10), MAT_PLASTICO)
				box.CanCollide = false
				if item then
					addThumbGui(box, item.id, UDim2.fromOffset(40, 40), Vector3.new(0, 1.2, 0))
				end
			end
		end
	end

	print("[LojaBuilder] Prateleiras montadas")
end

-- ─────────────────────────────────────────────────────────────
-- 6. Manequins
-- ─────────────────────────────────────────────────────────────

local function buildManequim(folder, ox, oz, label)
	local basePos = Vector3.new(ox, 0, oz)

	-- Pernas
	for _, dx in ipairs({-0.5, 0.5}) do
		novaPart(folder, "Perna",
			basePos + Vector3.new(dx, 1.25, 0),
			Vector3.new(0.7, 2.5, 0.7),
			Color3.fromRGB(220, 200, 185), MAT_PLASTICO)
	end

	-- Torso
	local torso = novaPart(folder, "Torso",
		basePos + Vector3.new(0, 3.8, 0),
		Vector3.new(1.8, 2.5, 0.9),
		Color3.fromRGB(220, 200, 185), MAT_PLASTICO)

	-- Braços
	for _, dx in ipairs({-1.3, 1.3}) do
		novaPart(folder, "Braco",
			basePos + Vector3.new(dx, 3.8, 0),
			Vector3.new(0.7, 2.2, 0.7),
			Color3.fromRGB(220, 200, 185), MAT_PLASTICO)
	end

	-- Pescoço
	novaPart(folder, "Pescoco",
		basePos + Vector3.new(0, 5.3, 0),
		Vector3.new(0.5, 0.7, 0.5),
		Color3.fromRGB(220, 200, 185), MAT_PLASTICO)

	-- Cabeça
	local head = novaPart(folder, "Cabeca",
		basePos + Vector3.new(0, 6.3, 0),
		Vector3.new(1.2, 1.2, 1.2),
		Color3.fromRGB(220, 200, 185), MAT_PLASTICO)

	-- Etiqueta com item
	local item = Catalog.getRandom("Hair")
	if item then
		addThumbGui(torso, item.id, UDim2.fromOffset(70, 90), Vector3.new(0, 0, -0.6))
	end
	addBillboard(head, label, UDim2.fromOffset(120, 36), Vector3.new(0, 2, 0), 12)

	return torso
end

local function buildManequins()
	local folder = Instance.new("Folder")
	folder.Name  = "Manequins"
	folder.Parent = lojaFolder

	buildManequim(folder, -10, -HD + 8, "Casual")
	buildManequim(folder,  10, -HD + 8, "Fashion")
	buildManequim(folder,   0,       0, "Premium")

	print("[LojaBuilder] Manequins montados: 3")
end

-- ─────────────────────────────────────────────────────────────
-- 7. Espelhos
-- ─────────────────────────────────────────────────────────────

local function buildEspelhos()
	local folder = Instance.new("Folder")
	folder.Name  = "Espelhos"
	folder.Parent = lojaFolder

	for _, sx in ipairs({-1, 1}) do
		local ex = sx * 14
		local ez = HD - 0.8

		-- Moldura
		novaPart(folder, "MolduraEspelho",
			Vector3.new(ex, 5.5, ez),
			Vector3.new(4.4, 8.4, 0.3),
			COR_OURO, MAT_METAL)

		-- Superfície reflexiva
		local mirror = novaPart(folder, "Espelho",
			Vector3.new(ex, 5.5, ez - 0.2),
			Vector3.new(4, 8, 0.1),
			Color3.fromRGB(200, 220, 230), MAT_VIDRO)
		mirror.Reflectance = 0.7
		mirror.CanCollide  = false
	end

	print("[LojaBuilder] Espelhos montados")
end

-- ─────────────────────────────────────────────────────────────
-- 8. Iluminação
-- ─────────────────────────────────────────────────────────────

local function buildIluminacao()
	local folder = Instance.new("Folder")
	folder.Name  = "Iluminacao"
	folder.Parent = lojaFolder

	local lightPositions = {
		Vector3.new(-15, H, -20),
		Vector3.new(  0, H, -20),
		Vector3.new( 15, H, -20),
		Vector3.new(-15, H,  15),
		Vector3.new(  0, H,  15),
		Vector3.new( 15, H,  15),
	}

	for i, lpos in ipairs(lightPositions) do
		-- Base da luminária
		local base = novaPart(folder, "Luminaria" .. i,
			lpos,
			Vector3.new(1.5, 0.5, 1.5),
			Color3.fromRGB(40, 40, 40), MAT_METAL)

		-- Haste
		novaPart(folder, "Haste" .. i,
			lpos + Vector3.new(0, 0.6, 0),
			Vector3.new(0.3, 0.7, 0.3),
			COR_ARARA, MAT_METAL)

		-- Cúpula
		local cupula = novaPart(folder, "Cupula" .. i,
			lpos - Vector3.new(0, 0.5, 0),
			Vector3.new(1.8, 0.6, 1.8),
			Color3.fromRGB(230, 210, 170), MAT_NEON)
		cupula.CanCollide = false

		local light          = Instance.new("PointLight")
		light.Color          = Color3.fromRGB(255, 200, 120)
		light.Brightness     = 2.5
		light.Range          = 22
		light.Shadows        = true
		light.Parent         = cupula
	end

	-- Luz ambiente nas lootboxes (vermelha suave de emergência)
	local emergencia = novaPart(folder, "LuzEmergencia",
		Vector3.new(0, H - 1, HD - 4),
		Vector3.new(1, 1, 1),
		Color3.fromRGB(200, 50, 50), MAT_NEON)
	emergencia.CanCollide = false
	local el          = Instance.new("PointLight")
	el.Color          = Color3.fromRGB(255, 80, 80)
	el.Brightness     = 1
	el.Range          = 20
	el.Parent         = emergencia

	-- Lighting global
	Lighting.Ambient        = Color3.fromRGB(90, 70, 50)
	Lighting.OutdoorAmbient = Color3.fromRGB(60, 50, 35)
	Lighting.Brightness     = 1.0
	Lighting.ColorShift_Top = Color3.fromRGB(255, 210, 140)

	print("[LojaBuilder] Iluminação instalada")
end

-- ─────────────────────────────────────────────────────────────
-- 9. Detalhes decorativos
-- ─────────────────────────────────────────────────────────────

local function buildDetalhes()
	local folder = Instance.new("Folder")
	folder.Name  = "Detalhes"
	folder.Parent = lojaFolder

	-- 2 plantas na entrada
	for _, sx in ipairs({-1, 1}) do
		local px = sx * 13
		local pz = -HD + 4

		-- Vaso
		novaPart(folder, "Vaso",
			Vector3.new(px, 1.25, pz),
			Vector3.new(1.5, 2.5, 1.5),
			COR_VASO, Enum.Material.SmoothPlastic)

		-- Haste da planta
		novaPart(folder, "PlantaHaste",
			Vector3.new(px, 3.5, pz),
			Vector3.new(0.3, 2, 0.3),
			COR_PLANTA, Enum.Material.Grass)

		-- Folhas (3 esferas)
		for k = 1, 3 do
			local angle = (k - 1) * (math.pi * 2 / 3)
			local fx = px + math.cos(angle) * 0.8
			local fz = pz + math.sin(angle) * 0.8
			local folha = novaPart(folder, "Folha",
				Vector3.new(fx, 5 + k * 0.3, fz),
				Vector3.new(1.2, 1.2, 1.2),
				Color3.fromRGB(40 + k*20, 140 - k*10, 50), Enum.Material.Grass)
			folha.CanCollide = false
		end
	end

	-- Caixas decorativas sob prateleiras
	local boxColors = {
		Color3.fromRGB(220, 80, 80),
		Color3.fromRGB(80, 120, 220),
		Color3.fromRGB(80, 180, 80),
		Color3.fromRGB(220, 180, 60),
	}
	for k, bc in ipairs(boxColors) do
		local bx = -HW + 2 + (k - 1) * 5
		novaPart(folder, "CaixaDeco",
			Vector3.new(bx, 0.6, HD - 3),
			Vector3.new(2, 1.2, 2),
			bc, MAT_PLASTICO)
		novaPart(folder, "CaixaDecoTampa",
			Vector3.new(bx, 1.35, HD - 3),
			Vector3.new(2.1, 0.3, 2.1),
			bc, MAT_PLASTICO)
	end

	-- Campanhinha de porta
	local sino = novaPart(folder, "Campanhinha",
		Vector3.new(0, H - 0.5, -HD - 0.3),
		Vector3.new(0.8, 0.8, 0.3),
		COR_OURO, MAT_METAL)
	addBillboard(sino, "🔔", UDim2.fromOffset(40, 40), Vector3.new(0, 1.5, 0), 18)

	print("[LojaBuilder] Detalhes decorativos adicionados")
end

-- ─────────────────────────────────────────────────────────────
-- Main
-- ─────────────────────────────────────────────────────────────

print("[LojaBuilder] Iniciando construção…")

buildEstrutura()
buildLootboxes()
buildBalcao()
buildAraras()
buildPrateleiras()
buildManequins()
buildEspelhos()
buildIluminacao()
buildDetalhes()

print("[LojaBuilder] Loja completa — " .. partCount .. " parts criadas")
