-- Interface Boutique de Luxo + Loja de Roupas com personalização de personagem.
-- Nunca modifica dados diretamente — apenas envia eventos ao servidor.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared     = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local ClickEvent        = ReplicatedStorage:WaitForChild("ClickEvent")
local BuyUpgradeEvent   = ReplicatedStorage:WaitForChild("BuyUpgradeEvent")
local UpdateStatsEvent  = ReplicatedStorage:WaitForChild("UpdateStatsEvent")
local ClothingEvent     = ReplicatedStorage:WaitForChild("ClothingEvent")
local UpdateOutfitEvent = ReplicatedStorage:WaitForChild("UpdateOutfitEvent")

local statsAtuais   = { coins = 0, clickPower = 1, totalClicks = 0 }
local outfitAtual   = {}   -- { skin=1, shirt=1, pants=1 }
local roupasOwned   = {}   -- { ["skin_1"]=true, ... }

-- ─────────────────────────────────────────────────────────────
-- Paleta Boutique de Luxo
-- ─────────────────────────────────────────────────────────────

local C_FUNDO    = Color3.fromRGB(10, 6, 16)
local C_OURO     = Color3.fromRGB(212, 175, 55)
local C_TEXTO    = Color3.fromRGB(255, 245, 228)
local C_SUBTEXTO = Color3.fromRGB(160, 148, 130)
local C_VERDE    = Color3.fromRGB(60, 190, 120)
local C_CINZA    = Color3.fromRGB(55, 48, 68)
local C_BOTAO    = Color3.fromRGB(22, 14, 36)
local C_ABA_ON   = Color3.fromRGB(35, 24, 55)
local C_ABA_OFF  = Color3.fromRGB(16, 10, 28)

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
local atualizarPainelRoupa

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
-- PAINEL DE ROUPAS — esquerda, com abas por categoria
-- ─────────────────────────────────────────────────────────────

local ROUPA_W        = 260
local ROUPA_H        = 370
local POS_ROUPA_ABERTA  = UDim2.new(0, 16, 0.5, -ROUPA_H / 2)
local POS_ROUPA_FECHADA = UDim2.new(0, -ROUPA_W - 20, 0.5, -ROUPA_H / 2)
local roupaAberta    = false
local abaAtual       = 1    -- índice da categoria ativa

local roupaFrame = Instance.new("Frame")
roupaFrame.Size                   = UDim2.new(0, ROUPA_W, 0, ROUPA_H)
roupaFrame.Position               = POS_ROUPA_FECHADA
roupaFrame.BackgroundColor3       = C_FUNDO
roupaFrame.BackgroundTransparency = 0.08
roupaFrame.BorderSizePixel        = 0
roupaFrame.Parent                 = screenGui
arredondar(roupaFrame, UDim.new(0, 14))
borda(roupaFrame, C_OURO)

-- Título
local roupaTitulo = Instance.new("TextLabel")
roupaTitulo.Size                   = UDim2.new(1, 0, 0, 32)
roupaTitulo.Position               = UDim2.new(0, 0, 0, 8)
roupaTitulo.BackgroundTransparency = 1
roupaTitulo.Text                   = "✦  ROUPAS  ✦"
roupaTitulo.TextColor3             = C_OURO
roupaTitulo.TextSize               = 14
roupaTitulo.Font                   = Enum.Font.GothamBold
roupaTitulo.Parent                 = roupaFrame
linhaDecorativa(roupaFrame, 36)

-- Abas de categoria (Pele | Camisa | Calça)
local ABA_H   = 32
local abaButtons: { TextButton } = {}

for i, cat in ipairs(GameConfig.ClothingCategories) do
	local abaPosX = (i - 1) * (ROUPA_W / #GameConfig.ClothingCategories)
	local abaW    = ROUPA_W / #GameConfig.ClothingCategories

	local aba = Instance.new("TextButton")
	aba.Size             = UDim2.new(0, abaW - 4, 0, ABA_H)
	aba.Position         = UDim2.new(0, abaPosX + 2, 0, 42)
	aba.BackgroundColor3 = C_ABA_OFF
	aba.BorderSizePixel  = 0
	aba.Text             = cat.name
	aba.TextColor3       = C_SUBTEXTO
	aba.TextSize         = 12
	aba.Font             = Enum.Font.GothamBold
	aba.Parent           = roupaFrame
	arredondar(aba, UDim.new(0, 8))

	local idx = i
	aba.MouseButton1Click:Connect(function()
		abaAtual = idx
		atualizarPainelRoupa()
	end)
	abaButtons[i] = aba
end

-- Área de scroll com os swatches
local swatchArea = Instance.new("ScrollingFrame")
swatchArea.Size              = UDim2.new(1, -12, 1, -(42 + ABA_H + 10))
swatchArea.Position          = UDim2.new(0, 6, 0, 42 + ABA_H + 6)
swatchArea.BackgroundTransparency = 1
swatchArea.BorderSizePixel   = 0
swatchArea.ScrollBarThickness = 4
swatchArea.ScrollBarImageColor3 = C_OURO
swatchArea.CanvasSize        = UDim2.new(0, 0, 0, 0)
swatchArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
swatchArea.Parent            = roupaFrame

local swatchGrid = Instance.new("UIGridLayout")
swatchGrid.CellSize     = UDim2.new(0, 108, 0, 108)
swatchGrid.CellPadding  = UDim2.new(0, 8, 0, 8)
swatchGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
swatchGrid.Parent       = swatchArea

local swatchPadding = Instance.new("UIPadding")
swatchPadding.PaddingTop    = UDim.new(0, 6)
swatchPadding.PaddingBottom = UDim.new(0, 6)
swatchPadding.Parent        = swatchArea

-- Swatches dinâmicos (recriados quando muda aba)
local swatchButtons: { Frame } = {}
local swatchRefs: { { bordaStatus: UIStroke, preco: TextLabel } } = {}

local function limparSwatches()
	for _, s in swatchButtons do s:Destroy() end
	table.clear(swatchButtons)
	table.clear(swatchRefs)
end

local function criarSwatches(catIndex: number)
	limparSwatches()
	local cat = GameConfig.ClothingCategories[catIndex]
	if not cat then return end

	for itemIdx, item in ipairs(cat.items) do
		local card = Instance.new("Frame")
		card.Size             = UDim2.new(0, 108, 0, 108)
		card.BackgroundColor3 = C_BOTAO
		card.BorderSizePixel  = 0
		card.Parent           = swatchArea
		arredondar(card, UDim.new(0, 10))

		-- Quadrado de cor
		local swatch = Instance.new("Frame")
		swatch.Size             = UDim2.new(1, -12, 0, 56)
		swatch.Position         = UDim2.new(0, 6, 0, 6)
		swatch.BackgroundColor3 = item.color
		swatch.BorderSizePixel  = 0
		swatch.Parent           = card
		arredondar(swatch, UDim.new(0, 8))

		-- Nome
		local nome = Instance.new("TextLabel")
		nome.Size                   = UDim2.new(1, -8, 0, 18)
		nome.Position               = UDim2.new(0, 4, 0, 65)
		nome.BackgroundTransparency = 1
		nome.Text                   = item.name
		nome.TextColor3             = C_TEXTO
		nome.TextSize               = 11
		nome.Font                   = Enum.Font.GothamBold
		nome.TextTruncate           = Enum.TextTruncate.AtEnd
		nome.Parent                 = card

		-- Preço / status
		local preco = Instance.new("TextLabel")
		preco.Size                   = UDim2.new(1, -8, 0, 16)
		preco.Position               = UDim2.new(0, 4, 0, 84)
		preco.BackgroundTransparency = 1
		preco.TextSize               = 10
		preco.Font                   = Enum.Font.Gotham
		preco.Parent                 = card

		-- Botão invisível sobre o card
		local btn = Instance.new("TextButton")
		btn.Size             = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text             = ""
		btn.Parent           = card

		-- Borda de status (atualizada em atualizarPainelRoupa)
		local bordaStatus = borda(card, C_CINZA, 2)

		-- Referências para atualização posterior
		card:SetAttribute("catKey",   cat.key)
		card:SetAttribute("itemIdx",  itemIdx)
		card:SetAttribute("itemCost", item.cost)
		card.Name = cat.key .. "_" .. itemIdx

		-- Store refs
		card:SetAttribute("_preco", true)

		-- Ação de compra/equip
		btn.MouseButton1Click:Connect(function()
			local ownedKey = cat.key .. "_" .. itemIdx
			local action   = roupasOwned[ownedKey] and "equip" or "buy"
			ClothingEvent:FireServer(action, cat.key, itemIdx)
		end)

		-- Guarda card e refs em tabelas Lua paralelas (nunca em propriedades de Instance)
		table.insert(swatchButtons, card)
		table.insert(swatchRefs, { bordaStatus = bordaStatus, preco = preco })
	end
end

-- ─────────────────────────────────────────────────────────────
-- Tweens do painel de roupas
-- ─────────────────────────────────────────────────────────────

local tweenRoupaAbrir = TweenService:Create(roupaFrame,
	TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	{ Position = POS_ROUPA_ABERTA })
local tweenRoupaFechar = TweenService:Create(roupaFrame,
	TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	{ Position = POS_ROUPA_FECHADA })

-- ─────────────────────────────────────────────────────────────
-- Botões toggle (canto inferior direito)
-- ─────────────────────────────────────────────────────────────

local function novaBtnToggle(emoji: string, posY: number): TextButton
	local btn = Instance.new("TextButton")
	btn.Size             = UDim2.new(0, 72, 0, 72)
	btn.Position         = UDim2.new(1, -88, 1, posY)
	btn.BackgroundColor3 = C_BOTAO
	btn.BorderSizePixel  = 0
	btn.Text             = emoji
	btn.TextSize         = 36
	btn.Font             = Enum.Font.GothamBold
	btn.Parent           = screenGui
	arredondar(btn, UDim.new(0, 18))
	borda(btn, C_OURO, 2)
	return btn
end

-- 👗 toggle boutique (upgrades)
local btnLoja  = novaBtnToggle("🛒", -88)
-- 👕 toggle roupas
local btnRoupa = novaBtnToggle("👕", -168)

-- Pulso suave no botão de roupas
local pulsoRoupa = TweenService:Create(btnRoupa,
	TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Size=UDim2.new(0, 78, 0, 78), Position=UDim2.new(1, -91, 1, -171) })
pulsoRoupa:Play()

-- Tweens boutique
local tweenLojaAbrir = TweenService:Create(lojaFrame,
	TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	{ Position = POS_LOJA_ABERTA })
local tweenLojaFechar = TweenService:Create(lojaFrame,
	TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	{ Position = POS_LOJA_FECHADA })

-- Pulso suave no botão de boutique
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

btnRoupa.MouseButton1Click:Connect(function()
	roupaAberta = not roupaAberta
	if roupaAberta then
		pulsoRoupa:Cancel()
		btnRoupa.Size     = UDim2.new(0, 72, 0, 72)
		btnRoupa.Position = UDim2.new(1, -88, 1, -168)
		tweenRoupaAbrir:Play()   -- abre o painel primeiro
		atualizarPainelRoupa()   -- depois popula o conteúdo
	else
		tweenRoupaFechar:Play()
		task.delay(0.25, function() pulsoRoupa:Play() end)
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

function atualizarPainelRoupa()
	-- Atualiza abas
	for i, aba in ipairs(abaButtons) do
		if i == abaAtual then
			aba.BackgroundColor3 = C_ABA_ON
			aba.TextColor3       = C_OURO
		else
			aba.BackgroundColor3 = C_ABA_OFF
			aba.TextColor3       = C_SUBTEXTO
		end
	end

	-- Recria swatches da aba ativa
	criarSwatches(abaAtual)

	local cat = GameConfig.ClothingCategories[abaAtual]
	if not cat then return end

	-- Atualiza visual de cada swatch
	for i, card in ipairs(swatchButtons) do
		local refs    = swatchRefs[i]
		if not refs then continue end

		local catKey   = card:GetAttribute("catKey")
		local itemIdx  = card:GetAttribute("itemIdx")
		local cost     = card:GetAttribute("itemCost")
		local ownedKey = catKey .. "_" .. itemIdx

		local isOwned    = roupasOwned[ownedKey] == true
		local isEquipped = outfitAtual[catKey] == itemIdx

		if isEquipped then
			refs.bordaStatus.Color     = C_OURO
			refs.bordaStatus.Thickness = 3
			refs.preco.Text            = "✓ Equipado"
			refs.preco.TextColor3      = C_OURO
		elseif isOwned then
			refs.bordaStatus.Color     = C_VERDE
			refs.bordaStatus.Thickness = 2
			refs.preco.Text            = "Equipar"
			refs.preco.TextColor3      = C_VERDE
		else
			refs.bordaStatus.Color     = C_CINZA
			refs.bordaStatus.Thickness = 1.5
			refs.preco.Text            = "💰 " .. fmt(cost)
			refs.preco.TextColor3      = statsAtuais.coins >= cost
				and C_TEXTO
				or  Color3.fromRGB(150, 80, 80)
		end
	end
end

function atualizarStats(dados: { coins: number, clickPower: number, totalClicks: number })
	statsAtuais = dados
	labelMoedas.Text  = "💰  Saldo:     " .. fmt(dados.coins)
	labelPoder.Text   = "✨  Estilo:    " .. fmt(dados.clickPower)
	labelCliques.Text = "👗  Criações:  " .. fmt(dados.totalClicks)
	atualizarBotoesLoja()
	if roupaAberta then atualizarPainelRoupa() end
end

-- ─────────────────────────────────────────────────────────────
-- Recebe dados do servidor
-- ─────────────────────────────────────────────────────────────

UpdateStatsEvent.OnClientEvent:Connect(atualizarStats)

UpdateOutfitEvent.OnClientEvent:Connect(function(
	outfit: { [string]: number },
	owned:  { [string]: boolean }
)
	outfitAtual = outfit
	roupasOwned = owned
	if roupaAberta then atualizarPainelRoupa() end
end)

-- Inicializa abas e swatches
atualizarPainelRoupa()

print("[ClientUI] Boutique + Loja de Roupas carregada.")
