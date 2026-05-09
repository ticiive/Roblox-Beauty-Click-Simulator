-- ═══════════════════════════════════════════════════════════════
-- LimparRebirthNPC.server.luau — ServerScriptService
-- Remove o totem RebirthNPC do Workspace se ele ficou salvo no
-- arquivo .rbxlx de runs anteriores do RebirthNPC.server.luau
-- (que foi deletado). Mantém o resto da decoração intacto.
-- ═══════════════════════════════════════════════════════════════

local Workspace = game:GetService("Workspace")

-- Procura no Workspace e dentro de StoreDecoration (onde o spawner colocava)
local function destruirSeAchar(parent)
	if not parent then return end
	local m = parent:FindFirstChild("RebirthNPC")
	if m then
		m:Destroy()
		print("[LimparRebirthNPC] Totem RebirthNPC removido de", parent:GetFullName())
	end
end

destruirSeAchar(Workspace)
destruirSeAchar(Workspace:FindFirstChild("StoreDecoration"))
