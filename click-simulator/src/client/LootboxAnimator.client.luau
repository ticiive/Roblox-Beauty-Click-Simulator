local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Debris            = game:GetService("Debris")

local Remotes              = ReplicatedStorage:WaitForChild("Remotes")
local PlayLootboxAnimEvent = Remotes:WaitForChild("PlayLootboxAnimEvent")

-- Evita reentrada: uma animação por caixa por vez
local busyBoxes = {}

local function playAnim(boxId: string, item: { id: number, name: string })
	if busyBoxes[boxId] then return end
	busyBoxes[boxId] = true

	local lootboxFolder = Workspace:WaitForChild("Lootboxes", 15)
	if not lootboxFolder then busyBoxes[boxId] = nil ; return end

	local model = lootboxFolder:FindFirstChild(boxId)
	if not model then busyBoxes[boxId] = nil ; return end

	local light     = model:FindFirstChildWhichIsA("PointLight",      true)
	local particles = model:FindFirstChildWhichIsA("ParticleEmitter", true)
	local pad       = model:FindFirstChild("Pad")

	-- Estado original para restaurar depois
	local origBrightness = light     and light.Brightness or 2
	local origRate       = particles and particles.Rate    or 8
	local origPivot      = model:GetPivot()

	local origTransp: { [BasePart]: number } = {}
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p ~= pad then
			origTransp[p] = p.Transparency
		end
	end

	-- ── FASE 1: build-up — 0.8s ──────────────────────────────
	if light     then TweenService:Create(light, TweenInfo.new(0.8), { Brightness = 8 }):Play() end
	if particles then particles.Rate = 30 end

	local chargeSound = Instance.new("Sound")
	chargeSound.SoundId = "rbxassetid://9114925902"
	chargeSound.Volume  = 0.6
	chargeSound.Parent  = Workspace
	chargeSound:Play()
	Debris:AddItem(chargeSound, 5)

	local shaking = true
	task.spawn(function()
		local t = 0
		while shaking do
			t += 0.05
			model:PivotTo(origPivot * CFrame.new(
				math.sin(t * 13) * 0.12,
				math.cos(t * 19) * 0.06,
				math.sin(t * 11) * 0.10
			))
			task.wait(0.05)
		end
		model:PivotTo(origPivot)
	end)

	task.wait(0.8)

	-- ── FASE 2: abertura — 0.5s ──────────────────────────────
	shaking = false
	task.wait(0.1)  -- garante que o shake coroutine parou

	local openSound = Instance.new("Sound")
	openSound.SoundId = "rbxassetid://5153734608"
	openSound.Volume  = 0.8
	openSound.Parent  = Workspace
	openSound:Play()
	Debris:AddItem(openSound, 5)

	if particles then
		particles:Emit(80)
		particles.Rate = 0
	end

	for p in origTransp do
		TweenService:Create(p, TweenInfo.new(0.35), { Transparency = 1 }):Play()
	end

	task.wait(0.5)

	-- ── FASE 3: item revelado — 1.5s ─────────────────────────
	local boxPos = origPivot.Position

	local floatPart = Instance.new("Part")
	floatPart.Size         = Vector3.new(0.1, 0.1, 0.1)
	floatPart.Transparency = 1
	floatPart.Anchored     = true
	floatPart.CanCollide   = false
	floatPart.CastShadow   = false
	floatPart.CFrame       = CFrame.new(boxPos)
	floatPart.Parent       = Workspace
	Debris:AddItem(floatPart, 10)

	local colLight = Instance.new("PointLight")
	colLight.Color      = Color3.new(1, 1, 1)
	colLight.Brightness = 6
	colLight.Range      = 20
	colLight.Parent     = floatPart

	local bb = Instance.new("BillboardGui")
	bb.Size        = UDim2.fromOffset(180, 180)
	bb.StudsOffset = Vector3.new(0, 1, 0)
	bb.AlwaysOnTop = false
	bb.Parent      = floatPart

	local thumbImg = Instance.new("ImageLabel")
	thumbImg.Size                = UDim2.fromScale(1, 1)
	thumbImg.BackgroundTransparency = 1
	thumbImg.ScaleType           = Enum.ScaleType.Fit
	thumbImg.ImageTransparency   = 0
	thumbImg.Image               = string.format("rbxthumb://type=Asset&id=%d&w=420&h=420", item.id)
	thumbImg.Parent              = bb

	-- Float + spin num único loop para evitar conflito de CFrame
	local floating = true
	task.spawn(function()
		local t = 0
		while floating do
			t += 0.03
			local progress = math.min(t / 1.5, 1)
			local ease = 1 - (1 - progress) ^ 2  -- quadratic ease-out
			floatPart.CFrame = CFrame.new(boxPos + Vector3.new(0, ease * 5, 0))
				* CFrame.Angles(0, math.rad(t * 200), 0)
			task.wait(0.03)
		end
	end)

	task.wait(1.5)

	-- ── FASE 4: cleanup — 0.5s ───────────────────────────────
	floating = false
	task.wait(0.05)

	TweenService:Create(thumbImg,  TweenInfo.new(0.4), { ImageTransparency = 1 }):Play()
	TweenService:Create(colLight,  TweenInfo.new(0.4), { Brightness = 0 }):Play()

	for p, origT in origTransp do
		if p and p.Parent then
			TweenService:Create(p, TweenInfo.new(0.4), { Transparency = origT }):Play()
		end
	end

	if light then
		TweenService:Create(light, TweenInfo.new(0.4), { Brightness = origBrightness }):Play()
	end
	if particles then
		particles.Rate = origRate
	end

	task.wait(0.5)
	busyBoxes[boxId] = nil
	-- floatPart destruído pelo Debris após 10s
end

PlayLootboxAnimEvent.OnClientEvent:Connect(function(boxId, item)
	task.spawn(playAnim, boxId, item)
end)

print("[LootboxAnimator] Pronto.")
