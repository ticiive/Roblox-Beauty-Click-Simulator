-- ═══════════════════════════════════════════════════════════════
-- LojaPositioner.server.luau — ServerScriptService
-- 1) Desce o modelo "loja_roblox" para que sua base toque o chão (Y=0).
-- 2) Ancora todas as BaseParts do modelo (remove a gravidade — partes
--    ficam fixas, sem cair nem se mover por física).
-- ═══════════════════════════════════════════════════════════════

local Workspace = game:GetService("Workspace")

-- Nível desejado para a BASE da loja
local NIVEL_CHAO = 0

-- Tempo máximo aguardando o modelo aparecer no Workspace
local TIMEOUT = 30

-- ─────────────────────────────────────────────────────────────
-- Localiza o modelo (case-insensitive em alguns aliases comuns)
-- ─────────────────────────────────────────────────────────────
local function encontrarLoja()
	local nomes = { "loja_roblox", "Loja_Roblox", "LojaRoblox", "loja_Roblox" }
	for _, nome in ipairs(nomes) do
		local m = Workspace:FindFirstChild(nome)
		if m then return m end
	end
	-- fallback: varre filhos procurando por padrão
	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("Model") and string.lower(child.Name):find("loja") and string.lower(child.Name):find("roblox") then
			return child
		end
	end
	return nil
end

-- ─────────────────────────────────────────────────────────────
-- Posiciona a base do modelo em Y = NIVEL_CHAO
-- ─────────────────────────────────────────────────────────────
local function ajustarAltura(modelo)
	-- Garante PrimaryPart para PivotTo/GetBoundingBox funcionarem
	if not modelo.PrimaryPart then
		modelo.PrimaryPart = modelo:FindFirstChildWhichIsA("BasePart", true)
	end
	if not modelo.PrimaryPart then
		warn("[LojaPositioner] Modelo sem BasePart — não é possível reposicionar:", modelo.Name)
		return
	end

	local pivot       = modelo:GetPivot()
	local _, tamanho  = modelo:GetBoundingBox()
	-- Centro do bounding box em Y = pivot.Y (PivotTo padrão centraliza)
	-- Base do modelo = pivot.Y - tamanho.Y / 2
	local baseAtual   = pivot.Position.Y - tamanho.Y / 2
	local deltaY      = NIVEL_CHAO - baseAtual

	-- Se já está no nível do chão (tolerância 0.05), não mexe
	if math.abs(deltaY) < 0.05 then
		print(string.format("[LojaPositioner] %s já está no nível do chão (base Y=%.2f)", modelo.Name, baseAtual))
		return
	end

	-- Translada apenas no eixo Y, preservando rotação
	modelo:PivotTo(pivot + Vector3.new(0, deltaY, 0))

	print(string.format(
		"[LojaPositioner] %s descido — base movida de Y=%.2f para Y=%.2f (delta=%.2f)",
		modelo.Name, baseAtual, NIVEL_CHAO, deltaY))
end

-- ─────────────────────────────────────────────────────────────
-- Ancora todas as BaseParts do modelo (remove gravidade)
-- ─────────────────────────────────────────────────────────────
local function ancorarTudo(modelo)
	local count = 0
	for _, p in ipairs(modelo:GetDescendants()) do
		if p:IsA("BasePart") then
			if not p.Anchored then
				p.Anchored = true
				count += 1
			end
		end
	end
	print(string.format("[LojaPositioner] %d partes ancoradas em %s (gravidade desativada).", count, modelo.Name))
end

-- ─────────────────────────────────────────────────────────────
-- Inicialização: aguarda o modelo aparecer e ajusta
-- ─────────────────────────────────────────────────────────────
task.spawn(function()
	local modelo = encontrarLoja()
	local tempo  = 0
	while not modelo and tempo < TIMEOUT do
		task.wait(0.5)
		tempo += 0.5
		modelo = encontrarLoja()
	end

	if not modelo then
		warn(string.format("[LojaPositioner] Modelo 'loja_roblox' não encontrado após %ds", TIMEOUT))
		return
	end

	-- Ancora primeiro (evita qualquer micro-queda entre operações),
	-- depois ajusta a altura.
	ancorarTudo(modelo)
	ajustarAltura(modelo)
end)
