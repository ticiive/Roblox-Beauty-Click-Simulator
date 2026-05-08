local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService     = game:GetService("InsertService")

local Shared        = ReplicatedStorage:WaitForChild("Shared")
local LootboxConfig = require(Shared:WaitForChild("LootboxConfig"))
local Catalog       = require(Shared:WaitForChild("Catalog"))

local UpdateStatsEvent = ReplicatedStorage:WaitForChild("UpdateStatsEvent")

-- Cria pasta Remotes se não existir
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
	or (function()
		local f = Instance.new("Folder")
		f.Name   = "Remotes"
		f.Parent = ReplicatedStorage
		return f
	end)()

local OpenLootboxEvent = Instance.new("RemoteEvent")
OpenLootboxEvent.Name   = "OpenLootboxEvent"
OpenLootboxEvent.Parent = Remotes

local LootboxResultEvent = Instance.new("RemoteEvent")
LootboxResultEvent.Name   = "LootboxResultEvent"
LootboxResultEvent.Parent = Remotes

-- ─────────────────────────────────────────────────────────────
-- Equipa acessório / roupa — detecta tipo real do asset
-- ─────────────────────────────────────────────────────────────

local function equipAssetOnPlayer(player: Player, assetId: number)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local ok, model = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok or not model then
		warn("[LootboxService] Falha ao carregar asset", assetId, ":", model)
		return
	end

	-- Debug: lista filhos do model carregado
	print("[Lootbox] LoadAsset", assetId, "→ filhos:")
	for _, child in ipairs(model:GetChildren()) do
		local extra = ""
		if child:IsA("Accessory") then
			extra = " AccessoryType=" .. tostring(child.AccessoryType)
		end
		print("  -", child.ClassName, child.Name, extra)
	end

	local equipped = false

	-- Shirt
	local shirt = model:FindFirstChildOfClass("Shirt")
	if shirt then
		local existing = character:FindFirstChildOfClass("Shirt")
		if existing then existing:Destroy() end
		shirt.Parent = character
		equipped = true
	end

	-- Pants
	local pants = model:FindFirstChildOfClass("Pants")
	if pants then
		local existing = character:FindFirstChildOfClass("Pants")
		if existing then existing:Destroy() end
		pants.Parent = character
		equipped = true
	end

	-- ShirtGraphic (T-Shirt)
	local tshirt = model:FindFirstChildOfClass("ShirtGraphic")
	if tshirt then
		local existing = character:FindFirstChildOfClass("ShirtGraphic")
		if existing then existing:Destroy() end
		tshirt.Parent = character
		equipped = true
	end

	-- Acessórios — itera todos (um model pode ter só um, mas iteramos por segurança)
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("Accessory") then
			-- Remove acessório existente do mesmo tipo para não acumular
			local accType = child.AccessoryType
			if accType ~= Enum.AccessoryType.Unknown then
				for _, existing in ipairs(character:GetChildren()) do
					if existing:IsA("Accessory") and existing.AccessoryType == accType then
						existing:Destroy()
					end
				end
			end
			humanoid:AddAccessory(child)
			equipped = true
		end
	end

	if not equipped then
		local primeiro = model:GetChildren()[1]
		warn("[LootboxService] Tipo não suportado:", primeiro and primeiro.ClassName or "vazio", "| assetId:", assetId)
	end

	model:Destroy()
end

-- ─────────────────────────────────────────────────────────────
-- Aguarda _G.PlayerData (GameLogic inicia junto)
-- ─────────────────────────────────────────────────────────────

local playerData = nil

task.spawn(function()
	while not _G.PlayerData do
		task.wait(0.1)
	end
	playerData = _G.PlayerData
	print("[LootboxService] PlayerData referenciado.")
end)

-- ─────────────────────────────────────────────────────────────
-- Evento principal: abrir caixa
-- ─────────────────────────────────────────────────────────────

OpenLootboxEvent.OnServerEvent:Connect(function(player: Player, boxId: string)
	if not playerData then return end

	local dados = playerData[player.UserId]
	if not dados then return end

	if type(boxId) ~= "string" then return end
	local box = LootboxConfig.getBoxById(boxId)
	if not box then return end

	if dados.coins < box.cost then
		print("[LootboxService]", player.Name, "sem moedas para caixa", boxId)
		return
	end

	-- Sorteia item — até 5 tentativas caso categorias venham vazias
	local item
	for attempt = 1, 5 do
		item = Catalog.getRandomFromCategories(box.categories)
		if item then break end
		task.wait(0)
	end

	if not item then
		warn("[LootboxService] Catálogo vazio para caixa", boxId, "— verifique Catalog.luau")
		return
	end

	-- Deduz moedas
	dados.coins -= box.cost

	-- Envia resultado ao cliente antes de equipar (equip pode demorar)
	LootboxResultEvent:FireClient(player, {
		boxId    = boxId,
		boxName  = box.name,
		itemId   = item.id,
		itemName = item.name,
		category = item.category,
	})

	UpdateStatsEvent:FireClient(player, dados)

	print(string.format("[LootboxService] %s abriu %s → %s (%d)", player.Name, box.name, item.name, item.id))

	-- Equipa no personagem
	task.spawn(function()
		equipAssetOnPlayer(player, item.id)
	end)
end)

print("[LootboxService] Pronto.")
