-- Configurações compartilhadas entre servidor e cliente.

local GameConfig = {}

GameConfig.StartingCoins      = 0
GameConfig.StartingClickPower = 1
GameConfig.MaxClicksPerSecond = 20
GameConfig.AutoSaveInterval   = 60

GameConfig.Upgrades = {
	{ name = "Agulha & Linha",     cost = 50,    bonus = 1   },
	{ name = "Máquina de Costura", cost = 500,   bonus = 5   },
	{ name = "Atelier Próprio",    cost = 5000,  bonus = 25  },
	{ name = "Maison de Luxo",     cost = 50000, bonus = 100 },
}

-- ─────────────────────────────────────────────────────────────
-- Catálogo de roupas (3 categorias × 8 opções)
-- key: identificador interno da categoria
-- items: { name, cost, color }
--   skin  → cor da cabeça (rosto exposto)
--   shirt → cor do torso + braços
--   pants → cor das pernas
-- ─────────────────────────────────────────────────────────────

GameConfig.ClothingCategories = {
	{
		key   = "skin",
		name  = "👤 Pele",
		items = {
			{ name = "Natural",   cost = 0,    color = Color3.fromRGB(255, 218, 180) },
			{ name = "Morena",    cost = 80,   color = Color3.fromRGB(195, 145, 95)  },
			{ name = "Escura",    cost = 80,   color = Color3.fromRGB(110, 70, 35)   },
			{ name = "Rosa",      cost = 150,  color = Color3.fromRGB(255, 185, 195) },
			{ name = "Azul",      cost = 400,  color = Color3.fromRGB(95, 145, 220)  },
			{ name = "Verde",     cost = 400,  color = Color3.fromRGB(75, 170, 80)   },
			{ name = "Dourada",   cost = 900,  color = Color3.fromRGB(215, 178, 55)  },
			{ name = "Negra",     cost = 700,  color = Color3.fromRGB(28, 22, 18)    },
		},
	},
	{
		key   = "shirt",
		name  = "👕 Camisa",
		items = {
			{ name = "Branca",    cost = 50,   color = Color3.fromRGB(242, 242, 242) },
			{ name = "Preta",     cost = 50,   color = Color3.fromRGB(28, 28, 28)    },
			{ name = "Vermelha",  cost = 120,  color = Color3.fromRGB(205, 45, 45)   },
			{ name = "Azul",      cost = 120,  color = Color3.fromRGB(55, 110, 205)  },
			{ name = "Rosa",      cost = 180,  color = Color3.fromRGB(255, 145, 170) },
			{ name = "Verde",     cost = 180,  color = Color3.fromRGB(45, 160, 75)   },
			{ name = "Amarela",   cost = 250,  color = Color3.fromRGB(242, 212, 48)  },
			{ name = "Roxa",      cost = 450,  color = Color3.fromRGB(125, 55, 182)  },
		},
	},
	{
		key   = "pants",
		name  = "👖 Calça",
		items = {
			{ name = "Jeans",     cost = 50,   color = Color3.fromRGB(58, 88, 140)   },
			{ name = "Preta",     cost = 50,   color = Color3.fromRGB(28, 28, 28)    },
			{ name = "Branca",    cost = 80,   color = Color3.fromRGB(238, 232, 222) },
			{ name = "Marrom",    cost = 80,   color = Color3.fromRGB(118, 78, 42)   },
			{ name = "Rosa",      cost = 180,  color = Color3.fromRGB(235, 150, 172) },
			{ name = "Verde",     cost = 180,  color = Color3.fromRGB(45, 138, 65)   },
			{ name = "Roxa",      cost = 280,  color = Color3.fromRGB(108, 50, 152)  },
			{ name = "Dourada",   cost = 750,  color = Color3.fromRGB(198, 158, 42)  },
		},
	},
}

return GameConfig
