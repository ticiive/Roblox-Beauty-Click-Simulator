-- Ancora só o modelo loja_roblox, nunca o personagem do jogador
task.wait(2)

local loja = workspace:WaitForChild("loja_roblox", 10)
if not loja then
	warn("[AncorarLoja] loja_roblox não encontrada!")
	return
end

local count = 0
for _, obj in ipairs(loja:GetDescendants()) do
	if obj:IsA("BasePart") then
		obj.Anchored = true
		count += 1
	end
end

loja.DescendantAdded:Connect(function(obj)
	if obj:IsA("BasePart") then
		obj.Anchored = true
	end
end)

print("[AncorarLoja] ✅ " .. count .. " partes ancoradas!")
