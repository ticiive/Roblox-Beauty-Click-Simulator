-- HUD principal: stats, barra de botões, botão de clique central, animações.

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

local statsAtuais = { coins = 0, clickPower = 1, totalClicks = 0, rebirths = 0, rebirthMultiplier = 1.0 }
local inventoryCount = 0

-- ─────────────────────────────────────────────────────────────
-- Paleta Fashion/Boutique
-- ─────────────────────────────────────────────────────────────

local C_PRIMARIA   = Color3.fromRGB(255, 182, 193)  -- rosa claro
local C_SECUNDARIA = Color3.fromRGB(255, 215, 0)    -- dourado
local C_ESCURO     = Color3.fromRGB(40, 30, 45)     -- roxo muito escuro
local C_TEXTO      = Color3.fromRGB(255, 255, 255)
local C_CINZA      = Color3.fromRGB(100, 90, 110)
local C_VERDE      = Color3.fromRGB(80, 200, 120)
local C_AZUL       = Color3.fromRGB(100, 180, 255)
local C_LARANJA    = Color3.fromRGB(255, 140, 0)

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

local function addCorner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = r or UDim.new(0, 12)
	c.Parent = inst
	return c
end

local function addStroke(inst, cor, thickness)
	local s = Instance.new("UIStroke")
	s.Color     = cor or C_SECUNDARIA
	s.Thickness = thickness or 1.5
	s.Parent    = inst
	return s
end

-- Forward declarations
local atualizarBotoesLoja
local atualizarStats
local atualizarBadges

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
statsFrame.Size                   = UDim2.new(0, 220, 0, 120)
statsFrame.Position               = UDim2.new(0, 12, 0, 12)
statsFrame.BackgroundColor3       = C_ESCURO
statsFrame.BackgroundTransparency = 0.15
statsFrame.BorderSizePixel        = 0
statsFrame.Parent                 = screenGui
addCorner(statsFrame, UDim.new(0, 16))
addStroke(statsFrame, C_SECUNDARIA, 1.5)

local function novaLabel(posY, texto, tamanho, cor)
	local lb = Instance.new("TextLabel")
	lb.Size                   = UDim2.new(1, -16, 0, 28)
	lb.Position               = UDim2.new(0, 10, 0, posY)
	lb.BackgroundTransparency = 1
	lb.TextColor3             = cor or C_TEXTO
	lb.TextSize               = tamanho or 15
	lb.Font                   = Enum.Font.GothamBold
	lb.TextXAlignment         = Enum.TextXAlignment.Left
	lb.Text                   = texto
	lb.Parent                 = statsFrame
	return lb
end

local labelMoedas  = novaLabel(8,  "💰 0",           22, C_SECUNDARIA)
local labelPoder   = novaLabel(36, "👆 1 por clique", 14, C_TEXTO)
local labelCliques = novaLabel(58, "0 cliques",       12, Color3.fromRGB(200, 200, 200))
local labelRebirth = novaLabel(80, "",                13, C_SECUNDARIA)
labelRebirth.Visible = false

-- ─────────────────────────────────────────────────────────────
-- Feedback visual de cliques (botão central removido — InputBegan
-- abaixo já captura cliques em qualquer ponto da tela)
-- ─────────────────────────────────────────────────────────────

local function mostrarFeedback(pos: Vector2)
	local valor = fmt(statsAtuais.clickPower)
	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.fromOffset(120, 34)
	lbl.Position               = UDim2.new(0, pos.X - 60, 0, pos.Y - 30)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = "+" .. valor .. "💰"
	lbl.TextColor3             = C_SECUNDARIA
	lbl.TextSize               = 20
	lbl.Font                   = Enum.Font.GothamBold
	lbl.TextStrokeColor3       = Color3.new(0, 0, 0)
	lbl.TextStrokeTransparency = 0.4
	lbl.ZIndex                 = 10
	lbl.Parent                 = screenGui

	TweenService:Create(lbl, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position         = UDim2.new(0, pos.X - 60, 0, pos.Y - 70),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	task.delay(0.65, function() lbl:Destroy() end)
end

-- Clique em qualquer lugar da tela registra
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		mostrarFeedback(UserInputService:GetMouseLocation())
		ClickEvent:FireServer()
	end
end)

-- ─────────────────────────────────────────────────────────────
-- Painel de Upgrades (slide da direita) — mantido
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
lojaFrame.BackgroundColor3       = C_ESCURO
lojaFrame.BackgroundTransparency = 0.08
lojaFrame.BorderSizePixel        = 0
lojaFrame.Parent                 = screenGui
addCorner(lojaFrame, UDim.new(0, 14))
addStroke(lojaFrame, C_SECUNDARIA)

local lojaTitulo = Instance.new("TextLabel")
lojaTitulo.Size                   = UDim2.new(1, 0, 0, 32)
lojaTitulo.Position               = UDim2.new(0, 0, 0, 8)
lojaTitulo.BackgroundTransparency = 1
lojaTitulo.Text                   = "✦  UPGRADES  ✦"
lojaTitulo.TextColor3             = C_SECUNDARIA
lojaTitulo.TextSize               = 14
lojaTitulo.Font                   = Enum.Font.GothamBold
lojaTitulo.Parent                 = lojaFrame

local sep = Instance.new("Frame")
sep.Size             = UDim2.new(0.6, 0, 0, 1)
sep.Position         = UDim2.new(0.2, 0, 0, 38)
sep.BackgroundColor3 = C_SECUNDARIA
sep.BackgroundTransparency = 0.4
sep.BorderSizePixel  = 0
sep.Parent           = lojaFrame
addCorner(sep, UDim.new(1, 0))

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
	addCorner(btn, UDim.new(0, 10))

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

local tweenLojaAbrir = TweenService:Create(lojaFrame,
	TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	{ Position = POS_LOJA_ABERTA })
local tweenLojaFechar = TweenService:Create(lojaFrame,
	TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	{ Position = POS_LOJA_FECHADA })

-- ─────────────────────────────────────────────────────────────
-- Barra de botões inferior
-- ─────────────────────────────────────────────────────────────

local barra = Instance.new("Frame")
barra.Size                   = UDim2.fromOffset(1, 72)  -- largura calculada pelo layout
barra.AutomaticSize          = Enum.AutomaticSize.X
barra.AnchorPoint            = Vector2.new(0.5, 1)
barra.Position               = UDim2.new(0.5, 0, 1, -14)
barra.BackgroundColor3       = C_ESCURO
barra.BackgroundTransparency = 0.2
barra.BorderSizePixel        = 0
barra.ZIndex                 = 5
barra.Parent                 = screenGui
addCorner(barra, UDim.new(0, 20))
addStroke(barra, C_SECUNDARIA, 1.5)

local barraLayout = Instance.new("UIListLayout")
barraLayout.FillDirection     = Enum.FillDirection.Horizontal
barraLayout.SortOrder         = Enum.SortOrder.LayoutOrder
barraLayout.Padding           = UDim.new(0, 8)
barraLayout.VerticalAlignment = Enum.VerticalAlignment.Center
barraLayout.Parent            = barra

local barraPad = Instance.new("UIPadding")
barraPad.PaddingLeft   = UDim.new(0, 12)
barraPad.PaddingRight  = UDim.new(0, 12)
barraPad.PaddingTop    = UDim.new(0, 6)
barraPad.PaddingBottom = UDim.new(0, 6)
barraPad.Parent        = barra

-- Função para criar botão da barra
local function criarBotaoBarra(emoji, cor, ordem)
	local btn = Instance.new("TextButton")
	btn.Size             = UDim2.fromOffset(60, 60)
	btn.BackgroundColor3 = cor
	btn.BorderSizePixel  = 0
	btn.Text             = emoji
	btn.TextSize         = 28
	btn.Font             = Enum.Font.GothamBold
	btn.AutoButtonColor  = false
	btn.LayoutOrder      = ordem
	btn.ZIndex           = 6
	btn.Parent           = barra
	addCorner(btn, UDim.new(0, 14))
	addStroke(btn, C_SECUNDARIA, 1.5)

	-- Hover
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { Size = UDim2.fromOffset(64, 64) }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { Size = UDim2.fromOffset(60, 60) }):Play()
	end)

	return btn
end

-- Função para criar badge "!" no canto do botão
local pulseTweens = {}

local function criarBadge(pai, texto)
	local badge = Instance.new("TextLabel")
	badge.Size                   = UDim2.fromOffset(18, 18)
	badge.AnchorPoint            = Vector2.new(1, 0)
	badge.Position               = UDim2.new(1, 2, 0, -2)
	badge.BackgroundColor3       = Color3.fromRGB(255, 50, 50)
	badge.BackgroundTransparency = 1
	badge.Text                   = texto or "!"
	badge.TextSize               = 11
	badge.Font                   = Enum.Font.GothamBold
	badge.TextColor3             = Color3.new(1, 1, 1)
	badge.BorderSizePixel        = 0
	badge.ZIndex                 = 8
	badge.Visible                = false
	badge.Parent                 = pai
	addCorner(badge, UDim.new(1, 0))
	return badge
end

local function ativarBadge(badge, texto)
	badge.Text                   = texto or "!"
	badge.BackgroundTransparency = 0
	badge.Visible                = true

	-- Cancela tween anterior
	if pulseTweens[badge] then pulseTweens[badge]:Cancel() end

	local t = TweenService:Create(badge,
		TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Size = UDim2.fromOffset(21, 21), Position = UDim2.new(1, 3, 0, -3) })
	t:Play()
	pulseTweens[badge] = t
end

local function desativarBadge(badge)
	if pulseTweens[badge] then pulseTweens[badge]:Cancel() end
	badge.BackgroundTransparency = 1
	badge.Visible                = false
	badge.Size                   = UDim2.fromOffset(18, 18)
	badge.Position               = UDim2.new(1, 2, 0, -2)
end

-- Cria os 4 botões da barra
local btnDiario   = criarBotaoBarra("🎁", C_LARANJA,               1)
local btnInv      = criarBotaoBarra("👗", Color3.fromRGB(255,105,180), 2)
local btnUpgrade  = criarBotaoBarra("⬆️", C_VERDE,                 3)
local btnRebirth  = criarBotaoBarra("🔄", C_AZUL,                  4)

local badgeDiario  = criarBadge(btnDiario, "!")
local badgeInv     = criarBadge(btnInv, "0")
local badgeUpgrade = criarBadge(btnUpgrade, "!")
local badgeRebirth = criarBadge(btnRebirth, "!")

-- BindableEvent para ClientUI notificar badge diário
local setDailyBadgeBE = Instance.new("BindableEvent")
setDailyBadgeBE.Name   = "SetDailyBadgeBE"
setDailyBadgeBE.Parent = playerGui

setDailyBadgeBE.Event:Connect(function(canClaim: boolean)
	if canClaim then
		ativarBadge(badgeDiario, "!")
		-- Cor do botão muda pra laranja brilhante
		TweenService:Create(btnDiario, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(255, 160, 30) }):Play()
	else
		desativarBadge(badgeDiario)
		TweenService:Create(btnDiario, TweenInfo.new(0.3), { BackgroundColor3 = C_LARANJA }):Play()
	end
end)

-- ─────────────────────────────────────────────────────────────
-- Lógica dos botões da barra
-- ─────────────────────────────────────────────────────────────

-- 🎁 Recompensa Diária
btnDiario.Activated:Connect(function()
	local be = playerGui:FindFirstChild("OpenDailyRewardBE")
	if be then be:Fire() end
end)

-- 👗 Inventário
btnInv.Activated:Connect(function()
	local be = playerGui:FindFirstChild("OpenInventoryBE")
	if be then be:Fire() end
end)

-- ⬆️ Upgrades (toggle painel)
btnUpgrade.Activated:Connect(function()
	lojaAberta = not lojaAberta
	if lojaAberta then
		tweenLojaAbrir:Play()
	else
		tweenLojaFechar:Play()
	end
end)

-- 🔄 Rebirth
btnRebirth.Activated:Connect(function()
	local be = playerGui:FindFirstChild("OpenRebirthBE")
	if be then be:Fire() end
end)

-- ─────────────────────────────────────────────────────────────
-- Atualização de badges
-- ─────────────────────────────────────────────────────────────

function atualizarBadges()
	-- Badge inventário (número de itens) — atualizado por InventoryUpdateEvent
	-- Badge upgrade: verde se tem moedas pra comprar algum
	local temUpgrade = false
	for _, upgrade in ipairs(GameConfig.Upgrades) do
		if statsAtuais.coins >= upgrade.cost then
			temUpgrade = true
			break
		end
	end
	if temUpgrade then
		ativarBadge(badgeUpgrade, "!")
	else
		desativarBadge(badgeUpgrade)
	end

	-- Badge rebirth: quando tem 100k+
	if statsAtuais.coins >= 100000 then
		ativarBadge(badgeRebirth, "!")
	else
		desativarBadge(badgeRebirth)
	end
end

-- ─────────────────────────────────────────────────────────────
-- Atualização do painel de upgrades
-- ─────────────────────────────────────────────────────────────

function atualizarBotoesLoja()
	for i, upgrade in ipairs(GameConfig.Upgrades) do
		botoesUpgrade[i].BackgroundColor3 = (statsAtuais.coins >= upgrade.cost)
			and C_VERDE or C_CINZA
	end
end

-- ─────────────────────────────────────────────────────────────
-- Atualização dos stats
-- ─────────────────────────────────────────────────────────────

function atualizarStats(dados)
	statsAtuais = dados

	labelMoedas.Text = "💰 " .. fmt(dados.coins)

	local mult = dados.rebirthMultiplier or 1
	if mult > 1 then
		labelPoder.Text = "👆 " .. fmt(dados.clickPower)
			.. " (x" .. string.format("%.1f", mult) .. ")"
	else
		labelPoder.Text = "👆 " .. fmt(dados.clickPower) .. " por clique"
	end

	labelCliques.Text = fmt(dados.totalClicks) .. " cliques"

	local rebirths = dados.rebirths or 0
	if rebirths > 0 then
		if rebirths > 10 then
			labelRebirth.Text = "⭐x" .. rebirths
		else
			labelRebirth.Text = string.rep("⭐", rebirths)
		end
		labelRebirth.Visible = true
		statsFrame.Size = UDim2.new(0, 220, 0, 148)
	else
		labelRebirth.Visible = false
		statsFrame.Size = UDim2.new(0, 220, 0, 120)
	end

	atualizarBotoesLoja()
	atualizarBadges()
end

UpdateStatsEvent.OnClientEvent:Connect(atualizarStats)

-- ─────────────────────────────────────────────────────────────
-- Badge de inventário (recebe de InventoryUI via BindableEvent)
-- ─────────────────────────────────────────────────────────────

local setInvCountBE = Instance.new("BindableEvent")
setInvCountBE.Name   = "SetInvCountBE"
setInvCountBE.Parent = playerGui

setInvCountBE.Event:Connect(function(count: number)
	inventoryCount = count
	if count > 0 then
		ativarBadge(badgeInv, tostring(math.min(count, 99)))
	else
		desativarBadge(badgeInv)
	end
end)

print("[HUD] Interface Fashion carregada.")
