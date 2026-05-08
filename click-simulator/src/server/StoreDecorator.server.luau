-- Manequins, cabideiros, cabides e body Andi para os jogadores.

local Players       = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local Workspace     = game:GetService("Workspace")

local ID_MANNEQUIN = 105156626214226
local ID_RACK      = 5146622096
local ID_HANGER    = 8350992766

-- ─────────────────────────────────────────────────────────────
-- Pasta isolada — não toca fora dela
-- ─────────────────────────────────────────────────────────────

local decorFolder = Instance.new("Folder")
decorFolder.Name   = "StoreDecoration"
decorFolder.Parent = Workspace

-- ─────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────

local function spawnAsset(assetId: number, cf: CFrame, canCollide: boolean?)
	local ok, loaded = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok or not loaded then
		warn("[StoreDecorator] Falha LoadAsset", assetId, ":", loaded)
		return nil
	end

	local model = loaded:FindFirstChildOfClass("Model") or loaded:GetChildren()[1]
	if not model then
		warn("[StoreDecorator] Asset vazio:", assetId)
		loaded:Destroy()
		return nil
	end

	model.Parent = nil
	loaded:Destroy()

	local col = (canCollide ~= false)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored   = true
			p.CanCollide = col
		end
	end

	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
	end
	if model.PrimaryPart then
		model:PivotTo(cf)
	end

	model.Parent = decorFolder
	return model
end

-- ─────────────────────────────────────────────────────────────
-- Obtém posições das lootboxes (aguarda até 10s)
-- ─────────────────────────────────────────────────────────────

local function getLootboxPositions()
	local folder = nil
	for _ = 1, 10 do
		folder = Workspace:FindFirstChild("Lootboxes")
		if folder and #folder:GetChildren() > 0 then break end
		task.wait(1)
	end

	if not folder or #folder:GetChildren() == 0 then
		warn("[StoreDecorator] Lootboxes não encontrado — posições padrão")
		local def = {}
		for i = 1, 4 do
			table.insert(def, Vector3.new(-80, 0, (i - 2.5) * 12))
		end
		return def
	end

	local positions = {}
	for _, child in folder:GetChildren() do
		local pos
		if child:IsA("Model") then
			if child.PrimaryPart then
				pos = child.PrimaryPart.Position
			else
				local ok2, piv = pcall(function() return child:GetPivot() end)
				if ok2 then pos = piv.Position end
			end
		elseif child:IsA("BasePart") then
			pos = child.Position
		end
		if pos then table.insert(positions, pos) end
	end

	table.sort(positions, function(a, b) return a.Z < b.Z end)
	return positions
end

-- ─────────────────────────────────────────────────────────────
-- Spawna decoração após Lootboxes estar pronto
-- ─────────────────────────────────────────────────────────────

task.spawn(function()
	local positions = getLootboxPositions()
	if #positions == 0 then
		warn("[StoreDecorator] Sem posições — decoração cancelada")
		return
	end

	local lookDir = Vector3.new(1, 0, 0)

	-- ── Manequins: 1 por lootbox, 15 studs à frente ──────────
	for _, boxPos in ipairs(positions) do
		local manPos = Vector3.new(boxPos.X + 15, boxPos.Y, boxPos.Z)
		local man = spawnAsset(ID_MANNEQUIN,
			CFrame.lookAt(manPos, manPos + lookDir))
		if man then
			print("[StoreDecorator] Manequim em", tostring(manPos))
		end
		task.wait(0.15)
	end

	-- ── Racks: 3 distribuídos em Z ao longo da parede ────────
	local sumZ, sumX, sumY = 0, 0, 0
	for _, p in ipairs(positions) do sumZ += p.Z; sumX += p.X; sumY += p.Y end
	local centerZ = sumZ / #positions
	local baseX   = sumX / #positions + 20  -- 20 studs à frente das caixas
	local baseY   = sumY / #positions

	for i = 1, 3 do
		local rackZ   = centerZ + (i - 2) * 8
		local rackPos = Vector3.new(baseX, baseY, rackZ)
		local rack = spawnAsset(ID_RACK, CFrame.new(rackPos))
		if rack then
			print("[StoreDecorator] Cabideiro em", tostring(rackPos))

			-- 2 cabides por rack (±2 studs em X, +4 em Y)
			for _, dx in ipairs({ -2, 2 }) do
				local hPos = Vector3.new(rackPos.X + dx, rackPos.Y + 4, rackPos.Z)
				local h = spawnAsset(ID_HANGER, CFrame.new(hPos), false)
				if h then
					for _, p in h:GetDescendants() do
						if p:IsA("BasePart") then p.CanCollide = false end
					end
				end
			end
		end
		task.wait(0.15)
	end

	print("[StoreDecorator] Decoração concluída.")
end)

-- ─────────────────────────────────────────────────────────────
-- Body Andi (bundle 993) — aplica só as partes do corpo
-- ─────────────────────────────────────────────────────────────

local function aplicarBodyAndi(player: Player, character: Model)
	task.wait(1)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local ok, bundleDesc = pcall(function()
		return Players:GetHumanoidDescriptionFromBundleId(993)
	end)
	if not ok then
		warn("[StoreDecorator] Falha ao obter desc do bundle Andi:", bundleDesc)
		return
	end

	local ok2, currentDesc = pcall(function()
		return humanoid:GetAppliedDescription()
	end)
	if not ok2 then return end

	-- Copia só as proporções e partes do corpo; preserva rosto, cabelo e roupas
	currentDesc.HeadScale   = bundleDesc.HeadScale
	currentDesc.BodyType    = bundleDesc.BodyType
	currentDesc.Proportions = bundleDesc.Proportions
	currentDesc.Torso       = bundleDesc.Torso
	currentDesc.LeftArm     = bundleDesc.LeftArm
	currentDesc.RightArm    = bundleDesc.RightArm
	currentDesc.LeftLeg     = bundleDesc.LeftLeg
	currentDesc.RightLeg    = bundleDesc.RightLeg

	local ok3, err3 = pcall(function()
		humanoid:ApplyDescription(currentDesc)
	end)
	if not ok3 then
		warn("[StoreDecorator] Falha ao aplicar body Andi (R6?):", err3)
	else
		print("[StoreDecorator] Body Andi aplicado a", player.Name)
	end
end

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character)
		task.spawn(aplicarBodyAndi, player, character)
	end)
	if player.Character then
		task.spawn(aplicarBodyAndi, player, player.Character)
	end
end)

for _, player in Players:GetPlayers() do
	if player.Character then
		task.spawn(aplicarBodyAndi, player, player.Character)
	end
end

print("[StoreDecorator] Pronto.")
