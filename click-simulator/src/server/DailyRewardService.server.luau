local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared            = ReplicatedStorage:WaitForChild("Shared")
local DailyConfig       = require(Shared:WaitForChild("DailyRewardConfig"))
local Catalog           = require(Shared:WaitForChild("Catalog"))

-- ─────────────────────────────────────────────────────────────
-- DataStore
-- ─────────────────────────────────────────────────────────────

local ds = DataStoreService:GetDataStore("DailyRewards_v1")

local function carregar(userId: number)
	local ok, result = pcall(function()
		return ds:GetAsync("daily_" .. userId)
	end)
	if ok and result then return result end
	return { lastClaimTime = 0, currentStreak = 0, highestStreak = 0 }
end

local function salvar(userId: number, data: table)
	pcall(function()
		ds:SetAsync("daily_" .. userId, data)
	end)
end

-- ─────────────────────────────────────────────────────────────
-- Remotes (criados aqui se não existirem)
-- ─────────────────────────────────────────────────────────────

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local function getOrCreate(name: string, class: string)
	local r = Remotes:FindFirstChild(name)
	if not r then
		r = Instance.new(class)
		r.Name   = name
		r.Parent = Remotes
	end
	return r
end

local ClaimDailyRewardEvent  = getOrCreate("ClaimDailyRewardEvent",  "RemoteEvent")
local DailyRewardResultEvent = getOrCreate("DailyRewardResultEvent", "RemoteEvent")
local DailyRewardStatusEvent = getOrCreate("DailyRewardStatusEvent", "RemoteEvent")

-- ─────────────────────────────────────────────────────────────
-- Lógica
-- ─────────────────────────────────────────────────────────────

local function calcStatus(data: table)
	local now       = os.time()
	local elapsed   = now - (data.lastClaimTime or 0)
	local canClaim  = elapsed >= DailyConfig.ClaimCooldown

	-- Verifica se streak quebrou (mais de 48h sem entrar)
	local streakValido = elapsed < DailyConfig.StreakWindow
	local streak = data.currentStreak or 0
	if not streakValido and data.lastClaimTime > 0 then
		streak = 0  -- quebrou; será setado para 1 na próxima coleta
	end

	local diaAtual   = (streak % DailyConfig.MaxStreak) + 1
	local recompensa = DailyConfig.Rewards[diaAtual]

	local timeUntilNext = math.max(0, DailyConfig.ClaimCooldown - elapsed)

	return {
		canClaim       = canClaim,
		currentStreak  = streak,
		highestStreak  = data.highestStreak or 0,
		nextReward     = recompensa,
		diaAtual       = diaAtual,
		timeUntilNext  = timeUntilNext,
	}
end

local function darRecompensa(player: Player)
	local userId = player.UserId
	local data   = carregar(userId)
	local status = calcStatus(data)

	if not status.canClaim then
		DailyRewardResultEvent:FireClient(player, {
			success = false,
			reason  = "Aguarde " .. math.ceil(status.timeUntilNext / 60) .. " minutos",
		})
		return
	end

	-- Atualiza streak
	local now     = os.time()
	local elapsed = now - (data.lastClaimTime or 0)
	local streakValido = elapsed < DailyConfig.StreakWindow

	if not streakValido and data.lastClaimTime > 0 then
		data.currentStreak = 1  -- quebrou, recomeça em 1
	else
		data.currentStreak = (data.currentStreak or 0) + 1
	end

	if data.currentStreak > (data.highestStreak or 0) then
		data.highestStreak = data.currentStreak
	end

	data.lastClaimTime = now
	salvar(userId, data)

	local diaIdx     = ((data.currentStreak - 1) % DailyConfig.MaxStreak) + 1
	local recompensa = DailyConfig.Rewards[diaIdx]

	-- Aguarda _G.PlayerData estar disponível (até 10s)
	local dadosJogador = nil
	for _ = 1, 20 do
		if _G.PlayerData and _G.PlayerData[userId] then
			dadosJogador = _G.PlayerData[userId]
			break
		end
		task.wait(0.5)
	end

	if not dadosJogador then
		DailyRewardResultEvent:FireClient(player, { success = false, reason = "Dados não carregados" })
		return
	end

	-- Dá moedas
	dadosJogador.coins = (dadosJogador.coins or 0) + recompensa.coins
	print(string.format("[DailyReward] %s recebeu %d moedas (dia %d)", player.Name, recompensa.coins, diaIdx))

	-- Dá item se aplicável
	local itemGanho = nil

	if recompensa.itemCategories then
		local item = Catalog.getRandomFromCategories(recompensa.itemCategories)
		if item and _G.Inventory then
			_G.Inventory.addItemToInventory(player, item)
			if _G.Inventory.fireUpdate then
				_G.Inventory.fireUpdate(player)
			end
			itemGanho = item
			print(string.format("[DailyReward] %s ganhou item: %s (id=%d)", player.Name, item.name, item.id))
		end
	elseif recompensa.specialBox then
		local item = Catalog.getRandomFromCategories(recompensa.boxCategories)
		if item and _G.Inventory then
			_G.Inventory.addItemToInventory(player, item)
			if _G.Inventory.fireUpdate then
				_G.Inventory.fireUpdate(player)
			end
			itemGanho = item
			print(string.format("[DailyReward] %s ganhou item especial: %s (id=%d)", player.Name, item.name, item.id))
		end
	end

	-- Dispara UpdateStatsEvent
	local UpdateStatsEvent = ReplicatedStorage:FindFirstChild("UpdateStatsEvent")
	if UpdateStatsEvent then
		UpdateStatsEvent:FireClient(player, dadosJogador)
	end

	DailyRewardResultEvent:FireClient(player, {
		success       = true,
		day           = diaIdx,
		coins         = recompensa.coins,
		streak        = data.currentStreak,
		item          = itemGanho,
		specialBox    = recompensa.specialBox or false,
	})

	print(string.format("[DailyReward] %s coletou recompensa dia %d (streak %d)", player.Name, diaIdx, data.currentStreak))
end

-- ─────────────────────────────────────────────────────────────
-- Eventos
-- ─────────────────────────────────────────────────────────────

ClaimDailyRewardEvent.OnServerEvent:Connect(function(player)
	darRecompensa(player)
end)

Players.PlayerAdded:Connect(function(player)
	-- Pequena espera para que GameLogic carregue os dados primeiro
	task.wait(3)
	if not player or not player.Parent then return end

	local data   = carregar(player.UserId)
	local status = calcStatus(data)

	DailyRewardStatusEvent:FireClient(player, status)
	print(string.format("[DailyReward] %s status: canClaim=%s streak=%d",
		player.Name, tostring(status.canClaim), status.currentStreak))
end)

print("[DailyRewardService] Pronto.")
