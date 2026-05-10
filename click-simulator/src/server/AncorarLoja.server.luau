-- Script temporário: ancora todas as Parts do modelo loja_roblox
-- DELETE este script após rodar uma vez

local loja = workspace:WaitForChild("loja_roblox", 10)
if not loja then
	warn("[AncorarLoja] Modelo loja_roblox não encontrado!")
	return
end

local count = 0
for _, obj in ipairs(loja:GetDescendants()) do
	if obj:IsA("BasePart") then
		obj.Anchored = true
		count = count + 1
	end
end

print("[AncorarLoja] ✅ " .. count .. " partes ancoradas!")
