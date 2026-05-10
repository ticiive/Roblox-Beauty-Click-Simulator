local toolbar = plugin:CreateToolbar("Ferramentas")
local button = toolbar:CreateButton(
	"Ancorar Loja",
	"Ancora todas as Parts do modelo loja_roblox",
	""
)

button.Click:Connect(function()
	local loja = workspace:FindFirstChild("loja_roblox")
	if not loja then
		warn("loja_roblox não encontrada!")
		return
	end

	local count = 0
	for _, obj in ipairs(loja:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = true
			count = count + 1
		end
	end

	print("✅ " .. count .. " parts ancoradas!")
end)
