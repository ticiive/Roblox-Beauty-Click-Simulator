-- ============================================================
-- BatomProximityPrompt.client.luau
-- LocalScript em StarterPlayerScripts
-- Variante com ProximityPrompt (botão 3D no mundo)
-- Use este script OU o BatomClicker.client.luau, não os dois juntos.
-- ============================================================

-- ========================
-- CONFIGURAÇÕES
-- ========================

-- ID da animação de passar batom
local ANIMATION_ID = "rbxassetid://0000000000"

-- Caminho da Part no Workspace que contém o ProximityPrompt
-- Exemplo: Workspace.Espelho.ProximityPrompt
-- Ajuste o caminho conforme sua cena
local CAMINHO_PROMPT = game:GetService("Workspace"):WaitForChild("Espelho"):WaitForChild("ProximityPrompt")

-- ========================
-- SERVIÇOS
-- ========================

local Players = game:GetService("Players")
local jogador = Players.LocalPlayer

-- ========================
-- REFERÊNCIA AO PROMPT
-- ========================

-- O ProximityPrompt deve estar colocado dentro de uma Part no Workspace.
-- Ele exibe automaticamente a tecla de interação (padrão: E) para o jogador.
local prompt = CAMINHO_PROMPT

-- Configura o texto exibido no prompt
prompt.ObjectText    = "Batom"
prompt.ActionText    = "Passar Batom 💄"
prompt.HoldDuration  = 0        -- 0 = clique simples; >0 = segurar
prompt.MaxActivationDistance = 10

-- ========================
-- ANIMAÇÃO
-- ========================

local animacaoAsset = Instance.new("Animation")
animacaoAsset.AnimationId = ANIMATION_ID

local trackBatom = nil

local function carregarAnimacao(personagem)
    local humanoid = personagem:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")

    trackBatom = animator:LoadAnimation(animacaoAsset)
    trackBatom.Priority = Enum.AnimationPriority.Action
end

-- ========================
-- LÓGICA DO PROMPT
-- ========================

-- O evento Triggered dispara no cliente quando o jogador ativa o ProximityPrompt.
-- FilteringEnabled garante que cheats não funcionem: valide no servidor se necessário.
prompt.Triggered:Connect(function(jogadorQueAtivou)
    -- Filtra: apenas o jogador local deve reagir (evita execução dupla)
    if jogadorQueAtivou ~= jogador then return end

    local track = trackBatom
    if not track then return end

    -- Debounce: bloqueia reativação enquanto a animação toca
    if track.IsPlaying then return end

    -- Desabilita o prompt para impedir nova interação durante a animação
    prompt.Enabled = false

    -- Toca a animação de passar batom
    track:Play()

    -- Aguarda o fim da animação antes de reabilitar o prompt
    track.Stopped:Wait()

    -- Reabilita o prompt após a animação terminar
    prompt.Enabled = true
end)

-- ========================
-- INICIALIZAÇÃO E RESPAWN
-- ========================

if jogador.Character then
    carregarAnimacao(jogador.Character)
end

jogador.CharacterAdded:Connect(function(novoPersonagem)
    -- Garante que o prompt seja reabilitado caso o jogador morra animando
    prompt.Enabled = true
    carregarAnimacao(novoPersonagem)
end)
