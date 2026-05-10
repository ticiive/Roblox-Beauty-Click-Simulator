-- Ancora TUDO no workspace, não só loja_roblox
task.wait(3) -- espera tudo carregar

local count = 0
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("BasePart") then
		obj.Anchored = true
		count += 1
	end
end

-- Listener pra qualquer nova Part que aparecer
workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("BasePart") then
		obj.Anchored = true
	end
end)

print("[AncorarLoja] ✅ " .. count .. " partes ancoradas!")
