local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService     = game:GetService("InsertService")

local Shared        = ReplicatedStorage:WaitForChild("Shared")
local LootboxConfig = require(Shared:WaitForChild("LootboxConfig"))
local Catalog       = require(Shared:WaitForChild("Catalog"))

local UpdateStatsEvent = ReplicatedStorage:WaitForChild("UpdateStatsEvent")

-- Cria pasta Remotes (LootboxSpawner também usa essa pasta via WaitForChild)
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
	or (function()
		local f = Instance.new("Folder")
		f.Name   = "Remotes"
		f.Parent = ReplicatedStorage
		return f
	end)()

local LootboxResultEvent = Instance.new("RemoteEvent")
LootboxResultEvent.Name   = "LootboxResultEvent"
LootboxResultEvent.Parent = Remotes

local RequestPurchaseConfirmEvent = Instance.new("RemoteEvent")
RequestPurchaseConfirmEvent.Name   = "RequestPurchaseConfirmEvent"
RequestPurchaseConfirmEvent.Parent = Remotes

local ConfirmPurchaseEvent = Instance.new("RemoteEvent")
ConfirmPurchaseEvent.Name   = "ConfirmPurchaseEvent"
ConfirmPurchaseEvent.Parent = Remotes

local PlayLootboxAnimEvent = Instance.new("RemoteEvent")
PlayLootboxAnimEvent.Name   = "PlayLootboxAnimEvent"
PlayLootboxAnimEvent.Parent = Remotes

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

	print("[Lootbox] LoadAsset", assetId, "→ filhos:")
	for _, child in ipairs(model:GetChildren()) do
		local extra = ""
		if child:IsA("Accessory") then
			extra = " AccessoryType=" .. tostring(child.AccessoryType)
		end
		print("  -", child.ClassName, child.Name, extra)
	end

	local equipped = false

	local shirt = model:FindFirstChildOfClass("Shirt")
	if shirt then
		local ex = character:FindFirstChildOfClass("Shirt")
		if ex then ex:Destroy() end
		shirt.Parent = character
		equipped = true
	end

	local pants = model:FindFirstChildOfClass("Pants")
	if pants then
		local ex = character:FindFirstChildOfClass("Pants")
		if ex then ex:Destroy() end
		pants.Parent = character
		equipped = true
	end

	local tshirt = model:FindFirstChildOfClass("ShirtGraphic")
	if tshirt then
		local ex = character:FindFirstChildOfClass("ShirtGraphic")
		if ex then ex:Destroy() end
		tshirt.Parent = character
		equipped = true
	end

	-- Accessories acumulam sem remover existentes (slot único só pra Shirt/Pants/TShirt)
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("Accessory") then
			child:SetAttribute("AssetId", assetId)
			humanoid:AddAccessory(child)
			equipped = true
		end
	end

	if not equipped then
		local first = model:GetChildren()[1]
		warn("[LootboxService] Tipo não suportado:", first and first.ClassName or "vazio", "| assetId:", assetId)
	end

	model:Destroy()
end

_G.EquipAsset = equipAssetOnPlayer

-- ─────────────────────────────────────────────────────────────
-- Aguarda _G.PlayerData (GameLogic inicia junto)
-- ─────────────────────────────────────────────────────────────

local playerData = nil

task.spawn(function()
	while not _G.PlayerData do task.wait(0.1) end
	playerData = _G.PlayerData
	print("[LootboxService] PlayerData referenciado.")
end)

-- Evita compra dupla enquanto animação roda (3.5s)
local purchasing = {}

Players.PlayerRemoving:Connect(function(player)
	purchasing[player.UserId] = nil
end)

-- ─────────────────────────────────────────────────────────────
-- Fluxo de compra: cliente confirma → server valida → anima → equipa
-- ─────────────────────────────────────────────────────────────

ConfirmPurchaseEvent.OnServerEvent:Connect(function(player: Player, boxId: string)
	if not playerData                 then return end
	if purchasing[player.UserId]      then return end

	local dados = playerData[player.UserId]
	if not dados then return end

	if type(boxId) ~= "string" then return end
	local box = LootboxConfig.getBoxById(boxId)
	if not box then return end

	-- Valida requisito de rebirth
	if box.requiresRebirth and box.requiresRebirth > 0 then
		if (dados.rebirths or 0) < box.requiresRebirth then
			LootboxResultEvent:FireClient(player, {
				success = false,
				reason  = "Requer rebirth " .. box.requiresRebirth,
			})
			purchasing[player.UserId] = nil
			return
		end
	end

	if dados.coins < box.cost then
		print("[LootboxService]", player.Name, "sem moedas para caixa", boxId)
		return
	end

	-- Sorteia item — até 5 tentativas
	local item
	for _ = 1, 5 do
		item = Catalog.getRandomFromCategories(box.categories)
		if item then break end
		task.wait(0)
	end

	if not item then
		warn("[LootboxService] Catálogo vazio para caixa", boxId, "— verifique Catalog.luau")
		return
	end

	-- Cobra moedas e trava nova compra enquanto anima
	purchasing[player.UserId] = true
	dados.coins -= box.cost
	UpdateStatsEvent:FireClient(player, dados)

	print(string.format("[LootboxService] %s abriu %s → %s (%d)", player.Name, box.name, item.name, item.id))

	-- Todos os clientes veem a animação na caixa física
	PlayLootboxAnimEvent:FireAllClients(box.id, { id = item.id, name = item.name, category = item.category })

	-- Espera a animação terminar antes de equipar
	task.wait(3.5)

	equipAssetOnPlayer(player, item.id)

	if _G.Inventory then
		_G.Inventory.addItemToInventory(player, item)
		_G.Inventory.addToEquipped(player, item.id, item.category)
		_G.Inventory.fireUpdate(player)
	end

	-- Resultado só para quem comprou
	LootboxResultEvent:FireClient(player, {
		boxId    = box.id,
		boxName  = box.name,
		itemId   = item.id,
		itemName = item.name,
		category = item.category,
	})

	purchasing[player.UserId] = nil
end)

print("[LootboxService] Pronto.")
