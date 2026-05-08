local Players           = game:GetService("Players")
local InsertService     = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local InventoryUpdateEvent = Instance.new("RemoteEvent")
InventoryUpdateEvent.Name   = "InventoryUpdateEvent"
InventoryUpdateEvent.Parent = Remotes

local EquipItemEvent = Instance.new("RemoteEvent")
EquipItemEvent.Name   = "EquipItemEvent"
EquipItemEvent.Parent = Remotes

local UnequipItemEvent = Instance.new("RemoteEvent")
UnequipItemEvent.Name   = "UnequipItemEvent"
UnequipItemEvent.Parent = Remotes

local RecolorItemEvent = Instance.new("RemoteEvent")
RecolorItemEvent.Name   = "RecolorItemEvent"
RecolorItemEvent.Parent = Remotes

-- ─────────────────────────────────────────────────────────────
-- Aguarda _G.PlayerData e injeta _G.Inventory.fireUpdate
-- ─────────────────────────────────────────────────────────────

local playerData = nil

task.spawn(function()
	local t = 0
	while not _G.PlayerData and t < 15 do
		task.wait(0.1)
		t += 0.1
	end
	playerData = _G.PlayerData
	if not playerData then
		warn("[InventoryService] Timeout aguardando PlayerData")
		return
	end
	print("[InventoryService] PlayerData referenciado.")

	if _G.Inventory then
		_G.Inventory.fireUpdate = function(player: Player)
			local dados = playerData[player.UserId]
			if dados then
				InventoryUpdateEvent:FireClient(player, dados.inventory or {}, dados.equipped or {})
			end
		end
		print("[InventoryService] fireUpdate injetado.")
	end
end)

-- ─────────────────────────────────────────────────────────────
-- Equipa asset no personagem (com AssetId attribute + multi-hat)
-- ─────────────────────────────────────────────────────────────

local function equipAsset(player: Player, assetId: number)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local ok, model = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok or not model then
		warn("[InventoryService] Falha ao carregar asset", assetId, ":", model)
		return
	end

	local shirt = model:FindFirstChildOfClass("Shirt")
	if shirt then
		local ex = character:FindFirstChildOfClass("Shirt")
		if ex then ex:Destroy() end
		shirt.Parent = character
	end

	local pants = model:FindFirstChildOfClass("Pants")
	if pants then
		local ex = character:FindFirstChildOfClass("Pants")
		if ex then ex:Destroy() end
		pants.Parent = character
	end

	local tshirt = model:FindFirstChildOfClass("ShirtGraphic")
	if tshirt then
		local ex = character:FindFirstChildOfClass("ShirtGraphic")
		if ex then ex:Destroy() end
		tshirt.Parent = character
	end

	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("Accessory") then
			local accType = child.AccessoryType
			if accType ~= Enum.AccessoryType.Unknown and accType ~= Enum.AccessoryType.Hat then
				for _, ex in ipairs(character:GetChildren()) do
					if ex:IsA("Accessory") and ex.AccessoryType == accType then
						ex:Destroy()
					end
				end
			end
			child:SetAttribute("AssetId", assetId)
			humanoid:AddAccessory(child)
		end
	end

	model:Destroy()
end

-- ─────────────────────────────────────────────────────────────
-- EquipItemEvent: cliente quer equipar item do inventário
-- ─────────────────────────────────────────────────────────────

EquipItemEvent.OnServerEvent:Connect(function(player: Player, itemId: number)
	if not playerData then return end
	if type(itemId) ~= "number" then return end

	local dados = playerData[player.UserId]
	if not dados then return end

	local key  = tostring(itemId)
	local item = dados.inventory[key]
	if not item then
		warn("[InventoryService]", player.Name, "tentou equipar item não possuído:", itemId)
		return
	end

	equipAsset(player, itemId)

	if _G.Inventory then
		_G.Inventory.addToEquipped(player, itemId, item.category)
		_G.Inventory.fireUpdate(player)
	end
end)

-- ─────────────────────────────────────────────────────────────
-- UnequipItemEvent: cliente quer desequipar item
-- ─────────────────────────────────────────────────────────────

UnequipItemEvent.OnServerEvent:Connect(function(player: Player, itemId: number)
	if not playerData then return end
	if type(itemId) ~= "number" then return end

	local dados = playerData[player.UserId]
	if not dados then return end

	local character = player.Character
	if character then
		-- Remove acessório pelo AssetId attribute
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Accessory") and child:GetAttribute("AssetId") == itemId then
				child:Destroy()
				break
			end
		end

		-- Remove Shirt/Pants/ShirtGraphic pela categoria
		local item = dados.inventory[tostring(itemId)]
		if item then
			local cat = item.category
			if cat == "Shirt" then
				local ex = character:FindFirstChildOfClass("Shirt")
				if ex then ex:Destroy() end
			elseif cat == "Pants" then
				local ex = character:FindFirstChildOfClass("Pants")
				if ex then ex:Destroy() end
			elseif cat == "TShirt" then
				local ex = character:FindFirstChildOfClass("ShirtGraphic")
				if ex then ex:Destroy() end
			end
		end
	end

	if _G.Inventory then
		_G.Inventory.removeFromEquipped(player, itemId)
		_G.Inventory.fireUpdate(player)
	end
end)

-- ─────────────────────────────────────────────────────────────
-- RecolorItemEvent: muda cor de acessório equipado
-- ─────────────────────────────────────────────────────────────

RecolorItemEvent.OnServerEvent:Connect(function(player: Player, itemId: number, color: Color3)
	if type(itemId) ~= "number" then return end
	if typeof(color) ~= "Color3" then return end

	local character = player.Character
	if not character then return end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") and child:GetAttribute("AssetId") == itemId then
			for _, part in child:GetDescendants() do
				if part:IsA("BasePart") then
					part.Color = color
				end
			end
			break
		end
	end
end)

-- ─────────────────────────────────────────────────────────────
-- Re-equipa tudo ao respawnar
-- ─────────────────────────────────────────────────────────────

local function reequipAll(player: Player)
	if not playerData then return end
	local dados = playerData[player.UserId]
	if not dados or not dados.equipped then return end

	local allIds = {}
	for _, ids in dados.equipped do
		for _, id in ids do
			table.insert(allIds, id)
		end
	end

	for _, id in ipairs(allIds) do
		task.wait(0.3)
		equipAsset(player, id)
	end
end

-- ─────────────────────────────────────────────────────────────
-- Ciclo de vida
-- ─────────────────────────────────────────────────────────────

local function waitAndFireUpdate(player: Player)
	task.spawn(function()
		local t = 0
		while (not playerData or not playerData[player.UserId]) and t < 10 do
			task.wait(0.2)
			t += 0.2
		end
		if playerData and playerData[player.UserId] then
			local dados = playerData[player.UserId]
			InventoryUpdateEvent:FireClient(player, dados.inventory or {}, dados.equipped or {})
		end
	end)
end

Players.PlayerAdded:Connect(function(player: Player)
	waitAndFireUpdate(player)

	player.CharacterAdded:Connect(function()
		task.delay(1, function()
			reequipAll(player)
		end)
	end)
end)

for _, player in Players:GetPlayers() do
	waitAndFireUpdate(player)
end

print("[InventoryService] Pronto.")
