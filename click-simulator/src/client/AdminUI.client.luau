local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local AdminConfig = require(Shared:WaitForChild("AdminConfig"))

-- Sai imediatamente se não for admin
if not AdminConfig.isAdmin(LocalPlayer.UserId) then return end

local Remotes        = ReplicatedStorage:WaitForChild("Remotes")
local GetCatalogFunc = Remotes:WaitForChild("GetCatalogFunc")
local BanItemEvent   = Remotes:WaitForChild("BanItemEvent")
local UnbanItemEvent = Remotes:WaitForChild("UnbanItemEvent")
local BanConfirmEvent= Remotes:WaitForChild("BanConfirmEvent")

-- ─────────────────────────────────────────────────────────────
-- Estado
-- ─────────────────────────────────────────────────────────────

local catalogData    = {}   -- { [catName] = { {id, name, price}, ... } }
local blacklistSet   = {}   -- { [id] = true }
local currentTab     = nil
local pendingActions = {}   -- { [id] = true } — aguardando confirmação
local loadedTabs     = {}   -- { [catName] = true } — já renderizou a lista

local CATEGORIES = {
	"Hair", "Hats", "FaceAcc", "NeckAcc", "ShoulderAcc",
	"WaistAcc", "Shirts", "Pants", "TShirts",
}

-- ─────────────────────────────────────────────────────────────
-- UI
-- ─────────────────────────────────────────────────────────────

local screenGui   = Instance.new("ScreenGui")
screenGui.Name    = "AdminUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent  = LocalPlayer:WaitForChild("PlayerGui")

-- Botão ⚙️ Admin (canto superior direito)
local openBtn       = Instance.new("TextButton")
openBtn.Name        = "AdminOpenBtn"
openBtn.Size        = UDim2.fromOffset(90, 30)
openBtn.Position    = UDim2.new(1, -98, 0, 8)
openBtn.Text        = "⚙️ Admin"
openBtn.TextSize    = 13
openBtn.Font        = Enum.Font.GothamBold
openBtn.TextColor3  = Color3.new(1, 1, 1)
openBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
openBtn.BorderSizePixel  = 0
openBtn.ZIndex      = 10
openBtn.Parent      = screenGui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 6)

-- Overlay escuro
local overlay       = Instance.new("Frame")
overlay.Name        = "AdminOverlay"
overlay.Size        = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.45
overlay.BorderSizePixel = 0
overlay.Visible     = false
overlay.ZIndex      = 20
overlay.Parent      = screenGui

-- Painel principal (80% da tela, centralizado)
local panel         = Instance.new("Frame")
panel.Name          = "AdminPanel"
panel.Size          = UDim2.fromScale(0.82, 0.84)
panel.Position      = UDim2.fromScale(0.09, 0.08)
panel.BackgroundColor3 = Color3.fromRGB(18, 14, 28)
panel.BorderSizePixel  = 0
panel.Visible       = false
panel.ZIndex        = 21
panel.Parent        = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

-- Header
local header        = Instance.new("Frame")
header.Size         = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = Color3.fromRGB(30, 22, 48)
header.BorderSizePixel  = 0
header.ZIndex       = 22
header.Parent       = panel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local titleLbl      = Instance.new("TextLabel")
titleLbl.Size       = UDim2.new(0.5, 0, 1, 0)
titleLbl.Position   = UDim2.fromOffset(14, 0)
titleLbl.Text       = "⚙️  Painel Admin — Catálogo"
titleLbl.TextSize   = 16
titleLbl.Font       = Enum.Font.GothamBold
titleLbl.TextColor3 = Color3.new(1, 1, 1)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.BackgroundTransparency = 1
titleLbl.ZIndex     = 23
titleLbl.Parent     = header

local counterLbl    = Instance.new("TextLabel")
counterLbl.Name     = "Counter"
counterLbl.Size     = UDim2.new(0.35, 0, 1, 0)
counterLbl.Position = UDim2.new(0.5, 0, 0, 0)
counterLbl.Text     = "Total: 0 | Banidos: 0"
counterLbl.TextSize = 12
counterLbl.Font     = Enum.Font.Gotham
counterLbl.TextColor3 = Color3.fromRGB(180, 160, 220)
counterLbl.TextXAlignment = Enum.TextXAlignment.Center
counterLbl.BackgroundTransparency = 1
counterLbl.ZIndex   = 23
counterLbl.Parent   = header

local searchBox     = Instance.new("TextBox")
searchBox.Name      = "SearchBox"
searchBox.Size      = UDim2.fromOffset(170, 26)
searchBox.Position  = UDim2.new(1, -260, 0.5, -13)
searchBox.PlaceholderText = "🔍 Buscar..."
searchBox.Text      = ""
searchBox.TextSize  = 12
searchBox.Font      = Enum.Font.Gotham
searchBox.TextColor3 = Color3.new(1, 1, 1)
searchBox.PlaceholderColor3 = Color3.fromRGB(140, 120, 170)
searchBox.BackgroundColor3  = Color3.fromRGB(40, 30, 60)
searchBox.BorderSizePixel   = 0
searchBox.ClearTextOnFocus  = false
searchBox.ZIndex    = 23
searchBox.Parent    = header
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)
local searchPad = Instance.new("UIPadding", searchBox)
searchPad.PaddingLeft = UDim.new(0, 6)

local closeBtn      = Instance.new("TextButton")
closeBtn.Size       = UDim2.fromOffset(30, 30)
closeBtn.Position   = UDim2.new(1, -40, 0.5, -15)
closeBtn.Text       = "✕"
closeBtn.TextSize   = 16
closeBtn.Font       = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.fromRGB(220, 120, 120)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 40)
closeBtn.BorderSizePixel  = 0
closeBtn.ZIndex     = 23
closeBtn.Parent     = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- Barra de abas
local tabBar        = Instance.new("Frame")
tabBar.Size         = UDim2.new(1, 0, 0, 36)
tabBar.Position     = UDim2.fromOffset(0, 48)
tabBar.BackgroundColor3 = Color3.fromRGB(22, 16, 36)
tabBar.BorderSizePixel  = 0
tabBar.ZIndex       = 22
tabBar.Parent       = panel

local tabLayout     = Instance.new("UIListLayout", tabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder     = Enum.SortOrder.LayoutOrder
tabLayout.Padding       = UDim.new(0, 4)

local tabPad        = Instance.new("UIPadding", tabBar)
tabPad.PaddingLeft  = UDim.new(0, 8)
tabPad.PaddingTop   = UDim.new(0, 6)

-- Área de lista (scroll)
local listFrame     = Instance.new("ScrollingFrame")
listFrame.Name      = "ItemList"
listFrame.Size      = UDim2.new(1, -12, 1, -92)
listFrame.Position  = UDim2.fromOffset(6, 88)
listFrame.BackgroundTransparency = 1
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 4
listFrame.ScrollBarImageColor3 = Color3.fromRGB(120, 80, 180)
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.ZIndex    = 22
listFrame.Parent    = panel

local listLayout    = Instance.new("UIListLayout", listFrame)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding   = UDim.new(0, 3)

local listPad       = Instance.new("UIPadding", listFrame)
listPad.PaddingTop  = UDim.new(0, 4)

-- Toast (canto inferior direito)
local toast         = Instance.new("TextLabel")
toast.Name          = "AdminToast"
toast.Size          = UDim2.fromOffset(240, 36)
toast.Position      = UDim2.new(1, -250, 1, -50)
toast.Text          = ""
toast.TextSize      = 13
toast.Font          = Enum.Font.GothamBold
toast.TextColor3    = Color3.new(1, 1, 1)
toast.BackgroundColor3 = Color3.fromRGB(30, 22, 48)
toast.BackgroundTransparency = 0.1
toast.BorderSizePixel = 0
toast.Visible       = false
toast.ZIndex        = 30
toast.Parent        = screenGui
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 8)

-- ─────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────

local function showToast(msg: string)
	toast.Text    = msg
	toast.Visible = true
	task.delay(2, function()
		toast.Visible = false
	end)
end

local function updateCounter()
	local total, banned = 0, 0
	for _, cat in ipairs(CATEGORIES) do
		local list = catalogData[cat]
		if list then
			total += #list
			for _, item in ipairs(list) do
				if blacklistSet[item.id] then banned += 1 end
			end
		end
	end
	counterLbl.Text = string.format("Total: %d | Banidos: %d", total, banned)
end

-- ─────────────────────────────────────────────────────────────
-- Renderização de itens
-- ─────────────────────────────────────────────────────────────

local tabButtons = {}  -- { [catName] = TextButton }

local function clearList()
	for _, child in listFrame:GetChildren() do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function buildRow(item, catName, order)
	local isBanned  = blacklistSet[item.id] == true

	local row       = Instance.new("Frame")
	row.Name        = "Row_" .. tostring(item.id)
	row.Size        = UDim2.new(1, -8, 0, 48)
	row.BackgroundColor3 = isBanned
		and Color3.fromRGB(60, 20, 24)
		or  Color3.fromRGB(28, 22, 42)
	row.BorderSizePixel = 0
	row.LayoutOrder = isBanned and (order + 10000) or order
	row.ZIndex      = 23
	row.Parent      = listFrame
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

	-- Thumbnail
	local thumb     = Instance.new("ImageLabel")
	thumb.Size      = UDim2.fromOffset(40, 40)
	thumb.Position  = UDim2.fromOffset(4, 4)
	thumb.Image     = string.format("rbxthumb://type=Asset&id=%d&w=100&h=100", item.id)
	thumb.BackgroundColor3 = Color3.fromRGB(14, 10, 22)
	thumb.BorderSizePixel  = 0
	thumb.ZIndex    = 24
	thumb.Parent    = row
	Instance.new("UICorner", thumb).CornerRadius = UDim.new(0, 4)

	-- Nome
	local nameLbl   = Instance.new("TextLabel")
	nameLbl.Size    = UDim2.new(0.38, 0, 0.55, 0)
	nameLbl.Position= UDim2.fromOffset(50, 2)
	nameLbl.Text    = item.name:sub(1, 30) .. (item.name:len() > 30 and "…" or "")
	nameLbl.TextSize = 12
	nameLbl.Font    = Enum.Font.Gotham
	nameLbl.TextColor3 = Color3.new(1, 1, 1)
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
	nameLbl.ZIndex  = 24
	nameLbl.Parent  = row

	-- Preço
	local priceLbl  = Instance.new("TextLabel")
	priceLbl.Size   = UDim2.new(0.38, 0, 0.4, 0)
	priceLbl.Position = UDim2.new(0, 50, 0.55, 0)
	priceLbl.Text   = string.format("💰 %d  •  ID: %d", item.price, item.id)
	priceLbl.TextSize = 10
	priceLbl.Font   = Enum.Font.Gotham
	priceLbl.TextColor3 = Color3.fromRGB(180, 155, 210)
	priceLbl.TextXAlignment = Enum.TextXAlignment.Left
	priceLbl.BackgroundTransparency = 1
	priceLbl.ZIndex = 24
	priceLbl.Parent = row

	-- Badge de status
	local badge     = Instance.new("TextLabel")
	badge.Name      = "StatusBadge"
	badge.Size      = UDim2.fromOffset(70, 22)
	badge.Position  = UDim2.new(1, -165, 0.5, -11)
	badge.Text      = isBanned and "🚫 Banido" or "✅ Ativo"
	badge.TextSize  = 11
	badge.Font      = Enum.Font.GothamBold
	badge.TextColor3 = isBanned and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 220, 120)
	badge.BackgroundColor3 = isBanned and Color3.fromRGB(80, 20, 24) or Color3.fromRGB(20, 60, 30)
	badge.BorderSizePixel  = 0
	badge.ZIndex    = 24
	badge.Parent    = row
	Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)

	-- Botão ação
	local actionBtn = Instance.new("TextButton")
	actionBtn.Name  = "ActionBtn"
	actionBtn.Size  = UDim2.fromOffset(82, 26)
	actionBtn.Position = UDim2.new(1, -88, 0.5, -13)
	actionBtn.Text  = isBanned and "✅ Restaurar" or "🚫 Banir"
	actionBtn.TextSize  = 11
	actionBtn.Font      = Enum.Font.GothamBold
	actionBtn.TextColor3 = Color3.new(1, 1, 1)
	actionBtn.BackgroundColor3 = isBanned
		and Color3.fromRGB(40, 130, 60)
		or  Color3.fromRGB(160, 40, 40)
	actionBtn.BorderSizePixel  = 0
	actionBtn.ZIndex = 24
	actionBtn.Parent = row
	Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 5)

	-- Ação de ban/unban
	actionBtn.Activated:Connect(function()
		if pendingActions[item.id] then return end
		pendingActions[item.id] = true
		actionBtn.Text    = "..."
		actionBtn.Active  = false

		if isBanned then
			UnbanItemEvent:FireServer(item.id)
		else
			BanItemEvent:FireServer(item.id)
		end
	end)

	return row
end

local function renderTab(catName: string)
	clearList()
	loadedTabs[catName] = true

	local items = catalogData[catName]
	if not items then return end

	local query = searchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")

	-- Separa ativos e banidos para ordenar
	local active, banned = {}, {}
	for i, item in ipairs(items) do
		local matchSearch = query == ""
			or item.name:lower():find(query, 1, true)
			or tostring(item.id):find(query, 1, true)
		if matchSearch then
			if blacklistSet[item.id] then
				table.insert(banned, { item = item, order = i })
			else
				table.insert(active, { item = item, order = i })
			end
		end
	end

	local order = 1
	for _, entry in ipairs(active) do
		buildRow(entry.item, catName, order)
		order += 1
	end
	for _, entry in ipairs(banned) do
		buildRow(entry.item, catName, order + 10000)
		order += 1
	end
end

-- ─────────────────────────────────────────────────────────────
-- Abas
-- ─────────────────────────────────────────────────────────────

local function selectTab(catName: string)
	currentTab = catName
	for name, btn in pairs(tabButtons) do
		btn.BackgroundColor3 = (name == catName)
			and Color3.fromRGB(90, 50, 160)
			or  Color3.fromRGB(38, 28, 58)
	end
	renderTab(catName)
end

for i, cat in ipairs(CATEGORIES) do
	local btn       = Instance.new("TextButton")
	btn.Name        = cat
	btn.Size        = UDim2.fromOffset(80, 24)
	btn.Text        = cat
	btn.TextSize    = 11
	btn.Font        = Enum.Font.GothamBold
	btn.TextColor3  = Color3.new(1, 1, 1)
	btn.BackgroundColor3 = Color3.fromRGB(38, 28, 58)
	btn.BorderSizePixel  = 0
	btn.LayoutOrder = i
	btn.ZIndex      = 23
	btn.Parent      = tabBar
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

	tabButtons[cat] = btn
	btn.Activated:Connect(function() selectTab(cat) end)
end

-- ─────────────────────────────────────────────────────────────
-- Atualiza uma row em tempo real após confirmação do servidor
-- ─────────────────────────────────────────────────────────────

BanConfirmEvent.OnClientEvent:Connect(function(itemId: number, isBanned: boolean)
	pendingActions[itemId] = nil

	if isBanned then
		blacklistSet[itemId] = true
	else
		blacklistSet[itemId] = nil
	end

	updateCounter()

	local action = isBanned and "banido" or "restaurado"
	showToast(string.format("Item %d %s ✔", itemId, action))

	-- Re-renderiza a aba atual se o item pertencer a ela
	if currentTab then
		local items = catalogData[currentTab]
		if items then
			for _, item in ipairs(items) do
				if item.id == itemId then
					renderTab(currentTab)
					return
				end
			end
		end
	end
end)

-- ─────────────────────────────────────────────────────────────
-- Busca em tempo real
-- ─────────────────────────────────────────────────────────────

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	if currentTab then renderTab(currentTab) end
end)

-- ─────────────────────────────────────────────────────────────
-- Abrir / fechar painel
-- ─────────────────────────────────────────────────────────────

local panelOpen = false

local function openPanel()
	if panelOpen then return end
	panelOpen      = true
	overlay.Visible = true
	panel.Visible   = true

	-- Busca dados do servidor apenas na primeira abertura
	if next(catalogData) == nil then
		local result = GetCatalogFunc:InvokeServer()
		if result then
			catalogData  = result.catalog or {}
			blacklistSet = {}
			for _, id in ipairs(result.blacklist or {}) do
				blacklistSet[id] = true
			end
			updateCounter()
			selectTab(CATEGORIES[1])
		else
			showToast("Sem permissão de admin.")
			panelOpen = false
			overlay.Visible = false
			panel.Visible   = false
		end
	else
		if currentTab then
			renderTab(currentTab)
		else
			selectTab(CATEGORIES[1])
		end
	end
end

local function closePanel()
	panelOpen       = false
	overlay.Visible = false
	panel.Visible   = false
end

openBtn.Activated:Connect(openPanel)
closeBtn.Activated:Connect(closePanel)
overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		closePanel()
	end
end)
