-- Cria chão simples e funcional
local chao = Instance.new("Part")
chao.Name = "Chao"
chao.Size = Vector3.new(200, 1, 200)
chao.Position = Vector3.new(0, 0, 0)
chao.Anchored = true
chao.Material = Enum.Material.SmoothPlastic
chao.Color = Color3.fromRGB(200, 180, 160)
chao.Parent = workspace

-- Ancora tudo da loja importada se existir
local loja = workspace:FindFirstChild("loja_roblox")
if loja then
	for _, obj in ipairs(loja:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = true
		end
	end
	print("[LojaBuilder] loja_roblox ancorada!")
else
	print("[LojaBuilder] Sem loja importada, só chão criado")
end
