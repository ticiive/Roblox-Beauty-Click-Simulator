-- ═══════════════════════════════════════════════════════════════
-- LimparLojaPobre.server.luau — ServerScriptService
-- Remove o modelo "Loja_Pobre" do Workspace se ele ficou salvo no
-- arquivo .rbxlx de runs anteriores do Environment_Pobre.server.luau
-- (que foi deletado). Não toca em Lootboxes nem em loja_roblox.
-- ═══════════════════════════════════════════════════════════════

local Workspace = game:GetService("Workspace")

local antigo = Workspace:FindFirstChild("Loja_Pobre")
if antigo then
	antigo:Destroy()
	print("[LimparLojaPobre] Modelo Loja_Pobre removido do Workspace.")
end
