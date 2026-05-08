local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local AdminConfig = require(Shared:WaitForChild("AdminConfig"))
local Catalog     = require(Shared:WaitForChild("Catalog"))

-- ─────────────────────────────────────────────────────────────
-- DataStore
-- ─────────────────────────────────────────────────────────────

local blacklistStore = DataStoreService:GetDataStore("CatalogBlacklist_v1")

-- Carrega blacklist na inicialização
_G.CatalogBlacklist = {}

local ok, data = pcall(function()
	return blacklistStore:GetAsync("blacklist")
end)
if ok and data then
	for _, id in ipairs(data) do
		_G.CatalogBlacklist[id] = true
	end
	print(string.format("[AdminService] Blacklist carregada: %d item(s) banidos", #data))
else
	print("[AdminService] Blacklist vazia ou erro ao carregar:", tostring(data))
end

local function saveBlacklist()
	local ids = {}
	for id in pairs(_G.CatalogBlacklist) do
		table.insert(ids, id)
	end
	local saveOk, err = pcall(function()
		blacklistStore:SetAsync("blacklist", ids)
	end)
	if not saveOk then
		warn("[AdminService] Erro ao salvar blacklist:", err)
	end
end

-- ─────────────────────────────────────────────────────────────
-- Remotes
-- ─────────────────────────────────────────────────────────────

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local function getOrCreate(name: string, className: string)
	local existing = Remotes:FindFirstChild(name)
	if existing then return existing end
	local obj = Instance.new(className)
	obj.Name   = name
	obj.Parent = Remotes
	return obj
end

local GetCatalogFunc        = getOrCreate("GetCatalogFunc",        "RemoteFunction")
local BanItemEvent          = getOrCreate("BanItemEvent",          "RemoteEvent")
local UnbanItemEvent        = getOrCreate("UnbanItemEvent",        "RemoteEvent")
local BanConfirmEvent       = getOrCreate("BanConfirmEvent",       "RemoteEvent")
local AdminEquipItemEvent   = getOrCreate("AdminEquipItemEvent",   "RemoteEvent")
local AdminEquipConfirmEvent= getOrCreate("AdminEquipConfirmEvent","RemoteEvent")

-- ─────────────────────────────────────────────────────────────
-- GetCatalog — retorna catálogo + blacklist ao admin
-- ─────────────────────────────────────────────────────────────

GetCatalogFunc.OnServerInvoke = function(player: Player)
	if not AdminConfig.isAdmin(player.UserId) then
		warn("[AdminService] GetCatalog negado:", player.Name)
		return nil
	end

	-- Serializa cada categoria do Catalog
	local catalogData = {}
	local categories = {
		"Hair", "Hats", "FaceAcc", "NeckAcc", "ShoulderAcc",
		"WaistAcc", "Shirts", "Pants", "TShirts",
	}
	for _, cat in ipairs(categories) do
		local list = (Catalog :: any)[cat]
		if list then
			local items = {}
			for _, item in ipairs(list) do
				table.insert(items, { id = item.id, name = item.name, price = item.price })
			end
			catalogData[cat] = items
		end
	end

	-- Converte blacklist para array de ids
	local bannedIds = {}
	for id in pairs(_G.CatalogBlacklist) do
		table.insert(bannedIds, id)
	end

	return { catalog = catalogData, blacklist = bannedIds }
end

-- ─────────────────────────────────────────────────────────────
-- BanItem
-- ─────────────────────────────────────────────────────────────

BanItemEvent.OnServerEvent:Connect(function(player: Player, itemId: number)
	if not AdminConfig.isAdmin(player.UserId) then
		warn("[AdminService] BanItem negado:", player.Name)
		return
	end
	if type(itemId) ~= "number" then return end

	_G.CatalogBlacklist[itemId] = true
	saveBlacklist()
	print(string.format("[AdminService] Item %d banido por %s", itemId, player.Name))
	BanConfirmEvent:FireClient(player, itemId, true)  -- true = banido
end)

-- ─────────────────────────────────────────────────────────────
-- UnbanItem
-- ─────────────────────────────────────────────────────────────

UnbanItemEvent.OnServerEvent:Connect(function(player: Player, itemId: number)
	if not AdminConfig.isAdmin(player.UserId) then
		warn("[AdminService] UnbanItem negado:", player.Name)
		return
	end
	if type(itemId) ~= "number" then return end

	_G.CatalogBlacklist[itemId] = nil
	saveBlacklist()
	print(string.format("[AdminService] Item %d restaurado por %s", itemId, player.Name))
	BanConfirmEvent:FireClient(player, itemId, false)  -- false = ativo
end)

-- ─────────────────────────────────────────────────────────────
-- AdminEquipItem — equipa item no avatar do admin (sem cobrar)
-- ─────────────────────────────────────────────────────────────

AdminEquipItemEvent.OnServerEvent:Connect(function(player: Player, itemId: number, category: string)
	if not AdminConfig.isAdmin(player.UserId) then
		warn("[AdminService] AdminEquip negado:", player.Name)
		return
	end
	if type(itemId) ~= "number" or type(category) ~= "string" then return end

	-- Aguarda _G.EquipAsset ficar disponível (LootboxService pode ainda estar iniciando)
	local timeout = 0
	while not _G.EquipAsset and timeout < 5 do
		task.wait(0.1)
		timeout += 0.1
	end

	if not _G.EquipAsset then
		warn("[AdminService] _G.EquipAsset indisponível após 5s")
		AdminEquipConfirmEvent:FireClient(player, itemId, false)
		return
	end

	-- Valida que o item existe no catálogo
	local list = (Catalog :: any)[category]
	local found = false
	if list then
		for _, item in ipairs(list) do
			if item.id == itemId then found = true; break end
		end
	end
	if not found then
		warn(string.format("[AdminService] Item %d não encontrado em %s", itemId, category))
		AdminEquipConfirmEvent:FireClient(player, itemId, false)
		return
	end

	local ok, err = pcall(function()
		_G.EquipAsset(player, itemId)
	end)

	if not ok then
		warn("[AdminService] Erro ao equipar item", itemId, ":", err)
		AdminEquipConfirmEvent:FireClient(player, itemId, false)
		return
	end

	print(string.format("[AdminService] Admin %s equipou item %d (%s)", player.Name, itemId, category))
	AdminEquipConfirmEvent:FireClient(player, itemId, true)
end)

print("[AdminService] Pronto.")
