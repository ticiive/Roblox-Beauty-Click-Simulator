local function ancorarTudo()
	local loja = workspace:WaitForChild("loja_roblox", 15)
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

	-- Também ancorar quando novos objetos forem adicionados
	loja.DescendantAdded:Connect(function(obj)
		if obj:IsA("BasePart") then
			obj.Anchored = true
		end
	end)

	print("[AncorarLoja] ✅ " .. count .. " partes ancoradas!")
end

ancorarTudo()
