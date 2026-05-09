local DailyRewardConfig = {}

DailyRewardConfig.Rewards = {
	{ day = 1, coins = 100 },
	{ day = 2, coins = 250 },
	{ day = 3, coins = 500 },
	{ day = 4, coins = 1000, itemCategories = { "Hair", "FaceAcc" } },
	{ day = 5, coins = 2000 },
	{ day = 6, coins = 5000 },
	{ day = 7, coins = 10000, specialBox = true,
	  boxCategories = { "Hair", "Hats", "FaceAcc", "NeckAcc", "ShoulderAcc" } },
}

-- Janela generosa: streak não quebra até 48h sem entrar
DailyRewardConfig.StreakWindow  = 48 * 3600
-- Período mínimo entre coletas: 24h
DailyRewardConfig.ClaimCooldown = 24 * 3600
-- Streak máximo (cicla)
DailyRewardConfig.MaxStreak     = 7

return DailyRewardConfig
