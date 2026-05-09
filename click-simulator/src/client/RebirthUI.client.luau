local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes             = ReplicatedStorage:WaitForChild("Remotes")
local RebirthConfirmEvent = Remotes:WaitForChild("RebirthConfirmEvent")
local RebirthEvent        = Remotes:WaitForChild("RebirthEvent")
local RebirthResultEvent  = Remotes:WaitForChild("RebirthResultEvent")

local C_FUNDO  = Color3.fromRGB(14, 10, 22)
local C_PAINEL = Color3.fromRGB(24, 18, 38)
local C_OURO   = Color3.fromRGB(255, 215, 0)
local C_VERDE  = Color3.fromRGB(50, 180, 80)
local C_VERM   = Color3.fromRGB(200, 55, 55)
local C_TEXTO  = Color3.fromRGB(240, 230, 215)

local function addCorner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = parent
end

local function addStroke(parent, thickness, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 2
	s.Color     = color or C_OURO
	s.Parent    = parent
end

-- ─────────────────────────────────────────────────────────────
-- ScreenGui
-- ─────────────────────────────────────────────────────────────

local gui = Instance.new("ScreenGui")
gui.Name           = "RebirthGui"
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = playerGui

-- BindableEvent para ClientUI abrir a confirmação de rebirth
local openBE = Instance.new("BindableEvent")
openBE.Name   = "OpenRebirthBE"
openBE.Parent = playerGui

-- ─────────────────────────────────────────────────────────────
-- Popup de CONFIRMAÇÃO
-- ─────────────────────────────────────────────────────────────

local confirmOverlay = Instance.new("Frame")
confirmOverlay.Size                   = UDim2.fromScale(1, 1)
confirmOverlay.BackgroundColor3       = Color3.new(0, 0, 0)
confirmOverlay.BackgroundTransparency = 0.5
confirmOverlay.Visible                = false
confirmOverlay.ZIndex                 = 40
confirmOverlay.Parent                 = gui

local confirmCard = Instance.new("Frame")
confirmCard.Size            = UDim2.fromOffset(340, 380)
confirmCard.AnchorPoint     = Vector2.new(0.5, 0.5)
confirmCard.Position        = UDim2.fromScale(0.5, 0.5)
confirmCard.BackgroundColor3 = C_FUNDO
confirmCard.BorderSizePixel = 0
confirmCard.Visible         = false
confirmCard.ZIndex          = 41
confirmCard.Parent          = gui
addCorner(confirmCard, 14)
addStroke(confirmCard, 2.5, C_OURO)

local confirmTitulo = Instance.new("TextLabel")
confirmTitulo.Text     = "⚠️  Tem certeza?"
confirmTitulo.TextSize = 20
confirmTitulo.Font     = Enum.Font.GothamBold
confirmTitulo.TextColor3 = Color3.fromRGB(255, 200, 50)
confirmTitulo.BackgroundTransparency = 1
confirmTitulo.Size     = UDim2.new(1, 0, 0, 36)
confirmTitulo.Position = UDim2.fromOffset(0, 18)
confirmTitulo.TextXAlignment = Enum.TextXAlignment.Center
confirmTitulo.ZIndex   = 42
confirmTitulo.Parent   = confirmCard

-- Separador
local sep = Instance.new("Frame")
sep.Size             = UDim2.new(0.8, 0, 0, 1)
sep.Position         = UDim2.new(0.1, 0, 0, 60)
sep.BackgroundColor3 = C_OURO
sep.BackgroundTransparency = 0.5
sep.BorderSizePixel  = 0
sep.ZIndex           = 42
sep.Parent           = confirmCard

-- "Você vai perder:"
local perderTitle = Instance.new("TextLabel")
perderTitle.Text   = "Você vai perder:"
perderTitle.TextSize = 13
perderTitle.Font   = Enum.Font.GothamBold
perderTitle.TextColor3 = Color3.fromRGB(220, 100, 100)
perderTitle.BackgroundTransparency = 1
perderTitle.Size   = UDim2.new(1, -20, 0, 22)
perderTitle.Position = UDim2.fromOffset(14, 70)
perderTitle.TextXAlignment = Enum.TextXAlignment.Left
perderTitle.ZIndex = 42
perderTitle.Parent = confirmCard

local perderItens = { "Todas as moedas", "Todo o inventário de roupas", "Todos os upgrades de clique" }
for i, txt in ipairs(perderItens) do
	local l = Instance.new("TextLabel")
	l.Text     = "  ✗  " .. txt
	l.TextSize = 12
	l.Font     = Enum.Font.Gotham
	l.TextColor3 = Color3.fromRGB(255, 120, 120)
	l.BackgroundTransparency = 1
	l.Size     = UDim2.new(1, -20, 0, 20)
	l.Position = UDim2.fromOffset(14, 88 + (i - 1) * 22)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.ZIndex   = 42
	l.Parent   = confirmCard
end

-- "Você vai ganhar:"
local ganharTitle = Instance.new("TextLabel")
ganharTitle.Text   = "Você vai ganhar:"
ganharTitle.TextSize = 13
ganharTitle.Font   = Enum.Font.GothamBold
ganharTitle.TextColor3 = Color3.fromRGB(80, 210, 120)
ganharTitle.BackgroundTransparency = 1
ganharTitle.Size   = UDim2.new(1, -20, 0, 22)
ganharTitle.Position = UDim2.fromOffset(14, 162)
ganharTitle.TextXAlignment = Enum.TextXAlignment.Left
ganharTitle.ZIndex = 42
ganharTitle.Parent = confirmCard

local ganharItens = {
	"+10% de moedas por clique pra sempre",
	"⭐ Estrela de rebirth",
	"Acesso à Caixa Rebirth exclusiva",
}
for i, txt in ipairs(ganharItens) do
	local l = Instance.new("TextLabel")
	l.Text     = "  ✓  " .. txt
	l.TextSize = 12
	l.Font     = Enum.Font.Gotham
	l.TextColor3 = Color3.fromRGB(100, 230, 140)
	l.BackgroundTransparency = 1
	l.Size     = UDim2.new(1, -20, 0, 20)
	l.Position = UDim2.fromOffset(14, 180 + (i - 1) * 22)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.ZIndex   = 42
	l.Parent   = confirmCard
end

-- Botões
local confirmarBtn = Instance.new("TextButton")
confirmarBtn.Text            = "✓  CONFIRMAR"
confirmarBtn.TextSize        = 15
confirmarBtn.Font            = Enum.Font.GothamBold
confirmarBtn.TextColor3      = Color3.new(1, 1, 1)
confirmarBtn.Size            = UDim2.new(0.44, 0, 0, 44)
confirmarBtn.AnchorPoint     = Vector2.new(0, 0)
confirmarBtn.Position        = UDim2.new(0.04, 0, 0, 320)
confirmarBtn.BackgroundColor3 = C_VERDE
confirmarBtn.BorderSizePixel = 0
confirmarBtn.AutoButtonColor = false
confirmarBtn.ZIndex          = 42
confirmarBtn.Parent          = confirmCard
addCorner(confirmarBtn, 8)

local cancelarBtn = Instance.new("TextButton")
cancelarBtn.Text            = "✕  CANCELAR"
cancelarBtn.TextSize        = 14
cancelarBtn.Font            = Enum.Font.GothamBold
cancelarBtn.TextColor3      = Color3.new(1, 1, 1)
cancelarBtn.Size            = UDim2.new(0.44, 0, 0, 44)
cancelarBtn.AnchorPoint     = Vector2.new(1, 0)
cancelarBtn.Position        = UDim2.new(0.96, 0, 0, 320)
cancelarBtn.BackgroundColor3 = C_VERM
cancelarBtn.BorderSizePixel = 0
cancelarBtn.AutoButtonColor = false
cancelarBtn.ZIndex          = 42
cancelarBtn.Parent          = confirmCard
addCorner(cancelarBtn, 8)

-- ─────────────────────────────────────────────────────────────
-- Abrir / fechar popup de confirmação
-- ─────────────────────────────────────────────────────────────

local function fecharConfirm()
	TweenService:Create(confirmCard,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Size = UDim2.fromOffset(0, 0) }):Play()
	task.delay(0.2, function()
		confirmOverlay.Visible = false
		confirmCard.Visible    = false
	end)
end

local function abrirConfirm()
	confirmOverlay.Visible = true
	confirmCard.Visible    = true
	confirmCard.Size       = UDim2.fromOffset(0, 0)
	TweenService:Create(confirmCard,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(340, 380) }):Play()
end

confirmarBtn.Activated:Connect(function()
	fecharConfirm()
	RebirthEvent:FireServer()
end)

cancelarBtn.Activated:Connect(fecharConfirm)

RebirthConfirmEvent.OnClientEvent:Connect(abrirConfirm)
openBE.Event:Connect(abrirConfirm)  -- barra de botões também pode abrir

-- ─────────────────────────────────────────────────────────────
-- Popup de RESULTADO
-- ─────────────────────────────────────────────────────────────

local resultOverlay = Instance.new("Frame")
resultOverlay.Size                   = UDim2.fromScale(1, 1)
resultOverlay.BackgroundColor3       = Color3.new(0, 0, 0)
resultOverlay.BackgroundTransparency = 0.45
resultOverlay.Visible                = false
resultOverlay.ZIndex                 = 50
resultOverlay.Parent                 = gui

local resultCard = Instance.new("Frame")
resultCard.Size            = UDim2.fromOffset(320, 280)
resultCard.AnchorPoint     = Vector2.new(0.5, 0.5)
resultCard.Position        = UDim2.fromScale(0.5, 0.5)
resultCard.BackgroundColor3 = C_FUNDO
resultCard.BorderSizePixel = 0
resultCard.Visible         = false
resultCard.ZIndex          = 51
resultCard.Parent          = gui
addCorner(resultCard, 14)
addStroke(resultCard, 2.5, C_OURO)

local resTitulo = Instance.new("TextLabel")
resTitulo.Name   = "Titulo"
resTitulo.Text   = ""
resTitulo.TextSize = 22
resTitulo.Font   = Enum.Font.GothamBold
resTitulo.TextColor3 = C_OURO
resTitulo.BackgroundTransparency = 1
resTitulo.Size   = UDim2.new(1, 0, 0, 50)
resTitulo.Position = UDim2.fromOffset(0, 20)
resTitulo.TextXAlignment = Enum.TextXAlignment.Center
resTitulo.ZIndex = 52
resTitulo.Parent = resultCard

local resSubtitulo = Instance.new("TextLabel")
resSubtitulo.Name   = "Subtitulo"
resSubtitulo.Text   = ""
resSubtitulo.TextSize = 16
resSubtitulo.Font   = Enum.Font.GothamBold
resSubtitulo.TextColor3 = C_TEXTO
resSubtitulo.BackgroundTransparency = 1
resSubtitulo.Size   = UDim2.new(1, -20, 0, 30)
resSubtitulo.Position = UDim2.fromOffset(10, 80)
resSubtitulo.TextXAlignment = Enum.TextXAlignment.Center
resSubtitulo.ZIndex = 52
resSubtitulo.Parent = resultCard

local resMult = Instance.new("TextLabel")
resMult.Name   = "Mult"
resMult.Text   = ""
resMult.TextSize = 14
resMult.Font   = Enum.Font.Gotham
resMult.TextColor3 = Color3.fromRGB(180, 220, 255)
resMult.BackgroundTransparency = 1
resMult.Size   = UDim2.new(1, -20, 0, 26)
resMult.Position = UDim2.fromOffset(10, 118)
resMult.TextXAlignment = Enum.TextXAlignment.Center
resMult.ZIndex = 52
resMult.Parent = resultCard

local resDescricao = Instance.new("TextLabel")
resDescricao.Text   = "Continue clicando para crescer ainda mais!"
resDescricao.TextSize = 12
resDescricao.Font   = Enum.Font.Gotham
resDescricao.TextColor3 = Color3.fromRGB(160, 150, 180)
resDescricao.BackgroundTransparency = 1
resDescricao.Size   = UDim2.new(1, -20, 0, 26)
resDescricao.Position = UDim2.fromOffset(10, 152)
resDescricao.TextXAlignment = Enum.TextXAlignment.Center
resDescricao.ZIndex = 52
resDescricao.Parent = resultCard

local fecharBtn = Instance.new("TextButton")
fecharBtn.Text            = "✕  Fechar"
fecharBtn.TextSize        = 14
fecharBtn.Font            = Enum.Font.GothamBold
fecharBtn.TextColor3      = Color3.new(1, 1, 1)
fecharBtn.Size            = UDim2.new(1, -48, 0, 42)
fecharBtn.AnchorPoint     = Vector2.new(0.5, 0)
fecharBtn.Position        = UDim2.new(0.5, 0, 0, 222)
fecharBtn.BackgroundColor3 = C_OURO
fecharBtn.BorderSizePixel = 0
fecharBtn.AutoButtonColor = false
fecharBtn.ZIndex          = 52
fecharBtn.Parent          = resultCard
addCorner(fecharBtn, 8)

local function fecharResult()
	TweenService:Create(resultCard,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Size = UDim2.fromOffset(0, 0) }):Play()
	task.delay(0.2, function()
		resultOverlay.Visible = false
		resultCard.Visible    = false
	end)
end

fecharBtn.Activated:Connect(fecharResult)
resultOverlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		fecharResult()
	end
end)

-- ─────────────────────────────────────────────────────────────
-- Flash dourado no Lighting
-- ─────────────────────────────────────────────────────────────

local function flashDourado()
	local cc = Instance.new("ColorCorrectionEffect")
	cc.TintColor = Color3.fromRGB(255, 220, 50)
	cc.Brightness = 0.3
	cc.Parent = Lighting

	TweenService:Create(cc,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Brightness = 0, TintColor = Color3.new(1, 1, 1) }):Play()
	task.delay(1.1, function() cc:Destroy() end)
end

-- ─────────────────────────────────────────────────────────────
-- Confete dourado (3s)
-- ─────────────────────────────────────────────────────────────

local function lancarConfete()
	local attach = Instance.new("Attachment")
	attach.Parent = playerGui

	local p = Instance.new("ParticleEmitter")
	p.Color          = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 160, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 240, 120)),
	})
	p.LightEmission  = 0.6
	p.LightInfluence = 0
	p.Rate           = 40
	p.Lifetime       = NumberRange.new(2, 3.5)
	p.Speed          = NumberRange.new(8, 16)
	p.Size           = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	p.Transparency   = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	p.SpreadAngle    = Vector2.new(180, 180)
	p.RotSpeed       = NumberRange.new(-90, 90)
	p.Parent         = attach

	task.delay(3, function()
		p.Enabled = false
		task.delay(3.5, function() attach:Destroy() end)
	end)
end

-- ─────────────────────────────────────────────────────────────
-- Toast de erro simples
-- ─────────────────────────────────────────────────────────────

local function mostrarErro(motivo: string)
	local t = Instance.new("TextLabel")
	t.Text             = "❌ " .. motivo
	t.TextSize         = 14
	t.Font             = Enum.Font.GothamBold
	t.TextColor3       = Color3.new(1, 1, 1)
	t.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
	t.BorderSizePixel  = 0
	t.Size             = UDim2.fromOffset(280, 42)
	t.Position         = UDim2.new(0.5, -140, 1, -60)
	t.ZIndex           = 60
	t.Parent           = gui
	local c = Instance.new("UICorner", t)
	c.CornerRadius = UDim.new(0, 8)
	task.delay(2.5, function() t:Destroy() end)
end

-- ─────────────────────────────────────────────────────────────
-- Recebe resultado do servidor
-- ─────────────────────────────────────────────────────────────

RebirthResultEvent.OnClientEvent:Connect(function(result)
	if not result.success then
		mostrarErro(result.reason or "Erro ao fazer rebirth")
		return
	end

	flashDourado()
	lancarConfete()

	local rebirths = result.rebirths or 1
	local mult     = result.multiplier or 1.1

	-- Estrelas
	local maxDisplay = 10
	local estrelas
	if rebirths > maxDisplay then
		estrelas = "⭐x" .. rebirths
	else
		estrelas = string.rep("⭐", rebirths)
	end

	resTitulo.Text    = estrelas
	resSubtitulo.Text = "Rebirth " .. rebirths .. " realizado!"
	resMult.Text      = string.format("Multiplicador: %.1fx  (+%d%%)", mult, (rebirths) * 10)

	resultOverlay.Visible = true
	resultCard.Visible    = true
	resultCard.Size       = UDim2.fromOffset(0, 0)
	TweenService:Create(resultCard,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(320, 280) }):Play()

	print(string.format("[RebirthUI] Rebirth %d concluído! Multiplicador: %.1fx", rebirths, mult))
end)

print("[RebirthUI] Pronto.")
