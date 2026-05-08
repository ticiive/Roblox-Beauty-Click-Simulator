local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared        = ReplicatedStorage:WaitForChild("Shared")
local LootboxConfig = require(Shared:WaitForChild("LootboxConfig"))

local Remotes                    = ReplicatedStorage:WaitForChild("Remotes")
local RequestPurchaseConfirmEvent = Remotes:WaitForChild("RequestPurchaseConfirmEvent")
local ConfirmPurchaseEvent        = Remotes:WaitForChild("ConfirmPurchaseEvent")
local LootboxResultEvent          = Remotes:WaitForChild("LootboxResultEvent")

local C_FUNDO  = Color3.fromRGB(18, 12, 28)
local C_PAINEL = Color3.fromRGB(28, 20, 42)
local C_OURO   = Color3.fromRGB(212, 175, 55)
local C_TEXTO  = Color3.fromRGB(240, 230, 215)
local C_CINZA  = Color3.fromRGB(120, 110, 100)
local C_VERDE  = Color3.fromRGB(55, 175, 75)
local C_VERM   = Color3.fromRGB(200, 55, 55)

local function addCorner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = parent
end

local function addStroke(parent, thickness, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 2
	s.Color     = color or C_OURO
	s.Parent    = parent
end

local gui = Instance.new("ScreenGui")
gui.Name           = "PurchaseConfirmGui"
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = playerGui

-- ─────────────────────────────────────────────────────────────
-- Popup de confirmação de compra
-- ─────────────────────────────────────────────────────────────

local confirmOverlay = Instance.new("Frame")
confirmOverlay.Size                   = UDim2.fromScale(1, 1)
confirmOverlay.BackgroundColor3       = Color3.new(0, 0, 0)
confirmOverlay.BackgroundTransparency = 0.5
confirmOverlay.Visible                = false
confirmOverlay.ZIndex                 = 10
confirmOverlay.Parent                 = gui

local confirmPopup = Instance.new("Frame")
confirmPopup.Size            = UDim2.fromOffset(320, 210)
confirmPopup.AnchorPoint     = Vector2.new(0.5, 0.5)
confirmPopup.Position        = UDim2.fromScale(0.5, 0.5)
confirmPopup.BackgroundColor3 = C_FUNDO
confirmPopup.BorderSizePixel = 0
confirmPopup.Visible         = false
confirmPopup.ZIndex          = 11
confirmPopup.Parent          = gui
addCorner(confirmPopup, 12)
addStroke(confirmPopup, 2.5, C_OURO)

local confirmTitle = Instance.new("TextLabel")
confirmTitle.Text                  = "Confirmar Compra"
confirmTitle.TextSize              = 18
confirmTitle.Font                  = Enum.Font.GothamBold
confirmTitle.BackgroundTransparency = 1
confirmTitle.TextColor3            = C_OURO
confirmTitle.Size                  = UDim2.new(1, 0, 0, 30)
confirmTitle.Position              = UDim2.new(0, 0, 0, 18)
confirmTitle.TextXAlignment        = Enum.TextXAlignment.Center
confirmTitle.ZIndex                = 12
confirmTitle.Parent                = confirmPopup

local confirmDesc = Instance.new("TextLabel")
confirmDesc.Text                   = ""
confirmDesc.TextSize               = 14
confirmDesc.Font                   = Enum.Font.Gotham
confirmDesc.BackgroundTransparency = 1
confirmDesc.TextColor3             = C_TEXTO
confirmDesc.Size                   = UDim2.new(1, -24, 0, 50)
confirmDesc.Position               = UDim2.new(0, 12, 0, 62)
confirmDesc.TextXAlignment         = Enum.TextXAlignment.Center
confirmDesc.TextWrapped            = true
confirmDesc.ZIndex                 = 12
confirmDesc.Parent                 = confirmPopup

local simBtn = Instance.new("TextButton")
simBtn.Text             = "✓  Sim, comprar"
simBtn.TextSize         = 14
simBtn.Font             = Enum.Font.GothamBold
simBtn.TextColor3       = Color3.new(1, 1, 1)
simBtn.Size             = UDim2.new(0.45, 0, 0, 42)
simBtn.AnchorPoint      = Vector2.new(0, 0)
simBtn.Position         = UDim2.new(0.04, 0, 0, 150)
simBtn.BackgroundColor3 = C_VERDE
simBtn.BorderSizePixel  = 0
simBtn.AutoButtonColor  = false
simBtn.ZIndex           = 12
simBtn.Parent           = confirmPopup
addCorner(simBtn, 8)

local naoBtn = Instance.new("TextButton")
naoBtn.Text             = "✕  Cancelar"
naoBtn.TextSize         = 14
naoBtn.Font             = Enum.Font.GothamBold
naoBtn.TextColor3       = Color3.new(1, 1, 1)
naoBtn.Size             = UDim2.new(0.45, 0, 0, 42)
naoBtn.AnchorPoint      = Vector2.new(1, 0)
naoBtn.Position         = UDim2.new(0.96, 0, 0, 150)
naoBtn.BackgroundColor3 = C_VERM
naoBtn.BorderSizePixel  = 0
naoBtn.AutoButtonColor  = false
naoBtn.ZIndex           = 12
naoBtn.Parent           = confirmPopup
addCorner(naoBtn, 8)

local pendingBoxId = nil

local function fecharConfirm()
	TweenService:Create(confirmPopup, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(0, 0),
	}):Play()
	task.delay(0.2, function()
		confirmOverlay.Visible = false
		confirmPopup.Visible   = false
		pendingBoxId           = nil
	end)
end

local function abrirConfirm(boxId)
	local box = LootboxConfig.getBoxById(boxId)
	if not box then return end

	pendingBoxId     = boxId
	confirmDesc.Text = box.emoji .. "  " .. box.name .. "\nCusto: 💰 " .. tostring(box.cost)

	confirmOverlay.Visible = true
	confirmPopup.Visible   = true
	confirmPopup.Size      = UDim2.fromOffset(0, 0)

	TweenService:Create(confirmPopup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(320, 210),
	}):Play()
end

simBtn.Activated:Connect(function()
	if pendingBoxId then
		ConfirmPurchaseEvent:FireServer(pendingBoxId)
	end
	fecharConfirm()
end)

naoBtn.Activated:Connect(fecharConfirm)

RequestPurchaseConfirmEvent.OnClientEvent:Connect(abrirConfirm)

-- ─────────────────────────────────────────────────────────────
-- Popup de resultado (exibido ~3.5s depois de confirmar)
-- ─────────────────────────────────────────────────────────────

local resultOverlay = Instance.new("Frame")
resultOverlay.Size                   = UDim2.fromScale(1, 1)
resultOverlay.BackgroundColor3       = Color3.new(0, 0, 0)
resultOverlay.BackgroundTransparency = 0.45
resultOverlay.Visible                = false
resultOverlay.ZIndex                 = 20
resultOverlay.Parent                 = gui

local resultPopup = Instance.new("Frame")
resultPopup.Size            = UDim2.fromOffset(320, 380)
resultPopup.AnchorPoint     = Vector2.new(0.5, 0.5)
resultPopup.Position        = UDim2.fromScale(0.5, 0.5)
resultPopup.BackgroundColor3 = C_FUNDO
resultPopup.BorderSizePixel = 0
resultPopup.Visible         = false
resultPopup.ZIndex          = 21
resultPopup.Parent          = gui
addCorner(resultPopup, 12)
addStroke(resultPopup, 2.5, C_OURO)

local resTitle = Instance.new("TextLabel")
resTitle.Text                  = "🎉 VOCÊ GANHOU!"
resTitle.TextSize              = 20
resTitle.Font                  = Enum.Font.GothamBold
resTitle.BackgroundTransparency = 1
resTitle.TextColor3            = C_OURO
resTitle.Size                  = UDim2.new(1, 0, 0, 36)
resTitle.Position              = UDim2.new(0, 0, 0, 18)
resTitle.TextXAlignment        = Enum.TextXAlignment.Center
resTitle.ZIndex                = 22
resTitle.Parent                = resultPopup

local resBoxName = Instance.new("TextLabel")
resBoxName.Text                   = ""
resBoxName.TextSize               = 13
resBoxName.Font                   = Enum.Font.Gotham
resBoxName.BackgroundTransparency = 1
resBoxName.TextColor3             = C_CINZA
resBoxName.Size                   = UDim2.new(1, 0, 0, 20)
resBoxName.Position               = UDim2.new(0, 0, 0, 52)
resBoxName.TextXAlignment         = Enum.TextXAlignment.Center
resBoxName.ZIndex                 = 22
resBoxName.Parent                 = resultPopup

local thumbFrame = Instance.new("Frame")
thumbFrame.Size             = UDim2.fromOffset(180, 180)
thumbFrame.AnchorPoint      = Vector2.new(0.5, 0)
thumbFrame.Position         = UDim2.new(0.5, 0, 0, 78)
thumbFrame.BackgroundColor3 = C_PAINEL
thumbFrame.BorderSizePixel  = 0
thumbFrame.ZIndex           = 22
thumbFrame.Parent           = resultPopup
addCorner(thumbFrame, 10)
addStroke(thumbFrame, 1.5, C_OURO)

local thumbImg = Instance.new("ImageLabel")
thumbImg.Size                = UDim2.fromScale(1, 1)
thumbImg.BackgroundTransparency = 1
thumbImg.ScaleType           = Enum.ScaleType.Fit
thumbImg.Image               = ""
thumbImg.ZIndex              = 23
thumbImg.Parent              = thumbFrame

local resItemName = Instance.new("TextLabel")
resItemName.Text                   = ""
resItemName.TextSize               = 16
resItemName.Font                   = Enum.Font.GothamBold
resItemName.BackgroundTransparency = 1
resItemName.TextColor3             = C_TEXTO
resItemName.Size                   = UDim2.new(1, -24, 0, 0)
resItemName.AutomaticSize          = Enum.AutomaticSize.Y
resItemName.Position               = UDim2.new(0, 12, 0, 268)
resItemName.TextXAlignment         = Enum.TextXAlignment.Center
resItemName.TextWrapped            = true
resItemName.ZIndex                 = 22
resItemName.Parent                 = resultPopup

local closeBtn = Instance.new("TextButton")
closeBtn.Text             = "✕  Fechar"
closeBtn.TextSize         = 14
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextColor3       = Color3.new(1, 1, 1)
closeBtn.Size             = UDim2.new(1, -48, 0, 38)
closeBtn.AnchorPoint      = Vector2.new(0.5, 0)
closeBtn.Position         = UDim2.new(0.5, 0, 0, 324)
closeBtn.BackgroundColor3 = C_OURO
closeBtn.BorderSizePixel  = 0
closeBtn.AutoButtonColor  = false
closeBtn.ZIndex           = 22
closeBtn.Parent           = resultPopup
addCorner(closeBtn, 8)

local function fecharResult()
	TweenService:Create(resultPopup, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(0, 0),
	}):Play()
	task.delay(0.22, function()
		resultOverlay.Visible = false
		resultPopup.Visible   = false
	end)
end

local function abrirResult(result)
	resBoxName.Text  = result.boxName
	resItemName.Text = result.itemName
	thumbImg.Image   = string.format("rbxthumb://type=Asset&id=%d&w=420&h=420", result.itemId)

	resultOverlay.Visible = true
	resultPopup.Visible   = true
	resultPopup.Size      = UDim2.fromOffset(0, 0)

	TweenService:Create(resultPopup, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(320, 380),
	}):Play()
end

closeBtn.Activated:Connect(fecharResult)
resultOverlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		fecharResult()
	end
end)

LootboxResultEvent.OnClientEvent:Connect(abrirResult)

print("[PurchaseUI] Pronto.")
