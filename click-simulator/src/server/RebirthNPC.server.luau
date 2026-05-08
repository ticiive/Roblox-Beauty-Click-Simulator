local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

-- ─────────────────────────────────────────────────────────────
-- Remotes
-- ─────────────────────────────────────────────────────────────

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local function getOrCreate(name: string, className: string)
	local ex = Remotes:FindFirstChild(name)
	if ex then return ex end
	local obj = Instance.new(className)
	obj.Name   = name
	obj.Parent = Remotes
	return obj
end

local RebirthConfirmEvent = getOrCreate("RebirthConfirmEvent", "RemoteEvent")

-- ─────────────────────────────────────────────────────────────
-- Posição: dentro da Loja-Roupa ou fallback
-- ─────────────────────────────────────────────────────────────

local function getPosicao(): Vector3
	local loja = Workspace:FindFirstChild("Loja-Roupa")
	if loja then
		local ok, piv = pcall(function() return loja:GetPivot() end)
		if ok then
			return piv.Position + Vector3.new(10, 0, -15)
		end
	end
	return Vector3.new(0, 5, -20)
end

-- ─────────────────────────────────────────────────────────────
-- Aguarda pasta StoreDecoration (até 10s)
-- ─────────────────────────────────────────────────────────────

local decorFolder = nil
for _ = 1, 10 do
	decorFolder = Workspace:FindFirstChild("StoreDecoration")
	if decorFolder then break end
	task.wait(1)
end
if not decorFolder then
	decorFolder = Instance.new("Folder")
	decorFolder.Name   = "StoreDecoration"
	decorFolder.Parent = Workspace
end

-- ─────────────────────────────────────────────────────────────
-- Constrói o NPC
-- ─────────────────────────────────────────────────────────────

local pos = getPosicao()

local npcModel = Instance.new("Model")
npcModel.Name  = "RebirthNPC"

-- Base cilíndrica dourada
local base        = Instance.new("Part")
base.Name         = "Base"
base.Shape        = Enum.PartType.Cylinder
base.Size         = Vector3.new(1, 4, 4)
base.CFrame       = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2)
base.Material     = Enum.Material.Neon
base.Color        = Color3.fromRGB(212, 175, 55)
base.Anchored     = true
base.CanCollide   = true
base.Parent       = npcModel

-- Corpo esférico em cima
local corpo       = Instance.new("Part")
corpo.Name        = "Corpo"
corpo.Shape       = Enum.PartType.Ball
corpo.Size        = Vector3.new(3, 3, 3)
corpo.CFrame      = CFrame.new(pos + Vector3.new(0, 3.5, 0))
corpo.Material    = Enum.Material.Neon
corpo.Color       = Color3.fromRGB(255, 215, 0)
corpo.Anchored    = true
corpo.CanCollide  = false
corpo.Parent      = npcModel

-- Aura de partículas douradas
local particulas  = Instance.new("ParticleEmitter")
particulas.Color          = ColorSequence.new(Color3.fromRGB(255, 215, 0))
particulas.LightEmission  = 1
particulas.LightInfluence = 0
particulas.Rate           = 15
particulas.Lifetime       = NumberRange.new(1, 2)
particulas.Speed          = NumberRange.new(2, 4)
particulas.Size           = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.3),
	NumberSequenceKeypoint.new(1, 0),
})
particulas.Transparency   = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(1, 1),
})
particulas.SpreadAngle    = Vector2.new(360, 360)
particulas.RotSpeed       = NumberRange.new(-45, 45)
particulas.Parent         = corpo

-- Luz pontual
local luz         = Instance.new("PointLight")
luz.Color         = Color3.fromRGB(255, 215, 0)
luz.Brightness    = 3
luz.Range         = 20
luz.Shadows       = true
luz.Parent        = corpo

-- BillboardGui
local bb          = Instance.new("BillboardGui")
bb.Size           = UDim2.fromOffset(200, 80)
bb.StudsOffset    = Vector3.new(0, 4, 0)
bb.AlwaysOnTop    = false
bb.Parent         = corpo

local bbFundo     = Instance.new("Frame")
bbFundo.Size                    = UDim2.fromScale(1, 1)
bbFundo.BackgroundColor3        = Color3.fromRGB(18, 12, 28)
bbFundo.BackgroundTransparency  = 0.2
bbFundo.BorderSizePixel         = 0
bbFundo.Parent                  = bb
local bbCorner = Instance.new("UICorner", bbFundo)
bbCorner.CornerRadius = UDim.new(0, 8)

local bbTitulo    = Instance.new("TextLabel")
bbTitulo.Text     = "🔄 REBIRTH"
bbTitulo.TextSize = 20
bbTitulo.Font     = Enum.Font.GothamBold
bbTitulo.TextColor3 = Color3.fromRGB(255, 215, 0)
bbTitulo.BackgroundTransparency = 1
bbTitulo.Size     = UDim2.new(1, 0, 0.55, 0)
bbTitulo.TextXAlignment = Enum.TextXAlignment.Center
bbTitulo.Parent   = bbFundo

local bbCusto     = Instance.new("TextLabel")
bbCusto.Text      = "100.000 💰"
bbCusto.TextSize  = 14
bbCusto.Font      = Enum.Font.Gotham
bbCusto.TextColor3 = Color3.new(1, 1, 1)
bbCusto.BackgroundTransparency = 1
bbCusto.Size      = UDim2.new(1, 0, 0.45, 0)
bbCusto.Position  = UDim2.new(0, 0, 0.55, 0)
bbCusto.TextXAlignment = Enum.TextXAlignment.Center
bbCusto.Parent    = bbFundo

-- ProximityPrompt
local prompt      = Instance.new("ProximityPrompt")
prompt.ActionText            = "Fazer Rebirth"
prompt.ObjectText            = "🔄 Reset tudo por +10%"
prompt.HoldDuration          = 2
prompt.MaxActivationDistance = 8
prompt.RequiresLineOfSight   = false
prompt.Parent                = corpo

npcModel.PrimaryPart = base
npcModel.Parent      = decorFolder

-- ─────────────────────────────────────────────────────────────
-- Atualiza billboard baseado nas moedas do jogador
-- ─────────────────────────────────────────────────────────────

local MIN_COINS = 100000

task.spawn(function()
	while not _G.PlayerData do task.wait(0.1) end

	while true do
		task.wait(2)
		for _, player in Players:GetPlayers() do
			local dados = _G.PlayerData[player.UserId]
			if dados and dados.coins < MIN_COINS then
				-- Billboard já mostra info suficiente; aviso extra via prompt ObjectText
				-- não conseguimos personalizar billboard por jogador facilmente
			end
		end
	end
end)

-- ─────────────────────────────────────────────────────────────
-- Triggered: pede confirmação ao cliente
-- ─────────────────────────────────────────────────────────────

prompt.Triggered:Connect(function(player: Player)
	RebirthConfirmEvent:FireClient(player)
	print("[RebirthNPC] Confirmação enviada para", player.Name)
end)

print("[RebirthNPC] NPC criado em", tostring(pos))
