-- Lógica principal do servidor:
-- carrega/salva dados via DataStore, processa cliques e compras,
-- aplica rate limiting, auto-save e salvamento ao fechar servidor.

local Players            = game:GetService("Players")
local DataStoreService   = game:GetService("DataStoreService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local Shared     = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local ClickEvent       = ReplicatedStorage:WaitForChild("ClickEvent")
local BuyUpgradeEvent  = ReplicatedStorage:WaitForChild("BuyUpgradeEvent")
local UpdateStatsEvent = ReplicatedStorage:WaitForChild("UpdateStatsEvent")

local dataStore = DataStoreService:GetDataStore("ClickSimulatorData_v1")

-- { [userId] = { coins, clickPower, totalClicks } }
local playerData = {}

-- { [userId] = { count, lastReset } }  – para rate limiting
local clickTracker = {}

-- ─────────────────────────────────────────────────────────────
-- Utilitários
-- ─────────────────────────────────────────────────────────────

local function dadosPadrao(): { coins: number, clickPower: number, totalClicks: number }
	return {
		coins       = GameConfig.StartingCoins,
		clickPower  = GameConfig.StartingClickPower,
		totalClicks = 0,
	}
end

local function enviarStats(player: Player)
	local dados = playerData[player.UserId]
	if dados then
		UpdateStatsEvent:FireClient(player, dados)
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
		-- Garante que campos novos existam caso o save seja antigo
		local dados = dadosPadrao()
		for k, v in resultado do
			dados[k] = v
		end
		playerData[player.UserId] = dados
		print("[GameLogic] Dados carregados para", player.Name)
	else
		playerData[player.UserId] = dadosPadrao()
		if not sucesso then
			warn("[GameLogic] Falha ao carregar dados de", player.Name, "- iniciando do zero. Erro:", resultado)
		else
			print("[GameLogic] Novo jogador:", player.Name)
		end
	end

	clickTracker[player.UserId] = { count = 0, lastReset = os.clock() }
	enviarStats(player)
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
	local userId = player.UserId
	local dados  = playerData[userId]
	if not dados then return end

	-- Rate limiting: descarta cliques acima do limite por segundo
	local tracker = clickTracker[userId]
	if tracker then
		local agora = os.clock()
		if agora - tracker.lastReset >= 1 then
			tracker.count     = 0
			tracker.lastReset = agora
		end
		tracker.count += 1
		if tracker.count > GameConfig.MaxClicksPerSecond then
			return
		end
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

	-- Validação: índice deve ser número inteiro dentro do range
	if type(indice) ~= "number" or indice ~= math.floor(indice) then return end

	local upgrade = GameConfig.Upgrades[indice]
	if not upgrade then return end

	-- Validação: moedas suficientes
	if dados.coins < upgrade.cost then
		print("[GameLogic]", player.Name, "tentou comprar sem moedas suficientes:", upgrade.name)
		return
	end

	dados.coins      -= upgrade.cost
	dados.clickPower += upgrade.bonus

	print("[GameLogic]", player.Name, "comprou:", upgrade.name)
	enviarStats(player)
end)

-- ─────────────────────────────────────────────────────────────
-- Ciclo de vida dos jogadores
-- ─────────────────────────────────────────────────────────────

Players.PlayerAdded:Connect(carregarDados)

Players.PlayerRemoving:Connect(function(player: Player)
	salvarDados(player)
	playerData[player.UserId]   = nil
	clickTracker[player.UserId] = nil
end)

-- Jogadores já presentes quando o script carrega (raro em produção, comum em testes)
for _, player in Players:GetPlayers() do
	task.spawn(carregarDados, player)
end

-- ─────────────────────────────────────────────────────────────
-- Auto-save periódico
-- ─────────────────────────────────────────────────────────────

task.spawn(function()
	while true do
		task.wait(GameConfig.AutoSaveInterval)
		print("[GameLogic] Auto-save iniciando...")
		for _, player in Players:GetPlayers() do
			salvarDados(player)
		end
		print("[GameLogic] Auto-save concluído.")
	end
end)

-- ─────────────────────────────────────────────────────────────
-- Salva tudo ao fechar o servidor
-- ─────────────────────────────────────────────────────────────

game:BindToClose(function()
	print("[GameLogic] Servidor encerrando — salvando todos os jogadores...")
	for _, player in Players:GetPlayers() do
		salvarDados(player)
	end
	print("[GameLogic] Salvamento final concluído.")
end)

print("[GameLogic] Sistema iniciado.")
