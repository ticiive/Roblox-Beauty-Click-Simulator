local LootboxConfig = {}

LootboxConfig.MeshAssetId = 77622925699973

LootboxConfig.SpawnOrigin = Vector3.new(0, 5, 0)
LootboxConfig.PadSize     = Vector3.new(8, 0.5, 8)
LootboxConfig.PadOffset   = Vector3.new(0, -3, 8)

LootboxConfig.Boxes = {
	{
		id          = "basic",
		name        = "Caixa Básica",
		emoji       = "📦",
		cost        = 100,
		color       = Color3.fromRGB(160, 160, 160),
		glowColor   = Color3.fromRGB(160, 160, 160),
		scale       = 1.0,
		spawnOffset = Vector3.new(-30, 0, 0),
		categories  = { "Hair", "Hats", "TShirts" },
	},
	{
		id          = "stylish",
		name        = "Caixa Fashion",
		emoji       = "🎀",
		cost        = 500,
		color       = Color3.fromRGB(80, 140, 220),
		glowColor   = Color3.fromRGB(80, 140, 220),
		scale       = 1.2,
		spawnOffset = Vector3.new(-10, 0, 0),
		categories  = { "Hair", "Hats", "FaceAcc", "Shirts", "Pants" },
	},
	{
		id          = "premium",
		name        = "Caixa Premium",
		emoji       = "✨",
		cost        = 2500,
		color       = Color3.fromRGB(215, 178, 55),
		glowColor   = Color3.fromRGB(215, 178, 55),
		scale       = 1.5,
		spawnOffset = Vector3.new(10, 0, 0),
		categories  = { "Hair", "Hats", "FaceAcc", "NeckAcc", "ShoulderAcc", "Shirts", "Pants" },
	},
	{
		id          = "ultimate",
		name        = "Caixa Ultimate",
		emoji       = "👑",
		cost        = 10000,
		color       = Color3.fromRGB(200, 60, 200),
		glowColor   = Color3.fromRGB(200, 60, 200),
		scale       = 2.0,
		spawnOffset = Vector3.new(30, 0, 0),
		categories  = { "Hair", "Hats", "FaceAcc", "NeckAcc", "ShoulderAcc", "WaistAcc", "Shirts", "Pants", "TShirts" },
	},
	{
		id              = "rebirth",
		name            = "Caixa Rebirth",
		emoji           = "✨",
		cost            = 500,
		color           = Color3.fromRGB(100, 220, 255),
		glowColor       = Color3.fromRGB(100, 220, 255),
		scale           = 1.3,
		spawnOffset     = Vector3.new(50, 0, 0),
		categories      = { "Hair", "Hats", "FaceAcc", "NeckAcc", "ShoulderAcc", "WaistAcc", "Shirts", "Pants", "TShirts" },
		requiresRebirth = 1,
	},
}

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
