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

local GetCatalogFunc   = getOrCreate("GetCatalogFunc",   "RemoteFunction")
local BanItemEvent     = getOrCreate("BanItemEvent",     "RemoteEvent")
local UnbanItemEvent   = getOrCreate("UnbanItemEvent",   "RemoteEvent")
local BanConfirmEvent  = getOrCreate("BanConfirmEvent",  "RemoteEvent")

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

print("[AdminService] Pronto.")
