-- ═══════════════════════════════════════════════════════════════
-- TiersConfig — ReplicatedStorage.Shared
-- Marcos de progresso do Index. required = quantidade total acumulada
-- de roupas descobertas para destravar este tier; reward = recompensa
-- em cliques (moeda do jogo) ao resgatar.
-- ═══════════════════════════════════════════════════════════════

return {
	{ tier = 1, label = "Tier 1", required =  8, reward =   50, rewardType = "clicks" },
	{ tier = 2, label = "Tier 2", required = 16, reward =  200, rewardType = "clicks" },
	{ tier = 3, label = "Tier 3", required = 24, reward = 1000, rewardType = "clicks" },
}
