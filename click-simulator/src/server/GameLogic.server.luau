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
local clickTracker = {}

-- ─────────────────────────────────────────────────────────────
-- Outfit padrão: índice 0 de cada categoria (item gratuito)
-- ─────────────────────────────────────────────────────────────

local function outfitPadrao()
	local o = {}
	for _, cat in GameConfig.ClothingCategories do
		o[cat.key] = 1  -- índice 1 = primeiro item (gratuito)
	end
	return o
end

local function dadosPadrao()
	return {
		coins        = GameConfig.StartingCoins,
		clickPower   = GameConfig.StartingClickPower,
		totalClicks  = 0,
		-- { ["skin_1"] = true, ["shirt_3"] = true, ... }
		ownedClothing = { skin_1 = true, shirt_1 = true, pants_1 = true },
		outfit        = outfitPadrao(),
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

	local corPele   = getCor("skin",  outfit.skin  or 1)
	local corCamisa = getCor("shirt", outfit.shirt or 1)
	local corCalca  = getCor("pants", outfit.pants or 1)

	bc.HeadColor3      = corPele
	bc.TorsoColor3     = corCamisa
	bc.LeftArmColor3   = corCamisa
	bc.RightArmColor3  = corCamisa
	bc.LeftLegColor3   = corCalca
	bc.RightLegColor3  = corCalca
end

-- ─────────────────────────────────────────────────────────────
-- Envio de dados ao cliente
-- ─────────────────────────────────────────────────────────────

local function enviarStats(player: Player)
	local dados = playerData[player.UserId]
	if dados then
		UpdateStatsEvent:FireClient(player, dados)
	end
end

local function enviarOutfit(player: Player)
	local dados = playerData[player.UserId]
	if dados then
		UpdateOutfitEvent:FireClient(player, dados.outfit, dados.ownedClothing)
	end
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
		-- Garante que campos novos existam em saves antigos
		if not dados.ownedClothing then dados.ownedClothing = dadosPadrao().ownedClothing end
		if not dados.outfit        then dados.outfit        = outfitPadrao()               end
		playerData[player.UserId] = dados
		print("[GameLogic] Dados carregados para", player.Name)
	else
		playerData[player.UserId] = dadosPadrao()
		if not sucesso then
			warn("[GameLogic] Falha ao carregar dados de", player.Name, "- iniciando do zero:", resultado)
		else
			print("[GameLogic] Novo jogador:", player.Name)
		end
	end

	clickTracker[player.UserId] = { count = 0, lastReset = os.clock() }
	enviarStats(player)
	enviarOutfit(player)
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
-- Evento: Compra de upgrade de click
-- ─────────────────────────────────────────────────────────────

BuyUpgradeEvent.OnServerEvent:Connect(function(player: Player, indice: number)
	local dados = playerData[player.UserId]
	if not dados then return end
	if type(indice) ~= "number" or indice ~= math.floor(indice) then return end

	local upgrade = GameConfig.Upgrades[indice]
	if not upgrade then return end

	if dados.coins < upgrade.cost then
		print("[GameLogic]", player.Name, "sem moedas suficientes para:", upgrade.name)
		return
	end

	dados.coins      -= upgrade.cost
	dados.clickPower += upgrade.bonus
	print("[GameLogic]", player.Name, "comprou upgrade:", upgrade.name)
	enviarStats(player)
end)

-- ─────────────────────────────────────────────────────────────
-- Evento: Roupa (comprar ou equipar)
-- action = "buy"   → deduz moedas, marca como owned, equipa
-- action = "equip" → só equipa (já é owned)
-- ─────────────────────────────────────────────────────────────

ClothingEvent.OnServerEvent:Connect(function(player: Player, action: string, catKey: string, itemIndex: number)
	local dados = playerData[player.UserId]
	if not dados then return end

	-- Valida catKey
	local catConfig = nil
	for _, cat in GameConfig.ClothingCategories do
		if cat.key == catKey then catConfig = cat break end
	end
	if not catConfig then return end

	-- Valida itemIndex
	if type(itemIndex) ~= "number" or itemIndex ~= math.floor(itemIndex) then return end
	local item = catConfig.items[itemIndex]
	if not item then return end

	local ownedKey = catKey .. "_" .. itemIndex

	if action == "buy" then
		-- Já possui?
		if dados.ownedClothing[ownedKey] then
			-- Só equipa
			dados.outfit[catKey] = itemIndex
		else
			-- Valida moedas
			if dados.coins < item.cost then
				print("[GameLogic]", player.Name, "sem moedas para roupa:", item.name)
				return
			end
			dados.coins -= item.cost
			dados.ownedClothing[ownedKey] = true
			dados.outfit[catKey] = itemIndex
			print("[GameLogic]", player.Name, "comprou roupa:", item.name)
		end
	elseif action == "equip" then
		if not dados.ownedClothing[ownedKey] then return end
		dados.outfit[catKey] = itemIndex
	else
		return
	end

	-- Aplica imediatamente no personagem
	local character = player.Character
	if character then
		aplicarOutfit(character, dados.outfit)
	end

	enviarStats(player)
	enviarOutfit(player)
end)

-- ─────────────────────────────────────────────────────────────
-- Ciclo de vida dos jogadores
-- ─────────────────────────────────────────────────────────────

local function onCharacterAdded(player: Player, character: Model)
	-- Espera BodyColors existir antes de aplicar
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

	-- Personagem já presente ao carregar
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
