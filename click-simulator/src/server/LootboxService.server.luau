local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService     = game:GetService("InsertService")

local Shared        = ReplicatedStorage:WaitForChild("Shared")
local LootboxConfig = require(Shared:WaitForChild("LootboxConfig"))
local Catalog       = require(Shared:WaitForChild("Catalog"))

-- RemoteEvents criados pelo Setup.server.luau
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
-- Equipa acessório / roupa no personagem
-- ─────────────────────────────────────────────────────────────

local function equipAssetOnPlayer(player: Player, assetId: number, assetCategory: string)
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

	local assetType = LootboxConfig.AssetTypeByCategory[assetCategory]

	if assetType == "Shirt" then
		local shirt = model:FindFirstChildOfClass("Shirt")
		if shirt then
			local existing = character:FindFirstChildOfClass("Shirt")
			if existing then existing:Destroy() end
			shirt.Parent = character
		end
	elseif assetType == "Pants" then
		local pants = model:FindFirstChildOfClass("Pants")
		if pants then
			local existing = character:FindFirstChildOfClass("Pants")
			if existing then existing:Destroy() end
			pants.Parent = character
		end
	elseif assetType == "TShirt" then
		-- T-shirts são aplicadas via shirt gráfica (apenas visual)
		local shirt = model:FindFirstChildOfClass("Shirt")
		if shirt then
			local existing = character:FindFirstChildOfClass("Shirt")
			if existing then existing:Destroy() end
			shirt.Parent = character
		end
	else
		-- Acessório (Hat, Hair, Face, Neck, Shoulder, Waist, etc.)
		local accessory = model:FindFirstChildOfClass("Accessory")
		if accessory then
			humanoid:AddAccessory(accessory)
		end
	end

	model:Destroy()
end

-- ─────────────────────────────────────────────────────────────
-- Aguarda _G.PlayerData ficar disponível (GameLogic inicia junto)
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

	-- Sorteia item
	local item = Catalog.getRandomFromCategories(box.categories)
	if not item then
		warn("[LootboxService] Catálogo vazio para caixa", boxId)
		return
	end

	-- Deduz moedas
	dados.coins -= box.cost

	-- Envia resultado ao cliente antes de tentar equipar (equip pode demorar)
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
		equipAssetOnPlayer(player, item.id, item.category)
	end)
end)

print("[LootboxService] Pronto.")
