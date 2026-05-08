-- Cria todos os RemoteEvents antes que qualquer outro script precise deles.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[Setup] Criando RemoteEvents...")

local function criarEvento(nome: string): RemoteEvent
	local evento = Instance.new("RemoteEvent")
	evento.Name   = nome
	evento.Parent = ReplicatedStorage
	print("[Setup] RemoteEvent criado:", nome)
	return evento
end

criarEvento("ClickEvent")          -- cliente → servidor: jogador clicou
criarEvento("BuyUpgradeEvent")     -- cliente → servidor: comprar upgrade N
criarEvento("UpdateStatsEvent")    -- servidor → cliente: dados atualizados
criarEvento("ClothingEvent")       -- cliente → servidor: comprar/equipar roupa
criarEvento("UpdateOutfitEvent")   -- servidor → cliente: outfit atual atualizado

print("[Setup] Todos os RemoteEvents prontos.")
