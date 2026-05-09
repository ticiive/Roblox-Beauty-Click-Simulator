local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local DailyConfig = require(Shared:WaitForChild("DailyRewardConfig"))

local Remotes                = ReplicatedStorage:WaitForChild("Remotes")
local ClaimDailyRewardEvent  = Remotes:WaitForChild("ClaimDailyRewardEvent")
local DailyRewardResultEvent = Remotes:WaitForChild("DailyRewardResultEvent")
local DailyRewardStatusEvent = Remotes:WaitForChild("DailyRewardStatusEvent")

-- ─────────────────────────────────────────────────────────────
-- Paleta
-- ─────────────────────────────────────────────────────────────

local C_PRIMARIA   = Color3.fromRGB(255, 182, 193)
local C_SECUNDARIA = Color3.fromRGB(255, 215, 0)
local C_ESCURO     = Color3.fromRGB(40, 30, 45)
local C_LARANJA    = Color3.fromRGB(255, 140, 0)
local C_VERDE      = Color3.fromRGB(60, 200, 100)
local C_CINZA      = Color3.fromRGB(100, 90, 110)
local C_TEXTO      = Color3.fromRGB(40, 30, 45)
local C_BRANCO     = Color3.new(1, 1, 1)

-- ─────────────────────────────────────────────────────────────
-- Estado
-- ─────────────────────────────────────────────────────────────

local statusAtual = { canClaim = false, currentStreak = 0, diaAtual = 1, timeUntilNext = 0 }
local painelAberto = false
local countdownThread = nil

-- ─────────────────────────────────────────────────────────────
-- Utilitários
-- ─────────────────────────────────────────────────────────────

local function addCorner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 12)
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

local function fmtTime(secs: number): string
	secs = math.ceil(secs)
	local h = math.floor(secs / 3600)
	local m = math.floor((secs % 3600) / 60)
	local s = secs % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end

-- ─────────────────────────────────────────────────────────────
-- ScreenGui
-- ─────────────────────────────────────────────────────────────

local gui = Instance.new("ScreenGui")
gui.Name           = "DailyRewardUI"
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = playerGui

-- BindableEvent para ClientUI abrir este painel
local openBE = Instance.new("BindableEvent")
openBE.Name   = "OpenDailyRewardBE"
openBE.Parent = playerGui

-- ─────────────────────────────────────────────────────────────
-- Overlay + Card principal
-- ─────────────────────────────────────────────────────────────

local overlay = Instance.new("Frame")
overlay.Size                   = UDim2.fromScale(1, 1)
overlay.BackgroundColor3       = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.45
overlay.Visible                = false
overlay.ZIndex                 = 30
overlay.Parent                 = gui

local card = Instance.new("Frame")
card.Size            = UDim2.fromOffset(500, 440)
card.AnchorPoint     = Vector2.new(0.5, 0.5)
card.Position        = UDim2.fromScale(0.5, 0.5)
card.BackgroundColor3 = Color3.fromRGB(255, 248, 252)
card.BorderSizePixel = 0
card.Visible         = false
card.ZIndex          = 31
card.Parent          = gui
addCorner(card, 18)
addStroke(card, C_SECUNDARIA, 2)

-- ─────────────────────────────────────────────────────────────
-- Header
-- ─────────────────────────────────────────────────────────────

local header = Instance.new("Frame")
header.Size                   = UDim2.new(1, 0, 0, 70)
header.BackgroundColor3       = C_PRIMARIA
header.BackgroundTransparency = 0.1
header.BorderSizePixel        = 0
header.ZIndex                 = 32
header.Parent                 = card
addCorner(header, 18)

-- Cobre o arredondamento inferior do header
local headerFill = Instance.new("Frame")
headerFill.Size             = UDim2.new(1, 0, 0.5, 0)
headerFill.Position         = UDim2.new(0, 0, 0.5, 0)
headerFill.BackgroundColor3 = C_PRIMARIA
headerFill.BackgroundTransparency = 0.1
headerFill.BorderSizePixel  = 0
headerFill.ZIndex           = 32
headerFill.Parent           = header

local titleLbl = Instance.new("TextLabel")
titleLbl.Text                   = "🎁  Recompensas Diárias"
titleLbl.TextSize               = 22
titleLbl.Font                   = Enum.Font.GothamBold
titleLbl.TextColor3             = C_ESCURO
titleLbl.BackgroundTransparency = 1
titleLbl.Size                   = UDim2.new(1, -50, 0, 36)
titleLbl.Position               = UDim2.new(0, 16, 0, 8)
titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
titleLbl.ZIndex                 = 33
titleLbl.Parent                 = header

local streakLbl = Instance.new("TextLabel")
streakLbl.Text                   = "Streak: 0 dias 🔥"
streakLbl.TextSize               = 14
streakLbl.Font                   = Enum.Font.GothamBold
streakLbl.TextColor3             = C_LARANJA
streakLbl.BackgroundTransparency = 1
streakLbl.Size                   = UDim2.new(1, -50, 0, 22)
streakLbl.Position               = UDim2.new(0, 16, 0, 42)
streakLbl.TextXAlignment         = Enum.TextXAlignment.Left
streakLbl.ZIndex                 = 33
streakLbl.Parent                 = header

local closeBtn = Instance.new("TextButton")
closeBtn.Text             = "✕"
closeBtn.TextSize         = 16
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextColor3       = C_ESCURO
closeBtn.Size             = UDim2.fromOffset(32, 32)
closeBtn.AnchorPoint      = Vector2.new(1, 0)
closeBtn.Position         = UDim2.new(1, -10, 0, 8)
closeBtn.BackgroundTransparency = 1
closeBtn.ZIndex           = 33
closeBtn.Parent           = header

-- ─────────────────────────────────────────────────────────────
-- Grade de 7 dias
-- ─────────────────────────────────────────────────────────────

local scrollDias = Instance.new("ScrollingFrame")
scrollDias.Size              = UDim2.new(1, -20, 0, 148)
scrollDias.Position          = UDim2.new(0, 10, 0, 80)
scrollDias.BackgroundTransparency = 1
scrollDias.BorderSizePixel   = 0
scrollDias.ScrollBarThickness = 4
scrollDias.ScrollBarImageColor3 = C_SECUNDARIA
scrollDias.CanvasSize        = UDim2.new(0, 0, 0, 0)
scrollDias.AutomaticCanvasSize = Enum.AutomaticSize.X
scrollDias.ScrollingDirection = Enum.ScrollingDirection.X
scrollDias.ZIndex             = 32
scrollDias.Parent             = card

local diaLayout = Instance.new("UIListLayout")
diaLayout.FillDirection       = Enum.FillDirection.Horizontal
diaLayout.SortOrder           = Enum.SortOrder.LayoutOrder
diaLayout.Padding             = UDim.new(0, 6)
diaLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
diaLayout.Parent              = scrollDias

local diaCards = {}  -- { [i] = { frame, badge } }

for i = 1, DailyConfig.MaxStreak do
	local r = DailyConfig.Rewards[i]

	local dc = Instance.new("Frame")
	dc.Size                   = UDim2.fromOffset(80, 110)
	dc.BackgroundColor3       = Color3.fromRGB(250, 240, 250)
	dc.BorderSizePixel        = 0
	dc.LayoutOrder             = i
	dc.ZIndex                 = 33
	dc.Parent                 = scrollDias
	addCorner(dc, 12)
	local stroke = addStroke(dc, Color3.fromRGB(220, 200, 230), 1.5)

	-- "Dia X"
	local diaLabel = Instance.new("TextLabel")
	diaLabel.Text                   = "Dia " .. i
	diaLabel.TextSize               = 11
	diaLabel.Font                   = Enum.Font.GothamBold
	diaLabel.TextColor3             = C_CINZA
	diaLabel.BackgroundTransparency = 1
	diaLabel.Size                   = UDim2.new(1, 0, 0, 18)
	diaLabel.Position               = UDim2.new(0, 0, 0, 5)
	diaLabel.TextXAlignment         = Enum.TextXAlignment.Center
	diaLabel.ZIndex                 = 34
	diaLabel.Parent                 = dc

	-- Ícone central
	local iconLbl = Instance.new("TextLabel")
	local iconTxt
	if r.specialBox then
		iconTxt = "✨"
	elseif r.itemCategories then
		iconTxt = "🎀"
	else
		iconTxt = "💰"
	end
	iconLbl.Text                   = iconTxt
	iconLbl.TextSize               = 28
	iconLbl.Font                   = Enum.Font.GothamBold
	iconLbl.BackgroundTransparency = 1
	iconLbl.Size                   = UDim2.new(1, 0, 0, 36)
	iconLbl.Position               = UDim2.new(0, 0, 0, 26)
	iconLbl.TextXAlignment         = Enum.TextXAlignment.Center
	iconLbl.ZIndex                 = 34
	iconLbl.Parent                 = dc

	-- Valor
	local valorLbl = Instance.new("TextLabel")
	local valorTxt
	if r.specialBox then
		valorTxt = "RARO"
	elseif r.coins >= 1000 then
		valorTxt = string.format("%.0fK", r.coins / 1000)
	else
		valorTxt = tostring(r.coins)
	end
	valorLbl.Text                   = "💰 " .. valorTxt
	valorLbl.TextSize               = 11
	valorLbl.Font                   = Enum.Font.GothamBold
	valorLbl.TextColor3             = Color3.fromRGB(180, 140, 0)
	valorLbl.BackgroundTransparency = 1
	valorLbl.Size                   = UDim2.new(1, 0, 0, 18)
	valorLbl.Position               = UDim2.new(0, 0, 0, 64)
	valorLbl.TextXAlignment         = Enum.TextXAlignment.Center
	valorLbl.ZIndex                 = 34
	valorLbl.Parent                 = dc

	-- Badge de estado (✅ coletado ou "HOJE")
	local badge = Instance.new("TextLabel")
	badge.Text                   = ""
	badge.TextSize               = 9
	badge.Font                   = Enum.Font.GothamBold
	badge.TextColor3             = C_BRANCO
	badge.BackgroundColor3       = C_VERDE
	badge.BackgroundTransparency = 1
	badge.BorderSizePixel        = 0
	badge.Size                   = UDim2.new(1, -8, 0, 18)
	badge.Position               = UDim2.new(0, 4, 0, 86)
	badge.TextXAlignment         = Enum.TextXAlignment.Center
	badge.ZIndex                 = 34
	badge.Parent                 = dc
	addCorner(badge, 6)

	diaCards[i] = { frame = dc, stroke = stroke, badge = badge, icon = iconLbl }
end

-- ─────────────────────────────────────────────────────────────
-- Botão de coletar / countdown
-- ─────────────────────────────────────────────────────────────

local coletarBtn = Instance.new("TextButton")
coletarBtn.Text             = "🎁  COLETAR RECOMPENSA!"
coletarBtn.TextSize         = 18
coletarBtn.Font             = Enum.Font.GothamBold
coletarBtn.TextColor3       = C_ESCURO
coletarBtn.Size             = UDim2.new(1, -40, 0, 54)
coletarBtn.AnchorPoint      = Vector2.new(0.5, 0)
coletarBtn.Position         = UDim2.new(0.5, 0, 0, 244)
coletarBtn.BackgroundColor3 = C_SECUNDARIA
coletarBtn.BorderSizePixel  = 0
coletarBtn.AutoButtonColor  = false
coletarBtn.ZIndex           = 32
coletarBtn.Parent           = card
addCorner(coletarBtn, 14)
addStroke(coletarBtn, Color3.fromRGB(200, 160, 0), 1.5)

-- Animação de pulso quando disponível
local pulsoBtnTween = TweenService:Create(coletarBtn,
	TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ BackgroundColor3 = Color3.fromRGB(255, 230, 50) })

-- Descrição da recompensa atual
local descRecomp = Instance.new("TextLabel")
descRecomp.Text                   = ""
descRecomp.TextSize               = 14
descRecomp.Font                   = Enum.Font.Gotham
descRecomp.TextColor3             = C_CINZA
descRecomp.BackgroundTransparency = 1
descRecomp.Size                   = UDim2.new(1, -20, 0, 28)
descRecomp.Position               = UDim2.new(0, 10, 0, 308)
descRecomp.TextXAlignment         = Enum.TextXAlignment.Center
descRecomp.TextWrapped            = true
descRecomp.ZIndex                 = 32
descRecomp.Parent                 = card

-- Info de streak máximo
local highStreakLbl = Instance.new("TextLabel")
highStreakLbl.Text                   = ""
highStreakLbl.TextSize               = 12
highStreakLbl.Font                   = Enum.Font.Gotham
highStreakLbl.TextColor3             = Color3.fromRGB(160, 140, 180)
highStreakLbl.BackgroundTransparency = 1
highStreakLbl.Size                   = UDim2.new(1, -20, 0, 22)
highStreakLbl.Position               = UDim2.new(0, 10, 0, 344)
highStreakLbl.TextXAlignment         = Enum.TextXAlignment.Center
highStreakLbl.ZIndex                 = 32
highStreakLbl.Parent                 = card

-- Toast dentro do card
local toastCard = Instance.new("TextLabel")
toastCard.Text                   = ""
toastCard.TextSize               = 14
toastCard.Font                   = Enum.Font.GothamBold
toastCard.TextColor3             = C_BRANCO
toastCard.BackgroundColor3       = C_VERDE
toastCard.BackgroundTransparency = 1
toastCard.BorderSizePixel        = 0
toastCard.Size                   = UDim2.new(1, -40, 0, 36)
toastCard.AnchorPoint            = Vector2.new(0.5, 0)
toastCard.Position               = UDim2.new(0.5, 0, 0, 376)
toastCard.TextXAlignment         = Enum.TextXAlignment.Center
toastCard.Visible                = false
toastCard.ZIndex                 = 32
toastCard.Parent                 = card
addCorner(toastCard, 8)

-- ─────────────────────────────────────────────────────────────
-- Atualiza visual dos cards de dia
-- ─────────────────────────────────────────────────────────────

local function atualizarCards(streak: number, diaAtual: number, canClaim: boolean)
	for i, dc in ipairs(diaCards) do
		local coletado = i < diaAtual or (i == diaAtual and not canClaim)
		local eHoje    = (i == diaAtual)

		if coletado then
			dc.frame.BackgroundColor3 = Color3.fromRGB(230, 255, 235)
			dc.stroke.Color           = C_VERDE
			dc.badge.Text             = "✅ Coletado"
			dc.badge.BackgroundColor3 = C_VERDE
			dc.badge.BackgroundTransparency = 0
		elseif eHoje and canClaim then
			dc.frame.BackgroundColor3 = Color3.fromRGB(255, 250, 225)
			dc.stroke.Color           = C_SECUNDARIA
			dc.badge.Text             = "★ HOJE"
			dc.badge.BackgroundColor3 = C_LARANJA
			dc.badge.BackgroundTransparency = 0
			-- Pulsa o ícone do dia atual
			TweenService:Create(dc.icon,
				TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ TextSize = 32 }):Play()
		else
			dc.frame.BackgroundColor3 = Color3.fromRGB(250, 240, 250)
			dc.stroke.Color           = Color3.fromRGB(220, 200, 230)
			dc.badge.Text             = ""
			dc.badge.BackgroundTransparency = 1
		end
	end

	local r = DailyConfig.Rewards[diaAtual]
	if r then
		local desc = "Recompensa dia " .. diaAtual .. ": 💰 " .. tostring(r.coins) .. " moedas"
		if r.itemCategories then desc = desc .. " + item aleatório 🎀" end
		if r.specialBox then desc = desc .. " + item RARO ✨" end
		descRecomp.Text = desc
	end
end

-- ─────────────────────────────────────────────────────────────
-- Countdown em tempo real
-- ─────────────────────────────────────────────────────────────

local function iniciarCountdown(segundos: number)
	if countdownThread then
		task.cancel(countdownThread)
		countdownThread = nil
	end
	pulsoBtnTween:Cancel()
	coletarBtn.BackgroundColor3 = C_CINZA
	coletarBtn.TextColor3       = C_BRANCO
	coletarBtn.Active           = false

	local restante = segundos
	countdownThread = task.spawn(function()
		while restante > 0 and painelAberto do
			coletarBtn.Text = "⏳ Volte em " .. fmtTime(restante)
			task.wait(1)
			restante -= 1
		end
		if restante <= 0 then
			statusAtual.canClaim = true
			coletarBtn.Text             = "🎁  COLETAR RECOMPENSA!"
			coletarBtn.BackgroundColor3 = C_SECUNDARIA
			coletarBtn.TextColor3       = C_ESCURO
			coletarBtn.Active           = true
			pulsoBtnTween:Play()
			atualizarCards(statusAtual.currentStreak, statusAtual.diaAtual, true)
		end
	end)
end

-- ─────────────────────────────────────────────────────────────
-- Abre / fecha
-- ─────────────────────────────────────────────────────────────

local function fechar()
	painelAberto = false
	if countdownThread then
		task.cancel(countdownThread)
		countdownThread = nil
	end
	pulsoBtnTween:Cancel()
	TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Size = UDim2.fromOffset(0, 0) }):Play()
	task.delay(0.2, function()
		overlay.Visible = false
		card.Visible    = false
	end)
end

local function abrir()
	if painelAberto then return end
	painelAberto = true

	streakLbl.Text   = "Streak atual: " .. statusAtual.currentStreak .. " dia(s) 🔥"
	highStreakLbl.Text = "Maior streak: " .. (statusAtual.highestStreak or 0) .. " dias"

	atualizarCards(statusAtual.currentStreak, statusAtual.diaAtual, statusAtual.canClaim)

	if statusAtual.canClaim then
		coletarBtn.Text             = "🎁  COLETAR RECOMPENSA!"
		coletarBtn.BackgroundColor3 = C_SECUNDARIA
		coletarBtn.TextColor3       = C_ESCURO
		coletarBtn.Active           = true
		pulsoBtnTween:Play()
	else
		iniciarCountdown(statusAtual.timeUntilNext)
	end

	overlay.Visible = true
	card.Visible    = true
	card.Size       = UDim2.fromOffset(0, 0)
	TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(500, 440) }):Play()
end

openBE.Event:Connect(abrir)
closeBtn.Activated:Connect(fechar)
overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		fechar()
	end
end)

-- ─────────────────────────────────────────────────────────────
-- Animação de coleta
-- ─────────────────────────────────────────────────────────────

local function animarColeta(result)
	-- Partículas douradas no card
	local att = Instance.new("Attachment")
	att.Parent = playerGui

	local p = Instance.new("ParticleEmitter")
	p.Color         = ColorSequence.new(C_SECUNDARIA)
	p.LightEmission = 0.8
	p.LightInfluence= 0
	p.Rate          = 60
	p.Lifetime      = NumberRange.new(0.5, 1.2)
	p.Speed         = NumberRange.new(5, 15)
	p.Size          = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
	p.Transparency  = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	p.SpreadAngle   = Vector2.new(180, 180)
	p.Parent        = att
	task.delay(0.5, function() p.Enabled = false end)
	task.delay(2, function() att:Destroy() end)

	-- 3 labels voando para o canto superior esquerdo
	for k = 1, 3 do
		task.delay(k * 0.15, function()
			local lbl = Instance.new("TextLabel")
			lbl.Text             = "+" .. tostring(result.coins) .. "💰"
			lbl.TextSize         = 18
			lbl.Font             = Enum.Font.GothamBold
			lbl.TextColor3       = C_SECUNDARIA
			lbl.BackgroundTransparency = 1
			lbl.Size             = UDim2.fromOffset(140, 30)
			lbl.Position         = UDim2.new(0.5, -70, 0.5, 0)
			lbl.ZIndex           = 50
			lbl.TextStrokeTransparency = 0.5
			lbl.Parent           = gui

			TweenService:Create(lbl, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position         = UDim2.new(0, 80, 0, 60),
				TextTransparency = 1,
				TextStrokeTransparency = 1,
			}):Play()
			task.delay(0.85, function() lbl:Destroy() end)
		end)
	end

	-- Se ganhou item: mini popup
	if result.item then
		task.delay(0.5, function()
			local popup = Instance.new("Frame")
			popup.Size            = UDim2.fromOffset(240, 70)
			popup.AnchorPoint     = Vector2.new(0.5, 0)
			popup.Position        = UDim2.new(0.5, 0, 0.3, 0)
			popup.BackgroundColor3 = Color3.fromRGB(40, 30, 45)
			popup.BackgroundTransparency = 0.1
			popup.BorderSizePixel = 0
			popup.ZIndex          = 60
			popup.Parent          = gui
			addCorner(popup, 10)
			addStroke(popup, C_SECUNDARIA, 1.5)

			local img = Instance.new("ImageLabel")
			img.Size             = UDim2.fromOffset(50, 50)
			img.Position         = UDim2.fromOffset(10, 10)
			img.BackgroundTransparency = 1
			img.Image            = string.format("rbxthumb://type=Asset&id=%d&w=100&h=100", result.item.id)
			img.ZIndex           = 61
			img.Parent           = popup

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Text                   = "🎀 " .. (result.item.name or "Item ganho!")
			nameLbl.TextSize               = 12
			nameLbl.Font                   = Enum.Font.GothamBold
			nameLbl.TextColor3             = Color3.new(1, 1, 1)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Size                   = UDim2.new(1, -70, 1, 0)
			nameLbl.Position               = UDim2.fromOffset(68, 0)
			nameLbl.TextWrapped            = true
			nameLbl.ZIndex                 = 61
			nameLbl.Parent                 = popup

			TweenService:Create(popup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Position = UDim2.new(0.5, 0, 0.25, 0) }):Play()
			task.delay(3, function()
				TweenService:Create(popup, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
				task.delay(0.25, function() popup:Destroy() end)
			end)
		end)
	end
end

-- ─────────────────────────────────────────────────────────────
-- Eventos do servidor
-- ─────────────────────────────────────────────────────────────

DailyRewardStatusEvent.OnClientEvent:Connect(function(status)
	statusAtual = status
	statusAtual.highestStreak = status.highestStreak or 0

	-- Badge no botão da barra (via BindableEvent em ClientUI)
	local badgeBE = playerGui:FindFirstChild("SetDailyBadgeBE")
	if badgeBE then
		badgeBE:Fire(status.canClaim)
	end

	-- Abre automaticamente após 2s se tiver recompensa disponível
	if status.canClaim then
		task.delay(2, function()
			if not painelAberto then
				abrir()
			end
		end)
	end
end)

DailyRewardResultEvent.OnClientEvent:Connect(function(result)
	if not result.success then
		toastCard.Text             = "❌ " .. (result.reason or "Erro")
		toastCard.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
		toastCard.Visible          = true
		task.delay(2.5, function() toastCard.Visible = false end)
		return
	end

	-- Atualiza estado
	statusAtual.currentStreak = result.streak
	statusAtual.canClaim      = false
	statusAtual.diaAtual      = (result.streak % DailyConfig.MaxStreak) + 1
	statusAtual.timeUntilNext = DailyConfig.ClaimCooldown

	-- Atualiza badge
	local badgeBE = playerGui:FindFirstChild("SetDailyBadgeBE")
	if badgeBE then badgeBE:Fire(false) end

	-- Atualiza visual
	streakLbl.Text = "Streak atual: " .. result.streak .. " dia(s) 🔥"
	atualizarCards(result.streak, statusAtual.diaAtual, false)
	iniciarCountdown(DailyConfig.ClaimCooldown)

	-- Animação
	animarColeta(result)

	-- Toast
	toastCard.Text             = "✅ Recompensa do dia " .. result.day .. " coletada!"
	toastCard.BackgroundColor3 = C_VERDE
	toastCard.Visible          = true
	task.delay(3, function() toastCard.Visible = false end)
end)

-- ─────────────────────────────────────────────────────────────
-- Botão coletar
-- ─────────────────────────────────────────────────────────────

coletarBtn.Activated:Connect(function()
	if not statusAtual.canClaim then return end
	coletarBtn.Active = false
	coletarBtn.Text   = "Coletando..."
	ClaimDailyRewardEvent:FireServer()
end)

print("[DailyRewardUI] Pronto.")
