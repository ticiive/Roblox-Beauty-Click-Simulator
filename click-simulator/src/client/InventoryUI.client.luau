local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes              = ReplicatedStorage:WaitForChild("Remotes")
local InventoryUpdateEvent = Remotes:WaitForChild("InventoryUpdateEvent")
local EquipItemEvent       = Remotes:WaitForChild("EquipItemEvent")
local UnequipItemEvent     = Remotes:WaitForChild("UnequipItemEvent")
local RecolorItemEvent     = Remotes:WaitForChild("RecolorItemEvent")

-- ─────────────────────────────────────────────────────────────
-- Estado local
-- ─────────────────────────────────────────────────────────────

local currentInventory = {}
local currentEquipped  = {}
local painelAberto     = false
local abaAtual         = 1   -- 1=Equipados 2=Coleção
local recolorTargetId  = nil

-- ─────────────────────────────────────────────────────────────
-- Paleta
-- ─────────────────────────────────────────────────────────────

local C_FUNDO    = Color3.fromRGB(10, 6, 16)
local C_PAINEL   = Color3.fromRGB(18, 12, 28)
local C_OURO     = Color3.fromRGB(212, 175, 55)
local C_TEXTO    = Color3.fromRGB(240, 230, 215)
local C_CINZA    = Color3.fromRGB(55, 48, 68)
local C_VERDE    = Color3.fromRGB(60, 190, 120)
local C_VERM     = Color3.fromRGB(200, 60, 60)
local C_BOTAO    = Color3.fromRGB(22, 14, 36)
local C_ABA_ON   = Color3.fromRGB(35, 24, 55)
local C_ABA_OFF  = Color3.fromRGB(16, 10, 28)
local C_SUBTEXTO = Color3.fromRGB(160, 148, 130)

local PRESET_COLORS = {
	Color3.fromRGB(255, 255, 255), Color3.fromRGB(0,   0,   0  ),
	Color3.fromRGB(200, 50,  50 ), Color3.fromRGB(50,  150, 220),
	Color3.fromRGB(60,  190, 80 ), Color3.fromRGB(240, 200, 50 ),
	Color3.fromRGB(200, 100, 200), Color3.fromRGB(240, 140, 50 ),
	Color3.fromRGB(50,  200, 200), Color3.fromRGB(220, 150, 100),
	Color3.fromRGB(100, 100, 220), Color3.fromRGB(230, 180, 220),
}

-- ─────────────────────────────────────────────────────────────
-- Utilitários
-- ─────────────────────────────────────────────────────────────

local function addCorner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = inst
end

local function addStroke(inst, thickness, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1.5
	s.Color     = color or C_OURO
	s.Parent    = inst
end

local function isEquipped(itemId)
	for _, ids in currentEquipped do
		for _, id in ids do
			if id == itemId then return true end
		end
	end
	return false
end

local function clearCards(scroll)
	for _, child in ipairs(scroll:GetChildren()) do
		if not (child:IsA("UIGridLayout") or child:IsA("UIPadding")) then
			child:Destroy()
		end
	end
end

-- ─────────────────────────────────────────────────────────────
-- ScreenGui
-- ─────────────────────────────────────────────────────────────

local gui = Instance.new("ScreenGui")
gui.Name           = "InventoryUI"
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = playerGui

-- ─────────────────────────────────────────────────────────────
-- Botão toggle 👕
-- ─────────────────────────────────────────────────────────────

local btnInv = Instance.new("TextButton")
btnInv.Size             = UDim2.new(0, 72, 0, 72)
btnInv.Position         = UDim2.new(1, -88, 1, -168)
btnInv.BackgroundColor3 = Color3.fromRGB(22, 14, 36)
btnInv.BorderSizePixel  = 0
btnInv.Text             = "👕"
btnInv.TextSize         = 36
btnInv.Font             = Enum.Font.GothamBold
btnInv.Parent           = gui
addCorner(btnInv, 18)
addStroke(btnInv, 2, C_OURO)

local pulso = TweenService:Create(btnInv,
	TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Size=UDim2.new(0, 78, 0, 78), Position=UDim2.new(1, -91, 1, -171) })
pulso:Play()

-- ─────────────────────────────────────────────────────────────
-- Overlay
-- ─────────────────────────────────────────────────────────────

local overlay = Instance.new("Frame")
overlay.Size                   = UDim2.fromScale(1, 1)
overlay.BackgroundColor3       = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.Visible                = false
overlay.ZIndex                 = 10
overlay.Parent                 = gui

-- ─────────────────────────────────────────────────────────────
-- Painel principal 540 × 460
-- ─────────────────────────────────────────────────────────────

local panel = Instance.new("Frame")
panel.Size            = UDim2.fromOffset(540, 460)
panel.AnchorPoint     = Vector2.new(0.5, 0.5)
panel.Position        = UDim2.fromScale(0.5, 0.5)
panel.BackgroundColor3 = C_FUNDO
panel.BorderSizePixel = 0
panel.Visible         = false
panel.ZIndex          = 11
panel.Parent          = gui
addCorner(panel, 14)
addStroke(panel, 2.5, C_OURO)

-- Título
local titleLbl = Instance.new("TextLabel")
titleLbl.Text                  = "✦  INVENTÁRIO  ✦"
titleLbl.TextSize              = 18
titleLbl.Font                  = Enum.Font.GothamBold
titleLbl.BackgroundTransparency = 1
titleLbl.TextColor3            = C_OURO
titleLbl.Size                  = UDim2.new(1, -50, 0, 36)
titleLbl.Position              = UDim2.new(0, 0, 0, 12)
titleLbl.TextXAlignment        = Enum.TextXAlignment.Center
titleLbl.ZIndex                = 12
titleLbl.Parent                = panel

-- Botão fechar
local closeBtn = Instance.new("TextButton")
closeBtn.Text             = "✕"
closeBtn.TextSize         = 16
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextColor3       = C_SUBTEXTO
closeBtn.Size             = UDim2.fromOffset(32, 32)
closeBtn.AnchorPoint      = Vector2.new(1, 0)
closeBtn.Position         = UDim2.new(1, -8, 0, 8)
closeBtn.BackgroundTransparency = 1
closeBtn.ZIndex           = 12
closeBtn.Parent           = panel

-- Linha decorativa
local lDecor = Instance.new("Frame")
lDecor.Size             = UDim2.new(0.7, 0, 0, 1)
lDecor.Position         = UDim2.new(0.15, 0, 0, 46)
lDecor.BackgroundColor3 = C_OURO
lDecor.BackgroundTransparency = 0.4
lDecor.BorderSizePixel  = 0
lDecor.ZIndex           = 12
lDecor.Parent           = panel
addCorner(lDecor, 99)

-- Abas
local tabNames = { "✨ Equipados", "📦 Coleção" }
local tabBtns  = {}
local TAB_H    = 32

for i, name in ipairs(tabNames) do
	local tb = Instance.new("TextButton")
	tb.Size             = UDim2.new(0, 120, 0, TAB_H)
	tb.Position         = UDim2.new(0, 16 + (i - 1) * 130, 0, 52)
	tb.BackgroundColor3 = (i == 1) and C_ABA_ON or C_ABA_OFF
	tb.BorderSizePixel  = 0
	tb.Text             = name
	tb.TextColor3       = (i == 1) and C_OURO or C_SUBTEXTO
	tb.TextSize         = 13
	tb.Font             = Enum.Font.GothamBold
	tb.ZIndex           = 12
	tb.Parent           = panel
	addCorner(tb, 8)
	addStroke(tb, 1, C_OURO)
	tabBtns[i] = tb
end

-- ─────────────────────────────────────────────────────────────
-- Scroll areas
-- ─────────────────────────────────────────────────────────────

local SCROLL_Y = 52 + TAB_H + 8
local SCROLL_H = 460 - SCROLL_Y - 12

local function makeScroll(visible)
	local sf = Instance.new("ScrollingFrame")
	sf.Size              = UDim2.new(1, -16, 0, SCROLL_H)
	sf.Position          = UDim2.new(0, 8, 0, SCROLL_Y)
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel   = 0
	sf.ScrollBarThickness = 4
	sf.ScrollBarImageColor3 = C_OURO
	sf.CanvasSize        = UDim2.new(0, 0, 0, 0)
	sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sf.Visible           = visible
	sf.ZIndex            = 12
	sf.Parent            = panel

	local grid = Instance.new("UIGridLayout")
	grid.CellSize     = UDim2.new(0, 150, 0, 200)
	grid.CellPadding  = UDim2.new(0, 10, 0, 10)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.Parent       = sf

	local pad = Instance.new("UIPadding")
	pad.PaddingTop    = UDim.new(0, 6)
	pad.PaddingLeft   = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.Parent        = sf

	return sf
end

local scrollEquipados = makeScroll(true)
local scrollColecao   = makeScroll(false)

-- ─────────────────────────────────────────────────────────────
-- Color picker overlay
-- ─────────────────────────────────────────────────────────────

local colorPicker = Instance.new("Frame")
colorPicker.Size            = UDim2.fromOffset(224, 190)
colorPicker.AnchorPoint     = Vector2.new(0.5, 0.5)
colorPicker.Position        = UDim2.fromScale(0.5, 0.5)
colorPicker.BackgroundColor3 = C_FUNDO
colorPicker.BorderSizePixel = 0
colorPicker.Visible         = false
colorPicker.ZIndex          = 20
colorPicker.Parent          = gui
addCorner(colorPicker, 12)
addStroke(colorPicker, 2, C_OURO)

local cpTitle = Instance.new("TextLabel")
cpTitle.Text                  = "Escolher Cor"
cpTitle.TextSize              = 14
cpTitle.Font                  = Enum.Font.GothamBold
cpTitle.BackgroundTransparency = 1
cpTitle.TextColor3            = C_OURO
cpTitle.Size                  = UDim2.new(1, -36, 0, 30)
cpTitle.Position              = UDim2.new(0, 0, 0, 8)
cpTitle.TextXAlignment        = Enum.TextXAlignment.Center
cpTitle.ZIndex                = 21
cpTitle.Parent                = colorPicker

local cpClose = Instance.new("TextButton")
cpClose.Text             = "✕"
cpClose.TextSize         = 13
cpClose.Font             = Enum.Font.GothamBold
cpClose.TextColor3       = C_SUBTEXTO
cpClose.Size             = UDim2.fromOffset(26, 26)
cpClose.AnchorPoint      = Vector2.new(1, 0)
cpClose.Position         = UDim2.new(1, -6, 0, 6)
cpClose.BackgroundTransparency = 1
cpClose.ZIndex           = 21
cpClose.Parent           = colorPicker

local cpGrid = Instance.new("Frame")
cpGrid.Size                   = UDim2.new(1, -20, 1, -46)
cpGrid.Position               = UDim2.new(0, 10, 0, 42)
cpGrid.BackgroundTransparency = 1
cpGrid.ZIndex                 = 21
cpGrid.Parent                 = colorPicker

local cpLayout = Instance.new("UIGridLayout")
cpLayout.CellSize     = UDim2.new(0, 36, 0, 36)
cpLayout.CellPadding  = UDim2.new(0, 6, 0, 6)
cpLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
cpLayout.Parent       = cpGrid

for _, col in ipairs(PRESET_COLORS) do
	local cb = Instance.new("TextButton")
	cb.Size             = UDim2.new(0, 36, 0, 36)
	cb.BackgroundColor3 = col
	cb.BorderSizePixel  = 0
	cb.Text             = ""
	cb.ZIndex           = 22
	cb.Parent           = cpGrid
	addCorner(cb, 6)
	addStroke(cb, 1, Color3.new(1, 1, 1))

	local capCol = col
	cb.Activated:Connect(function()
		if recolorTargetId then
			RecolorItemEvent:FireServer(recolorTargetId, capCol)
		end
		colorPicker.Visible = false
		recolorTargetId = nil
	end)
end

cpClose.Activated:Connect(function()
	colorPicker.Visible = false
	recolorTargetId = nil
end)

-- ─────────────────────────────────────────────────────────────
-- Cria um card de item
-- ─────────────────────────────────────────────────────────────

local function criarCard(parent, itemId, name, category, equipped)
	local card = Instance.new("Frame")
	card.BackgroundColor3 = C_BOTAO
	card.BorderSizePixel  = 0
	card.ZIndex           = 13
	card.Parent           = parent
	addCorner(card, 10)
	addStroke(card, 1.5, equipped and C_OURO or C_CINZA)

	local thumb = Instance.new("ImageLabel")
	thumb.Size                = UDim2.new(1, -10, 0, 120)
	thumb.Position            = UDim2.new(0, 5, 0, 5)
	thumb.BackgroundColor3    = C_PAINEL
	thumb.BackgroundTransparency = 0
	thumb.ScaleType           = Enum.ScaleType.Fit
	thumb.Image               = string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", itemId)
	thumb.ZIndex              = 14
	thumb.Parent              = card
	addCorner(thumb, 8)

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Text                   = name
	nameLbl.TextSize               = 11
	nameLbl.Font                   = Enum.Font.GothamBold
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextColor3             = C_TEXTO
	nameLbl.Size                   = UDim2.new(1, -10, 0, 28)
	nameLbl.Position               = UDim2.new(0, 5, 0, 128)
	nameLbl.TextWrapped            = true
	nameLbl.TextXAlignment         = Enum.TextXAlignment.Center
	nameLbl.ZIndex                 = 14
	nameLbl.Parent                 = card

	local catLbl = Instance.new("TextLabel")
	catLbl.Text                   = category or ""
	catLbl.TextSize               = 10
	catLbl.Font                   = Enum.Font.Gotham
	catLbl.BackgroundTransparency = 1
	catLbl.TextColor3             = C_SUBTEXTO
	catLbl.Size                   = UDim2.new(1, -10, 0, 14)
	catLbl.Position               = UDim2.new(0, 5, 0, 154)
	catLbl.TextXAlignment         = Enum.TextXAlignment.Center
	catLbl.ZIndex                 = 14
	catLbl.Parent                 = card

	return card
end

-- ─────────────────────────────────────────────────────────────
-- Populadores
-- ─────────────────────────────────────────────────────────────

local function populateEquipados()
	clearCards(scrollEquipados)

	local count = 0
	for category, ids in currentEquipped do
		for _, itemId in ids do
			count += 1
			local item = currentInventory[tostring(itemId)]
			local name = item and item.name or ("Item #" .. itemId)

			local card = criarCard(scrollEquipados, itemId, name, category, true)

			-- Shirt/Pants/TShirts: textura 2D, sem botão de cor
			local isClothing = (category == "Shirts" or category == "Pants" or category == "TShirts")
			local capId = itemId

			local unequipBtn = Instance.new("TextButton")
			unequipBtn.Text             = "✕ Tirar"
			unequipBtn.TextSize         = 10
			unequipBtn.Font             = Enum.Font.GothamBold
			unequipBtn.TextColor3       = Color3.new(1, 1, 1)
			unequipBtn.Size             = isClothing
				and UDim2.new(1, -6, 0, 22)
				or  UDim2.new(0.5, -4, 0, 22)
			unequipBtn.Position         = UDim2.new(0, 2, 1, -24)
			unequipBtn.BackgroundColor3 = C_VERM
			unequipBtn.BorderSizePixel  = 0
			unequipBtn.ZIndex           = 14
			unequipBtn.Parent           = card
			addCorner(unequipBtn, 6)
			unequipBtn.Activated:Connect(function()
				UnequipItemEvent:FireServer(capId)
			end)

			if not isClothing then
				local recolorBtn = Instance.new("TextButton")
				recolorBtn.Text             = "🎨"
				recolorBtn.TextSize         = 14
				recolorBtn.Font             = Enum.Font.GothamBold
				recolorBtn.TextColor3       = Color3.new(1, 1, 1)
				recolorBtn.Size             = UDim2.new(0.5, -4, 0, 22)
				recolorBtn.Position         = UDim2.new(0.5, 2, 1, -24)
				recolorBtn.BackgroundColor3 = C_CINZA
				recolorBtn.BorderSizePixel  = 0
				recolorBtn.ZIndex           = 14
				recolorBtn.Parent           = card
				addCorner(recolorBtn, 6)
				recolorBtn.Activated:Connect(function()
					recolorTargetId = capId
					colorPicker.Visible = true
				end)
			end
		end
	end

	if count == 0 then
		local empty = Instance.new("TextLabel")
		empty.Text                   = "Nenhum item equipado."
		empty.TextSize               = 14
		empty.Font                   = Enum.Font.Gotham
		empty.BackgroundTransparency = 1
		empty.TextColor3             = C_SUBTEXTO
		empty.Size                   = UDim2.new(1, 0, 0, 40)
		empty.TextXAlignment         = Enum.TextXAlignment.Center
		empty.ZIndex                 = 13
		empty.Parent                 = scrollEquipados
	end
end

local function populateColecao()
	clearCards(scrollColecao)

	local count = 0
	for _, item in currentInventory do
		count += 1
		local eq = isEquipped(item.id)
		local card = criarCard(scrollColecao, item.id, item.name, item.category, eq)

		local equipBtn = Instance.new("TextButton")
		equipBtn.Text             = eq and "✓ Equipado" or "Equipar"
		equipBtn.TextSize         = 11
		equipBtn.Font             = Enum.Font.GothamBold
		equipBtn.TextColor3       = Color3.new(1, 1, 1)
		equipBtn.Size             = UDim2.new(1, -10, 0, 22)
		equipBtn.Position         = UDim2.new(0, 5, 1, -24)
		equipBtn.BackgroundColor3 = eq and C_OURO or C_VERDE
		equipBtn.BorderSizePixel  = 0
		equipBtn.ZIndex           = 14
		equipBtn.Parent           = card
		addCorner(equipBtn, 6)

		if not eq then
			local capId = item.id
			equipBtn.Activated:Connect(function()
				EquipItemEvent:FireServer(capId)
			end)
		end
	end

	if count == 0 then
		local empty = Instance.new("TextLabel")
		empty.Text                   = "Inventário vazio.\nAbra caixas para ganhar itens!"
		empty.TextSize               = 14
		empty.Font                   = Enum.Font.Gotham
		empty.BackgroundTransparency = 1
		empty.TextColor3             = C_SUBTEXTO
		empty.Size                   = UDim2.new(1, 0, 0, 60)
		empty.TextXAlignment         = Enum.TextXAlignment.Center
		empty.TextWrapped            = true
		empty.ZIndex                 = 13
		empty.Parent                 = scrollColecao
	end
end

local function populateCurrentTab()
	if abaAtual == 1 then populateEquipados() else populateColecao() end
end

-- ─────────────────────────────────────────────────────────────
-- Troca de aba
-- ─────────────────────────────────────────────────────────────

local function switchTab(idx)
	abaAtual = idx
	for i, tb in ipairs(tabBtns) do
		tb.BackgroundColor3 = (i == idx) and C_ABA_ON or C_ABA_OFF
		tb.TextColor3       = (i == idx) and C_OURO   or C_SUBTEXTO
	end
	scrollEquipados.Visible = (idx == 1)
	scrollColecao.Visible   = (idx == 2)
	populateCurrentTab()
end

for i, tb in ipairs(tabBtns) do
	local capI = i
	tb.Activated:Connect(function() switchTab(capI) end)
end

-- ─────────────────────────────────────────────────────────────
-- Abrir / fechar
-- ─────────────────────────────────────────────────────────────

local function fecharPainel()
	TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(0, 0),
	}):Play()
	task.delay(0.22, function()
		overlay.Visible = false
		panel.Visible   = false
		painelAberto    = false
		task.delay(0.1, function() pulso:Play() end)
	end)
end

local function abrirPainel()
	painelAberto = true
	pulso:Cancel()
	btnInv.Size     = UDim2.new(0, 72, 0, 72)
	btnInv.Position = UDim2.new(1, -88, 1, -168)

	overlay.Visible = true
	panel.Visible   = true
	panel.Size      = UDim2.fromOffset(0, 0)

	TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(540, 460),
	}):Play()

	populateCurrentTab()
end

btnInv.Activated:Connect(function()
	if painelAberto then fecharPainel() else abrirPainel() end
end)

closeBtn.Activated:Connect(fecharPainel)

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		if not colorPicker.Visible then fecharPainel() end
	end
end)

-- ─────────────────────────────────────────────────────────────
-- Recebe update do servidor
-- ─────────────────────────────────────────────────────────────

InventoryUpdateEvent.OnClientEvent:Connect(function(inventory, equipped)
	currentInventory = inventory or {}
	currentEquipped  = equipped  or {}
	if painelAberto then populateCurrentTab() end
end)

print("[InventoryUI] Pronto.")
