-- Lógica principal: DataStore, cliques, upgrades, roupas, anti-exploit.

local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared     = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local ClickEvent       = ReplicatedStorage:WaitForChild("ClickEvent")
local BuyUpgradeEvent  = ReplicatedStorage:WaitForChild("BuyUpgradeEvent")
local UpdateStatsEvent = ReplicatedStorage:WaitForChild("UpdateStatsEvent")
local ClothingEvent    = ReplicatedStorage:WaitForChild("ClothingEvent")
local UpdateOutfitEvent = ReplicatedStorage:WaitForChild("UpdateOutfitEvent")

local dataStore    = DataStoreService:GetDataStore("ClickSimulatorData_v2")
local playerData   = {}
_G.PlayerData      = playerData   -- LootboxService e InventoryService lêem daqui
local clickTracker = {}

-- ─────────────────────────────────────────────────────────────
-- _G.Inventory — API partilhada com LootboxService e InventoryService
-- ─────────────────────────────────────────────────────────────

local MAX_INVENTORY = 200

_G.Inventory = {}
_G.Inventory.fireUpdate = function(_player) end  -- sobrescrito pelo InventoryService

_G.Inventory.addItemToInventory = function(player, item)
	local dados = playerData[player.UserId]
	if not dados then return end
	local key = tostring(item.id)
	if dados.inventory[key] then return end  -- já possui

	dados.inventory[key] = {
		id       = item.id,
		name     = item.name,
		category = item.category,
		ownedAt  = os.time(),
	}

	-- Limita a MAX_INVENTORY: remove não-equipados mais antigos
	local total = 0
	for _ in dados.inventory do total += 1 end

	if total > MAX_INVENTORY then
		local equippedIds = {}
		for _, ids in (dados.equipped or {}) do
			for _, id in ids do equippedIds[id] = true end
		end

		local candidates = {}
		for k, v in dados.inventory do
			if not equippedIds[v.id] then
				table.insert(candidates, { key = k, t = v.ownedAt })
			end
		end
		table.sort(candidates, function(a, b) return a.t < b.t end)

		for i = 1, total - MAX_INVENTORY do
			if candidates[i] then dados.inventory[candidates[i].key] = nil end
		end
	end
end

_G.Inventory.addToEquipped = function(player, itemId, category)
	local dados = playerData[player.UserId]
	if not dados then return end
	if not dados.equipped then dados.equipped = {} end

	if category == "Hats" then
		-- Chapéus acumulam
		if not dados.equipped.Hats then dados.equipped.Hats = {} end
		for _, id in dados.equipped.Hats do
			if id == itemId then return end
		end
		table.insert(dados.equipped.Hats, itemId)
	else
		-- Slot único: substitui
		dados.equipped[category] = { itemId }
	end
end

_G.Inventory.removeFromEquipped = function(player, itemId)
	local dados = playerData[player.UserId]
	if not dados or not dados.equipped then return end

	for category, ids in dados.equipped do
		for i, id in ipairs(ids) do
			if id == itemId then
				table.remove(ids, i)
				if #ids == 0 then dados.equipped[category] = nil end
				return
			end
		end
	end
end

-- ─────────────────────────────────────────────────────────────
-- Outfit padrão
-- ─────────────────────────────────────────────────────────────

local function outfitPadrao()
	local o = {}
	for _, cat in GameConfig.ClothingCategories do
		o[cat.key] = 1
	end
	return o
end

local function dadosPadrao()
	return {
		coins         = GameConfig.StartingCoins,
		clickPower    = GameConfig.StartingClickPower,
		totalClicks   = 0,
		ownedClothing = { skin_1 = true, shirt_1 = true, pants_1 = true },
		outfit        = outfitPadrao(),
		inventory     = {},   -- itens ganhos via lootbox
		equipped      = {},   -- { Hair={id}, Hats={id1,id2}, Shirt={id} }
	}
end

-- ─────────────────────────────────────────────────────────────
-- Aplicar outfit no personagem (via BodyColors)
-- ─────────────────────────────────────────────────────────────

local function getCor(catKey: string, itemIndex: number): Color3
	for _, cat in GameConfig.ClothingCategories do
		if cat.key == catKey then
			local item = cat.items[itemIndex]
			if item then return item.color end
		end
	end
	return Color3.fromRGB(255, 218, 180)
end

local function aplicarOutfit(character: Model, outfit: { [string]: number })
	local bc = character:FindFirstChildOfClass("BodyColors")
	if not bc then return end

	bc.HeadColor3     = getCor("skin",  outfit.skin  or 1)
	bc.TorsoColor3    = getCor("shirt", outfit.shirt or 1)
	bc.LeftArmColor3  = getCor("shirt", outfit.shirt or 1)
	bc.RightArmColor3 = getCor("shirt", outfit.shirt or 1)
	bc.LeftLegColor3  = getCor("pants", outfit.pants or 1)
	bc.RightLegColor3 = getCor("pants", outfit.pants or 1)
end

-- ─────────────────────────────────────────────────────────────
-- Envio de dados ao cliente
-- ─────────────────────────────────────────────────────────────

local function enviarStats(player: Player)
	local dados = playerData[player.UserId]
	if dados then UpdateStatsEvent:FireClient(player, dados) end
end

local function enviarOutfit(player: Player)
	local dados = playerData[player.UserId]
	if dados then UpdateOutfitEvent:FireClient(player, dados.outfit, dados.ownedClothing) end
end

-- ─────────────────────────────────────────────────────────────
-- DataStore
-- ─────────────────────────────────────────────────────────────

local function carregarDados(player: Player)
	local chave = "player_" .. player.UserId

	local sucesso, resultado = pcall(function()
		return dataStore:GetAsync(chave)
	end)

	if sucesso and type(resultado) == "table" then
		local dados = dadosPadrao()
		for k, v in resultado do
			dados[k] = v
		end
		-- Migração: garante campos novos em saves antigos
		if not dados.ownedClothing then dados.ownedClothing = dadosPadrao().ownedClothing end
		if not dados.outfit        then dados.outfit        = outfitPadrao()               end
		if not dados.inventory     then dados.inventory     = {}                           end
		if not dados.equipped      then dados.equipped      = {}                           end
		playerData[player.UserId] = dados
		print("[GameLogic] Dados carregados para", player.Name)
	else
		playerData[player.UserId] = dadosPadrao()
		if not sucesso then
			warn("[GameLogic] Falha ao carregar dados de", player.Name, ":", resultado)
		else
			print("[GameLogic] Novo jogador:", player.Name)
		end
	end

	clickTracker[player.UserId] = { count = 0, lastReset = os.clock() }
	enviarStats(player)
	enviarOutfit(player)
	-- Inventário enviado pelo InventoryService (via fireUpdate após PlayerAdded)
end

local function salvarDados(player: Player)
	local dados = playerData[player.UserId]
	if not dados then return end

	local chave = "player_" .. player.UserId
	local sucesso, erro = pcall(function()
		dataStore:SetAsync(chave, dados)
	end)

	if sucesso then
		print("[GameLogic] Dados salvos para", player.Name)
	else
		warn("[GameLogic] Falha ao salvar dados de", player.Name, ":", erro)
	end
end

-- ─────────────────────────────────────────────────────────────
-- Evento: Clique
-- ─────────────────────────────────────────────────────────────

ClickEvent.OnServerEvent:Connect(function(player: Player)
	local dados = playerData[player.UserId]
	if not dados then return end

	local tracker = clickTracker[player.UserId]
	if tracker then
		local agora = os.clock()
		if agora - tracker.lastReset >= 1 then
			tracker.count     = 0
			tracker.lastReset = agora
		end
		tracker.count += 1
		if tracker.count > GameConfig.MaxClicksPerSecond then return end
	end

	dados.coins       += dados.clickPower
	dados.totalClicks += 1
	enviarStats(player)
end)

-- ─────────────────────────────────────────────────────────────
-- Evento: Compra de upgrade
-- ─────────────────────────────────────────────────────────────

BuyUpgradeEvent.OnServerEvent:Connect(function(player: Player, indice: number)
	local dados = playerData[player.UserId]
	if not dados then return end
	if type(indice) ~= "number" or indice ~= math.floor(indice) then return end

	local upgrade = GameConfig.Upgrades[indice]
	if not upgrade then return end

	if dados.coins < upgrade.cost then
		print("[GameLogic]", player.Name, "sem moedas para:", upgrade.name)
		return
	end

	dados.coins      -= upgrade.cost
	dados.clickPower += upgrade.bonus
	print("[GameLogic]", player.Name, "comprou upgrade:", upgrade.name)
	enviarStats(player)
end)

-- ─────────────────────────────────────────────────────────────
-- Evento: Roupa (sistema legado de cores)
-- ─────────────────────────────────────────────────────────────

ClothingEvent.OnServerEvent:Connect(function(player: Player, action: string, catKey: string, itemIndex: number)
	local dados = playerData[player.UserId]
	if not dados then return end

	local catConfig = nil
	for _, cat in GameConfig.ClothingCategories do
		if cat.key == catKey then catConfig = cat break end
	end
	if not catConfig then return end

	if type(itemIndex) ~= "number" or itemIndex ~= math.floor(itemIndex) then return end
	local item = catConfig.items[itemIndex]
	if not item then return end

	local ownedKey = catKey .. "_" .. itemIndex

	if action == "buy" then
		if dados.ownedClothing[ownedKey] then
			dados.outfit[catKey] = itemIndex
		else
			if dados.coins < item.cost then return end
			dados.coins -= item.cost
			dados.ownedClothing[ownedKey] = true
			dados.outfit[catKey] = itemIndex
		end
	elseif action == "equip" then
		if not dados.ownedClothing[ownedKey] then return end
		dados.outfit[catKey] = itemIndex
	else
		return
	end

	local character = player.Character
	if character then aplicarOutfit(character, dados.outfit) end

	enviarStats(player)
	enviarOutfit(player)
end)

-- ─────────────────────────────────────────────────────────────
-- Ciclo de vida dos jogadores
-- ─────────────────────────────────────────────────────────────

local function onCharacterAdded(player: Player, character: Model)
	task.defer(function()
		local dados = playerData[player.UserId]
		if dados and character.Parent then
			aplicarOutfit(character, dados.outfit)
		end
	end)
end

Players.PlayerAdded:Connect(function(player: Player)
	carregarDados(player)

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	salvarDados(player)
	playerData[player.UserId]   = nil
	clickTracker[player.UserId] = nil
end)

for _, player in Players:GetPlayers() do
	task.spawn(carregarDados, player)
end

-- ─────────────────────────────────────────────────────────────
-- Auto-save e BindToClose
-- ─────────────────────────────────────────────────────────────

task.spawn(function()
	while true do
		task.wait(GameConfig.AutoSaveInterval)
		print("[GameLogic] Auto-save iniciando...")
		for _, player in Players:GetPlayers() do salvarDados(player) end
		print("[GameLogic] Auto-save concluído.")
	end
end)

game:BindToClose(function()
	print("[GameLogic] Servidor encerrando — salvando todos...")
	for _, player in Players:GetPlayers() do salvarDados(player) end
	print("[GameLogic] Salvamento final concluído.")
end)

print("[GameLogic] Sistema iniciado.")
