local LootboxConfig = {}

LootboxConfig.Boxes = {
	{
		id       = "basic",
		name     = "Caixa Básica",
		emoji    = "📦",
		cost     = 100,
		color    = Color3.fromRGB(160, 160, 160),
		categories = { "Hair", "Hats", "TShirts" },
	},
	{
		id       = "stylish",
		name     = "Caixa Fashion",
		emoji    = "🎀",
		cost     = 500,
		color    = Color3.fromRGB(80, 140, 220),
		categories = { "Hair", "Hats", "FaceAcc", "Shirts", "Pants" },
	},
	{
		id       = "premium",
		name     = "Caixa Premium",
		emoji    = "✨",
		cost     = 2500,
		color    = Color3.fromRGB(215, 178, 55),
		categories = { "Hair", "Hats", "FaceAcc", "NeckAcc", "ShoulderAcc", "Shirts", "Pants" },
	},
	{
		id       = "ultimate",
		name     = "Caixa Ultimate",
		emoji    = "👑",
		cost     = 10000,
		color    = Color3.fromRGB(200, 60, 200),
		categories = { "Hair", "Hats", "FaceAcc", "NeckAcc", "ShoulderAcc", "WaistAcc", "Shirts", "Pants", "TShirts" },
	},
}

-- Tipo de asset do Roblox por categoria do catálogo
LootboxConfig.AssetTypeByCategory = {
	Hair        = "HairAccessory",
	Hats        = "HatAccessory",
	FaceAcc     = "FaceAccessory",
	NeckAcc     = "NeckAccessory",
	ShoulderAcc = "ShoulderAccessory",
	WaistAcc    = "WaistAccessory",
	Shirts      = "Shirt",
	Pants       = "Pants",
	TShirts     = "TShirt",
}

function LootboxConfig.getBoxById(id: string)
	for _, box in LootboxConfig.Boxes do
		if box.id == id then return box end
	end
	return nil
end

return LootboxConfig
