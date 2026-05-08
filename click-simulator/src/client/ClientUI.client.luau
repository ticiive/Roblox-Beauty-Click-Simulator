-- Interface Boutique de Luxo (upgrades) + stats.
-- Roupas/inventário gerenciados pelo InventoryUI.client.luau.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared     = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local ClickEvent       = ReplicatedStorage:WaitForChild("ClickEvent")
local BuyUpgradeEvent  = ReplicatedStorage:WaitForChild("BuyUpgradeEvent")
local UpdateStatsEvent = ReplicatedStorage:WaitForChild("UpdateStatsEvent")

local statsAtuais = { coins = 0, clickPower = 1, totalClicks = 0 }

-- ─────────────────────────────────────────────────────────────
-- Paleta Boutique de Luxo
-- ─────────────────────────────────────────────────────────────

local C_FUNDO    = Color3.fromRGB(10, 6, 16)
local C_OURO     = Color3.fromRGB(212, 175, 55)
local C_TEXTO    = Color3.fromRGB(255, 245, 228)
local C_VERDE    = Color3.fromRGB(60, 190, 120)
local C_CINZA    = Color3.fromRGB(55, 48, 68)
local C_BOTAO    = Color3.fromRGB(22, 14, 36)

local EMOJIS = { "👗", "👠", "👜", "💄", "🎀", "✨", "👒", "💍", "🌸" }

-- ─────────────────────────────────────────────────────────────
-- Utilitários
-- ─────────────────────────────────────────────────────────────

local function fmt(n: number): string
	n = math.floor(n)
	if n >= 1e9 then return string.format("%.1fB", n / 1e9)
	elseif n >= 1e6 then return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
	else return tostring(n) end
end

local function arredondar(inst: GuiObject, raio: UDim?)
	local c = Instance.new("UICorner")
	c.CornerRadius = raio or UDim.new(0, 12)
	c.Parent = inst
end

local function borda(inst: GuiObject, cor: Color3, espessura: number?)
	local s = Instance.new("UIStroke")
	s.Color     = cor
	s.Thickness = espessura or 1.5
	s.Parent    = inst
	return s
end

local function linhaDecorativa(parent: GuiObject, posY: number)
	local l = Instance.new("Frame")
	l.Size             = UDim2.new(0.6, 0, 0, 1)
	l.Position         = UDim2.new(0.2, 0, 0, posY)
	l.BackgroundColor3 = C_OURO
	l.BackgroundTransparency = 0.4
	l.BorderSizePixel  = 0
	l.Parent           = parent
	arredondar(l, UDim.new(1, 0))
end

-- Forward declarations
local atualizarBotoesLoja
local atualizarStats

-- ─────────────────────────────────────────────────────────────
-- ScreenGui
-- ─────────────────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "ClickSimulatorUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = false
screenGui.Parent         = playerGui

-- ─────────────────────────────────────────────────────────────
-- Painel de Stats — canto superior esquerdo
-- ─────────────────────────────────────────────────────────────

local statsFrame = Instance.new("Frame")
statsFrame.Size                   = UDim2.new(0, 230, 0, 148)
statsFrame.Position               = UDim2.new(0, 16, 0, 16)
statsFrame.BackgroundColor3       = C_FUNDO
statsFrame.BackgroundTransparency = 0.08
statsFrame.BorderSizePixel        = 0
statsFrame.Parent                 = screenGui
arredondar(statsFrame, UDim.new(0, 14))
borda(statsFrame, C_OURO)

local statsTitulo = Instance.new("TextLabel")
statsTitulo.Size                   = UDim2.new(1, 0, 0, 30)
statsTitulo.Position               = UDim2.new(0, 0, 0, 8)
statsTitulo.BackgroundTransparency = 1
statsTitulo.Text                   = "✦  MEU PERFIL  ✦"
statsTitulo.TextColor3             = C_OURO
statsTitulo.TextSize               = 12
statsTitulo.Font                   = Enum.Font.GothamBold
statsTitulo.Parent                 = statsFrame
linhaDecorativa(statsFrame, 34)

local function novaLabelStat(posY: number, texto: string): TextLabel
	local lb = Instance.new("TextLabel")
	lb.Size                   = UDim2.new(1, -20, 0, 30)
	lb.Position               = UDim2.new(0, 12, 0, posY)
	lb.BackgroundTransparency = 1
	lb.TextColor3             = C_TEXTO
	lb.TextSize               = 15
	lb.Font                   = Enum.Font.Gotham
	lb.TextXAlignment         = Enum.TextXAlignment.Left
	lb.Text                   = texto
	lb.Parent                 = statsFrame
	return lb
end

local labelMoedas  = novaLabelStat(40,  "💰  Saldo:     0")
local labelPoder   = novaLabelStat(74,  "✨  Estilo:    1")
local labelCliques = novaLabelStat(108, "👗  Criações:  0")

-- ─────────────────────────────────────────────────────────────
-- Feedback flutuante ao clicar
-- ─────────────────────────────────────────────────────────────

local function mostrarFeedback(pos: Vector2)
	local emoji = EMOJIS[math.random(1, #EMOJIS)]
	local label = Instance.new("TextLabel")
	label.Size                   = UDim2.new(0, 110, 0, 36)
	label.Position               = UDim2.new(0, pos.X - 55, 0, pos.Y - 28)
	label.BackgroundTransparency = 1
	label.Text                   = emoji .. "  +" .. fmt(statsAtuais.clickPower)
	label.TextColor3             = C_OURO
	label.TextSize               = 20
	label.Font                   = Enum.Font.GothamBold
	label.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.3
	label.ZIndex                 = 10
	label.Parent                 = screenGui

	local t = TweenService:Create(label,
		TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position=UDim2.new(0, pos.X-55, 0, pos.Y-110), TextTransparency=1, TextStrokeTransparency=1 })
	t:Play()
	t.Completed:Connect(function() label:Destroy() end)
end

-- ─────────────────────────────────────────────────────────────
-- Clique em qualquer lugar
-- ─────────────────────────────────────────────────────────────

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		mostrarFeedback(UserInputService:GetMouseLocation())
		ClickEvent:FireServer()
	end
end)

-- ─────────────────────────────────────────────────────────────
-- Painel da Boutique (upgrades) — direita
-- ─────────────────────────────────────────────────────────────

local ALTURA_BOTAO = 56
local ESPACO       = 8
local ALTURA_LOJA  = 58 + #GameConfig.Upgrades * (ALTURA_BOTAO + ESPACO)

local POS_LOJA_ABERTA  = UDim2.new(1, -230, 0.5, -ALTURA_LOJA / 2)
local POS_LOJA_FECHADA = UDim2.new(1,   20, 0.5, -ALTURA_LOJA / 2)
local lojaAberta = false

local lojaFrame = Instance.new("Frame")
lojaFrame.Size                   = UDim2.new(0, 214, 0, ALTURA_LOJA)
lojaFrame.Position               = POS_LOJA_FECHADA
lojaFrame.BackgroundColor3       = C_FUNDO
lojaFrame.BackgroundTransparency = 0.08
lojaFrame.BorderSizePixel        = 0
lojaFrame.Parent                 = screenGui
arredondar(lojaFrame, UDim.new(0, 14))
borda(lojaFrame, C_OURO)

local lojaTitulo = Instance.new("TextLabel")
lojaTitulo.Size                   = UDim2.new(1, 0, 0, 32)
lojaTitulo.Position               = UDim2.new(0, 0, 0, 8)
lojaTitulo.BackgroundTransparency = 1
lojaTitulo.Text                   = "✦  BOUTIQUE  ✦"
lojaTitulo.TextColor3             = C_OURO
lojaTitulo.TextSize               = 14
lojaTitulo.Font                   = Enum.Font.GothamBold
lojaTitulo.Parent                 = lojaFrame
linhaDecorativa(lojaFrame, 36)

local botoesUpgrade: { TextButton } = {}

for i, upgrade in ipairs(GameConfig.Upgrades) do
	local btn = Instance.new("TextButton")
	btn.Size             = UDim2.new(1, -16, 0, ALTURA_BOTAO)
	btn.Position         = UDim2.new(0, 8, 0, 44 + (i - 1) * (ALTURA_BOTAO + ESPACO))
	btn.BackgroundColor3 = C_CINZA
	btn.BorderSizePixel  = 0
	btn.TextColor3       = C_TEXTO
	btn.TextSize         = 13
	btn.Font             = Enum.Font.Gotham
	btn.Text             = upgrade.name .. "\n💰 " .. fmt(upgrade.cost)
	btn.Parent           = lojaFrame
	arredondar(btn, UDim.new(0, 10))

	btn.MouseEnter:Connect(function()
		if btn.BackgroundColor3 ~= C_VERDE then
			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(75, 66, 92) }):Play()
		end
	end)
	btn.MouseLeave:Connect(function() atualizarBotoesLoja() end)

	local idx = i
	btn.MouseButton1Click:Connect(function() BuyUpgradeEvent:FireServer(idx) end)
	botoesUpgrade[i] = btn
end

-- ─────────────────────────────────────────────────────────────
-- Botão toggle Boutique (canto inferior direito)
-- ─────────────────────────────────────────────────────────────

local btnLoja = Instance.new("TextButton")
btnLoja.Size             = UDim2.new(0, 72, 0, 72)
btnLoja.Position         = UDim2.new(1, -88, 1, -88)
btnLoja.BackgroundColor3 = C_BOTAO
btnLoja.BorderSizePixel  = 0
btnLoja.Text             = "🛒"
btnLoja.TextSize         = 36
btnLoja.Font             = Enum.Font.GothamBold
btnLoja.Parent           = screenGui
arredondar(btnLoja, UDim.new(0, 18))
borda(btnLoja, C_OURO, 2)

local tweenLojaAbrir = TweenService:Create(lojaFrame,
	TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	{ Position = POS_LOJA_ABERTA })
local tweenLojaFechar = TweenService:Create(lojaFrame,
	TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	{ Position = POS_LOJA_FECHADA })

local pulsoLoja = TweenService:Create(btnLoja,
	TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Size=UDim2.new(0, 78, 0, 78), Position=UDim2.new(1, -91, 1, -91) })
pulsoLoja:Play()

btnLoja.MouseButton1Click:Connect(function()
	lojaAberta = not lojaAberta
	if lojaAberta then
		pulsoLoja:Cancel()
		btnLoja.Size     = UDim2.new(0, 72, 0, 72)
		btnLoja.Position = UDim2.new(1, -88, 1, -88)
		tweenLojaAbrir:Play()
	else
		tweenLojaFechar:Play()
		task.delay(0.25, function() pulsoLoja:Play() end)
	end
end)

-- ─────────────────────────────────────────────────────────────
-- Atualização de UI
-- ─────────────────────────────────────────────────────────────

function atualizarBotoesLoja()
	for i, upgrade in ipairs(GameConfig.Upgrades) do
		botoesUpgrade[i].BackgroundColor3 = (statsAtuais.coins >= upgrade.cost)
			and C_VERDE or C_CINZA
	end
end

function atualizarStats(dados: { coins: number, clickPower: number, totalClicks: number })
	statsAtuais = dados
	labelMoedas.Text  = "💰  Saldo:     " .. fmt(dados.coins)
	labelPoder.Text   = "✨  Estilo:    " .. fmt(dados.clickPower)
	labelCliques.Text = "👗  Criações:  " .. fmt(dados.totalClicks)
	atualizarBotoesLoja()
end

-- ─────────────────────────────────────────────────────────────
-- Recebe dados do servidor
-- ─────────────────────────────────────────────────────────────

UpdateStatsEvent.OnClientEvent:Connect(atualizarStats)

print("[ClientUI] Boutique carregada.")
