-- Configurações compartilhadas entre servidor e cliente.
-- Qualquer alteração aqui afeta automaticamente os dois lados.

local GameConfig = {}

GameConfig.StartingCoins      = 0
GameConfig.StartingClickPower = 1

-- Cada entrada: { name, cost, bonus }
GameConfig.Upgrades = {
	{ name = "Agulha & Linha",     cost = 50,    bonus = 1   },
	{ name = "Máquina de Costura", cost = 500,   bonus = 5   },
	{ name = "Atelier Próprio",    cost = 5000,  bonus = 25  },
	{ name = "Maison de Luxo",     cost = 50000, bonus = 100 },
}

-- Limite de cliques por segundo aceitos pelo servidor (anti-exploit)
GameConfig.MaxClicksPerSecond = 20

-- Intervalo de auto-save em segundos
GameConfig.AutoSaveInterval = 60

return GameConfig
