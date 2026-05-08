-- ============================================================
-- BatomClicker.client.luau
-- LocalScript em StarterPlayerScripts
-- Sistema de clique com animação de passar batom
-- ============================================================

-- ========================
-- CONFIGURAÇÕES (edite aqui)
-- ========================

-- ID da animação de passar batom — substitua pelo AnimationId do seu asset
-- Exemplo: "rbxassetid://507770239" (animação de acenar da Roblox)
local ANIMATION_ID = "rbxassetid://0000000000"

-- Cores do botão nos dois estados
local COR_ATIVO     = Color3.fromRGB(220, 80, 120)  -- rosa batom
local COR_INATIVO   = Color3.fromRGB(100, 50, 65)   -- cinza-rosado (desativado)

-- ========================
-- SERVIÇOS
-- ========================

local Players = game:GetService("Players")

-- Referência ao jogador que está rodando este script (lado do cliente)
local jogador = Players.LocalPlayer

-- ========================
-- CRIAÇÃO DA INTERFACE
-- ========================
-- A ScreenGui é criada em código para não depender de instâncias no Studio.
-- Se preferir usar uma GUI já montada, substitua estas linhas por:
--   local screenGui = jogador:WaitForChild("PlayerGui"):WaitForChild("NomeDaSuaGui")
--   local botao = screenGui:WaitForChild("NomeDoBotao")

local screenGui = Instance.new("ScreenGui")
screenGui.Name          = "BatomClickerGui"
screenGui.ResetOnSpawn  = false   -- mantém a GUI ao respawnar
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent        = jogador:WaitForChild("PlayerGui")

-- Painel de fundo centralizado na parte inferior da tela
local painel = Instance.new("Frame")
painel.Name                 = "Painel"
painel.Size                 = UDim2.new(0, 200, 0, 200)
painel.Position             = UDim2.new(0.5, -100, 0.75, -100)
painel.BackgroundColor3     = Color3.fromRGB(25, 15, 20)
painel.BorderSizePixel      = 0
painel.Parent               = screenGui

Instance.new("UICorner", painel).CornerRadius = UDim.new(0, 18)

-- Sombra decorativa atrás do painel
local sombra = Instance.new("ImageLabel")
sombra.Name                 = "Sombra"
sombra.Size                 = UDim2.new(1, 20, 1, 20)
sombra.Position             = UDim2.new(0, -10, 0, 8)
sombra.BackgroundTransparency = 1
sombra.Image                = "rbxassetid://5554236805"
sombra.ImageColor3          = Color3.fromRGB(0, 0, 0)
sombra.ImageTransparency    = 0.5
sombra.ScaleType            = Enum.ScaleType.Slice
sombra.SliceCenter          = Rect.new(23, 23, 277, 277)
sombra.ZIndex               = 0
sombra.Parent               = painel

-- Botão principal de clique
local botao = Instance.new("TextButton")
botao.Name                  = "BotaoBatom"
botao.Size                  = UDim2.new(1, -24, 0, 70)
botao.Position              = UDim2.new(0, 12, 0, 18)
botao.BackgroundColor3      = COR_ATIVO
botao.TextColor3            = Color3.fromRGB(255, 255, 255)
botao.Text                  = "💄  Passar Batom"
botao.TextSize              = 18
botao.Font                  = Enum.Font.GothamBold
botao.BorderSizePixel       = 0
botao.AutoButtonColor       = true
botao.Parent                = painel

Instance.new("UICorner", botao).CornerRadius = UDim.new(0, 12)

-- Rótulo de status: informa se está pronto ou animando
local labelStatus = Instance.new("TextLabel")
labelStatus.Name                = "Status"
labelStatus.Size                = UDim2.new(1, -16, 0, 30)
labelStatus.Position            = UDim2.new(0, 8, 0, 100)
labelStatus.BackgroundTransparency = 1
labelStatus.TextColor3          = Color3.fromRGB(210, 170, 180)
labelStatus.Text                = "✔  Pronto para clicar!"
labelStatus.TextSize            = 14
labelStatus.Font                = Enum.Font.Gotham
labelStatus.TextXAlignment      = Enum.TextXAlignment.Center
labelStatus.Parent              = painel

-- Rótulo de contador de cliques
local labelContador = Instance.new("TextLabel")
labelContador.Name              = "Contador"
labelContador.Size              = UDim2.new(1, -16, 0, 30)
labelContador.Position          = UDim2.new(0, 8, 0, 140)
labelContador.BackgroundTransparency = 1
labelContador.TextColor3        = Color3.fromRGB(255, 200, 215)
labelContador.Text              = "Batom aplicado: 0x"
labelContador.TextSize          = 14
labelContador.Font              = Enum.Font.GothamBold
labelContador.TextXAlignment    = Enum.TextXAlignment.Center
labelContador.Parent            = painel

-- ========================
-- ESTADO DO JOGO
-- ========================

local totalCliques   = 0   -- contador persistente de cliques bem-sucedidos
local trackBatom     = nil -- AnimationTrack atual; substituído a cada respawn

-- ========================
-- ANIMAÇÃO: carregamento
-- ========================

-- Cria a instância de Animation com o ID configurado no topo.
-- Esta instância pode ser reutilizada em múltiplos LoadAnimation().
local animacaoAsset = Instance.new("Animation")
animacaoAsset.AnimationId = ANIMATION_ID

-- Configura (ou reconfigura) o AnimationTrack para o personagem atual.
-- Chamada tanto na primeira carga quanto após cada respawn.
local function carregarAnimacao(personagem)
    -- Aguarda o Humanoid existir no modelo do personagem
    local humanoid = personagem:WaitForChild("Humanoid")

    -- O Animator é o responsável por reproduzir AnimationTracks no R15/R6
    -- Humanoid:LoadAnimation() está obsoleto; use Animator:LoadAnimation()
    local animator = humanoid:WaitForChild("Animator")

    -- Carrega a animação e retorna um AnimationTrack pronto para Play()
    trackBatom = animator:LoadAnimation(animacaoAsset)

    -- Action sobrepõe animações de idle, walk e run automaticamente
    trackBatom.Priority = Enum.AnimationPriority.Action
end

-- ========================
-- LÓGICA DE CLIQUE
-- ========================

local function aoClicar()
    -- Guarda uma referência local ao track para evitar race condition no respawn
    local track = trackBatom

    -- Segurança: ignora se o personagem ainda não carregou a animação
    if not track then return end

    -- DEBOUNCE principal: rejeita novos cliques enquanto a animação está tocando.
    -- IsPlaying é true desde Play() até o frame final da animação.
    if track.IsPlaying then return end

    -- ── DESATIVA o botão visualmente ──────────────────────────
    botao.Active           = false    -- bloqueia cliques de mouse
    botao.AutoButtonColor  = false    -- desliga o hover automático do Roblox
    botao.BackgroundColor3 = COR_INATIVO
    labelStatus.Text       = "⏳  Aplicando batom..."

    -- ── TOCA A ANIMAÇÃO ───────────────────────────────────────
    track:Play()

    -- Aguarda o evento Stopped do AnimationTrack.
    -- Este :Wait() suspende apenas esta coroutine; o resto do jogo continua.
    -- O evento dispara quando:
    --   (a) a animação chegou ao fim naturalmente, OU
    --   (b) track:Stop() foi chamado manualmente
    track.Stopped:Wait()

    -- ── REATIVA o botão após a animação terminar ──────────────
    botao.Active           = true
    botao.AutoButtonColor  = true
    botao.BackgroundColor3 = COR_ATIVO

    -- Incrementa e exibe o contador de cliques concluídos
    totalCliques += 1
    labelStatus.Text  = "✔  Pronto para clicar!"
    labelContador.Text = string.format("Batom aplicado: %dx", totalCliques)
end

-- ========================
-- INICIALIZAÇÃO
-- ========================

-- Se o personagem já existe quando o script carrega (modo solo/Studio),
-- carrega a animação imediatamente.
if jogador.Character then
    carregarAnimacao(jogador.Character)
end

-- Conecta ao evento CharacterAdded para recarregar a animação a cada respawn.
-- O Humanoid e o Animator são destruídos junto com o personagem ao morrer,
-- por isso um novo LoadAnimation() é necessário no novo personagem.
jogador.CharacterAdded:Connect(function(novoPersonagem)
    -- Reseta o visual do botão caso o jogador tenha morrido durante a animação
    botao.Active           = true
    botao.AutoButtonColor  = true
    botao.BackgroundColor3 = COR_ATIVO
    labelStatus.Text       = "✔  Pronto para clicar!"

    -- Reconfigura o track para o Animator do novo personagem
    carregarAnimacao(novoPersonagem)
end)

-- Conecta o clique do botão à função principal de interação
botao.MouseButton1Click:Connect(aoClicar)
