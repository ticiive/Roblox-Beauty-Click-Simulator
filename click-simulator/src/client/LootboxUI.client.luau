local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui")

local Shared        = ReplicatedStorage:WaitForChild("Shared")
local LootboxConfig = require(Shared:WaitForChild("LootboxConfig"))

local Remotes            = ReplicatedStorage:WaitForChild("Remotes")
local OpenLootboxEvent   = Remotes:WaitForChild("OpenLootboxEvent")
local LootboxResultEvent = Remotes:WaitForChild("LootboxResultEvent")

-- ─────────────────────────────────────────────────────────────
-- Paleta
-- ─────────────────────────────────────────────────────────────

local C_FUNDO  = Color3.fromRGB(18, 12, 28)
local C_PAINEL = Color3.fromRGB(28, 20, 42)
local C_OURO   = Color3.fromRGB(212, 175, 55)
local C_TEXTO  = Color3.fromRGB(240, 230, 215)
local C_CINZA  = Color3.fromRGB(120, 110, 100)

-- ─────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────

local function makeLabel(parent, text, size, color, pos, anchor)
	local l = Instance.new("TextLabel")
	l.Text              = text
	l.TextSize          = size
	l.TextColor3        = color or C_TEXTO
	l.Font              = Enum.Font.GothamBold
	l.BackgroundTransparency = 1
	l.Size              = UDim2.fromScale(1, 0)
	l.AutomaticSize     = Enum.AutomaticSize.Y
	l.Position          = pos or UDim2.new(0, 0, 0, 0)
	l.AnchorPoint       = anchor or Vector2.new(0, 0)
	l.TextXAlignment    = Enum.TextXAlignment.Center
	l.Parent            = parent
	return l
end

local function stroke(parent, thickness, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 2
	s.Color     = color or C_OURO
	s.Parent    = parent
	return s
end

-- ─────────────────────────────────────────────────────────────
-- ScreenGui principal
-- ─────────────────────────────────────────────────────────────

local gui = Instance.new("ScreenGui")
gui.Name              = "LootboxGui"
gui.ResetOnSpawn      = false
gui.IgnoreGuiInset    = true
gui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
gui.Parent            = playerGui

-- ─────────────────────────────────────────────────────────────
-- Painel lateral: botões das caixas (esquerda, abaixo do stats)
-- Stats panel vai de y=12 até y=12+148=160; começamos em 172
-- ─────────────────────────────────────────────────────────────

local PANEL_W  = 140
local BTN_H    = 52
local BTN_GAP  = 6
local PANEL_H  = #LootboxConfig.Boxes * (BTN_H + BTN_GAP) - BTN_GAP + 16

local sidePanel = Instance.new("Frame")
sidePanel.Name            = "LootboxPanel"
sidePanel.Size            = UDim2.fromOffset(PANEL_W, PANEL_H)
sidePanel.Position        = UDim2.new(0, 12, 0, 172)
sidePanel.BackgroundColor3 = C_PAINEL
sidePanel.BorderSizePixel = 0
sidePanel.Parent          = gui
stroke(sidePanel, 1.5, C_OURO)

local uiPad = Instance.new("UIPadding")
uiPad.PaddingTop    = UDim.new(0, 8)
uiPad.PaddingBottom = UDim.new(0, 8)
uiPad.PaddingLeft   = UDim.new(0, 6)
uiPad.PaddingRight  = UDim.new(0, 6)
uiPad.Parent        = sidePanel

local uiList = Instance.new("UIListLayout")
uiList.FillDirection     = Enum.FillDirection.Vertical
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiList.Padding           = UDim.new(0, BTN_GAP)
uiList.Parent            = sidePanel

for _, box in LootboxConfig.Boxes do
	local btn = Instance.new("TextButton")
	btn.Name              = "Btn_" .. box.id
	btn.Size              = UDim2.new(1, 0, 0, BTN_H)
	btn.BackgroundColor3  = box.color
	btn.BorderSizePixel   = 0
	btn.Text              = ""
	btn.AutoButtonColor   = false
	btn.Parent            = sidePanel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent       = btn

	stroke(btn, 1, C_OURO)

	-- Emoji grande
	local emojiLbl = Instance.new("TextLabel")
	emojiLbl.Text              = box.emoji
	emojiLbl.TextSize          = 22
	emojiLbl.Font              = Enum.Font.GothamBold
	emojiLbl.BackgroundTransparency = 1
	emojiLbl.TextColor3        = Color3.new(1, 1, 1)
	emojiLbl.Size              = UDim2.new(1, 0, 0, 24)
	emojiLbl.Position          = UDim2.new(0, 0, 0, 4)
	emojiLbl.TextXAlignment    = Enum.TextXAlignment.Center
	emojiLbl.Parent            = btn

	-- Nome
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Text              = box.name
	nameLbl.TextSize          = 10
	nameLbl.Font              = Enum.Font.GothamBold
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextColor3        = Color3.new(1, 1, 1)
	nameLbl.Size              = UDim2.new(1, 0, 0, 13)
	nameLbl.Position          = UDim2.new(0, 0, 0, 28)
	nameLbl.TextXAlignment    = Enum.TextXAlignment.Center
	nameLbl.Parent            = btn

	-- Preço
	local priceLbl = Instance.new("TextLabel")
	priceLbl.Text              = "💰 " .. tostring(box.cost)
	priceLbl.TextSize          = 10
	priceLbl.Font              = Enum.Font.Gotham
	priceLbl.BackgroundTransparency = 1
	priceLbl.TextColor3        = C_OURO
	priceLbl.Size              = UDim2.new(1, 0, 0, 12)
	priceLbl.Position          = UDim2.new(0, 0, 0, 40)
	priceLbl.TextXAlignment    = Enum.TextXAlignment.Center
	priceLbl.Parent            = btn

	-- Hover
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = btn.BackgroundColor3:Lerp(Color3.new(1,1,1), 0.15) }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = box.color }):Play()
	end)

	btn.Activated:Connect(function()
		OpenLootboxEvent:FireServer(box.id)
	end)
end

-- ─────────────────────────────────────────────────────────────
-- Popup de resultado
-- ─────────────────────────────────────────────────────────────

local overlay = Instance.new("Frame")
overlay.Name              = "Overlay"
overlay.Size              = UDim2.fromScale(1, 1)
overlay.BackgroundColor3  = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.45
overlay.Visible           = false
overlay.ZIndex            = 10
overlay.Parent            = gui

local popup = Instance.new("Frame")
popup.Name             = "ResultPopup"
popup.Size             = UDim2.fromOffset(320, 380)
popup.AnchorPoint      = Vector2.new(0.5, 0.5)
popup.Position         = UDim2.fromScale(0.5, 0.5)
popup.BackgroundColor3 = C_FUNDO
popup.BorderSizePixel  = 0
popup.Visible          = false
popup.ZIndex           = 11
popup.Parent           = gui

local popupCorner = Instance.new("UICorner")
popupCorner.CornerRadius = UDim.new(0, 12)
popupCorner.Parent       = popup

stroke(popup, 2.5, C_OURO)

-- Título do popup
local popTitle = Instance.new("TextLabel")
popTitle.Name              = "Title"
popTitle.Text              = "🎉 VOCÊ GANHOU!"
popTitle.TextSize          = 20
popTitle.Font              = Enum.Font.GothamBold
popTitle.BackgroundTransparency = 1
popTitle.TextColor3        = C_OURO
popTitle.Size              = UDim2.new(1, 0, 0, 36)
popTitle.Position          = UDim2.new(0, 0, 0, 18)
popTitle.TextXAlignment    = Enum.TextXAlignment.Center
popTitle.ZIndex            = 12
popTitle.Parent            = popup

-- Subtítulo (nome da caixa)
local popBox = Instance.new("TextLabel")
popBox.Name              = "BoxName"
popBox.Text              = ""
popBox.TextSize          = 13
popBox.Font              = Enum.Font.Gotham
popBox.BackgroundTransparency = 1
popBox.TextColor3        = C_CINZA
popBox.Size              = UDim2.new(1, 0, 0, 20)
popBox.Position          = UDim2.new(0, 0, 0, 52)
popBox.TextXAlignment    = Enum.TextXAlignment.Center
popBox.ZIndex            = 12
popBox.Parent            = popup

-- Thumbnail do item
local thumbFrame = Instance.new("Frame")
thumbFrame.Size              = UDim2.fromOffset(180, 180)
thumbFrame.AnchorPoint       = Vector2.new(0.5, 0)
thumbFrame.Position          = UDim2.new(0.5, 0, 0, 78)
thumbFrame.BackgroundColor3  = C_PAINEL
thumbFrame.BorderSizePixel   = 0
thumbFrame.ZIndex            = 12
thumbFrame.Parent            = popup

local thumbCorner = Instance.new("UICorner")
thumbCorner.CornerRadius = UDim.new(0, 10)
thumbCorner.Parent       = thumbFrame

stroke(thumbFrame, 1.5, C_OURO)

local thumbImg = Instance.new("ImageLabel")
thumbImg.Name             = "Thumb"
thumbImg.Size             = UDim2.fromScale(1, 1)
thumbImg.BackgroundTransparency = 1
thumbImg.ScaleType        = Enum.ScaleType.Fit
thumbImg.Image            = ""
thumbImg.ZIndex           = 13
thumbImg.Parent           = thumbFrame

-- Nome do item
local popItemName = Instance.new("TextLabel")
popItemName.Name              = "ItemName"
popItemName.Text              = ""
popItemName.TextSize          = 16
popItemName.Font              = Enum.Font.GothamBold
popItemName.BackgroundTransparency = 1
popItemName.TextColor3        = C_TEXTO
popItemName.Size              = UDim2.new(1, -24, 0, 0)
popItemName.AutomaticSize     = Enum.AutomaticSize.Y
popItemName.Position          = UDim2.new(0, 12, 0, 268)
popItemName.TextXAlignment    = Enum.TextXAlignment.Center
popItemName.TextWrapped       = true
popItemName.ZIndex            = 12
popItemName.Parent            = popup

-- Botão fechar
local closeBtn = Instance.new("TextButton")
closeBtn.Name              = "Close"
closeBtn.Text              = "✕ Fechar"
closeBtn.TextSize          = 14
closeBtn.Font              = Enum.Font.GothamBold
closeBtn.TextColor3        = Color3.new(1, 1, 1)
closeBtn.Size              = UDim2.new(1, -48, 0, 38)
closeBtn.AnchorPoint       = Vector2.new(0.5, 0)
closeBtn.Position          = UDim2.new(0.5, 0, 0, 324)
closeBtn.BackgroundColor3  = C_OURO
closeBtn.BorderSizePixel   = 0
closeBtn.AutoButtonColor   = false
closeBtn.ZIndex            = 12
closeBtn.Parent            = popup

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent       = closeBtn

-- ─────────────────────────────────────────────────────────────
-- Animação do popup
-- ─────────────────────────────────────────────────────────────

local function abrirPopup(result)
	popBox.Text      = result.boxName
	popItemName.Text = result.itemName

	-- Thumbnail via rbxthumb
	thumbImg.Image = string.format("rbxthumb://type=Asset&id=%d&w=420&h=420", result.itemId)

	overlay.Visible = true
	popup.Visible   = true
	popup.Size      = UDim2.fromOffset(0, 0)

	TweenService:Create(popup, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(320, 380),
	}):Play()
end

local function fecharPopup()
	local t = TweenService:Create(popup, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(0, 0),
	})
	t:Play()
	t.Completed:Connect(function()
		overlay.Visible = false
		popup.Visible   = false
	end)
end

closeBtn.Activated:Connect(fecharPopup)
overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		fecharPopup()
	end
end)

-- ─────────────────────────────────────────────────────────────
-- Recebe resultado do servidor
-- ─────────────────────────────────────────────────────────────

LootboxResultEvent.OnClientEvent:Connect(function(result)
	abrirPopup(result)
end)

print("[LootboxUI] Pronto.")
