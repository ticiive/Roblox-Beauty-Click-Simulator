-- Loja Nível 1 — "Pobre"
-- Estilo low-poly Roblox. Madeira crua, desgastada, iluminação fraca.
-- Inspirado no layout Dress to Impress: escada à esquerda, nichos ao fundo,
-- prateleiras à direita, balcão-caixote à esquerda no centro.

local Workspace = game:GetService("Workspace")
local Lighting  = game:GetService("Lighting")

-- ─────────────────────────────────────────────────────────────
-- Dimensões do cômodo
-- ─────────────────────────────────────────────────────────────

local W  = 45   -- metade da largura  (70 total)
local D  = 36   -- metade da profundidade (52 total)
local H  = 22   -- altura
local DW = 6    -- metade da largura da porta (porta = 12)
local DH = 13   -- altura da porta

-- ─────────────────────────────────────────────────────────────
-- Setup
-- ─────────────────────────────────────────────────────────────

local bp = Workspace:FindFirstChild("Baseplate")
if bp then bp:Destroy() end

local LOJA = Instance.new("Model")
LOJA.Name   = "Loja_Pobre"
LOJA.Parent = Workspace

local function pt(props: { [string]: any }): Part
	local piece      = Instance.new("Part")
	piece.Anchored   = true
	piece.CanCollide = true
	piece.CastShadow = true
	for k, v in props do (piece :: any)[k] = v end
	piece.Parent = LOJA
	return piece
end

-- ─────────────────────────────────────────────────────────────
-- Paleta "pobre"
-- ─────────────────────────────────────────────────────────────

local C_CHAO    = Color3.fromRGB(62, 42, 20)        -- piso desgastado
local C_PAREDE  = Color3.fromRGB(112, 80, 46)        -- compensado barato
local C_TETO    = Color3.fromRGB(88, 62, 32)         -- teto escuro
local C_MADEIRA = Color3.fromRGB(95, 66, 32)         -- móveis rústicos
local C_SUJEIRA = Color3.fromRGB(28, 20, 10)         -- manchas no chão
local C_TEIA    = Color3.fromRGB(185, 175, 155)      -- teia de aranha
local C_LUZ     = Color3.fromRGB(255, 198, 82)       -- lâmpada incandescente

-- Cores desbotadas dos itens expostos
local DESBOTADOS = {
	Color3.fromRGB(175, 148, 125),   -- rosa sujo
	Color3.fromRGB(135, 140, 152),   -- azul desbotado
	Color3.fromRGB(155, 145, 108),   -- amarelo-marrom
	Color3.fromRGB(145, 115, 95),    -- laranja gasto
	Color3.fromRGB(125, 120, 138),   -- roxo apagado
	Color3.fromRGB(115, 148, 122),   -- verde murcho
	Color3.fromRGB(168, 155, 135),   -- bege sujo
}

-- ─────────────────────────────────────────────────────────────
-- PISO: tábuas largas com variação de cor
-- ─────────────────────────────────────────────────────────────

local taboas = {
	Color3.fromRGB(62, 42, 20), Color3.fromRGB(70, 50, 25),
	Color3.fromRGB(56, 38, 17), Color3.fromRGB(66, 47, 23), Color3.fromRGB(54, 37, 16),
}
local largTab = 3.5
local qtdTab  = math.floor(W * 2 / largTab)
for i = 0, qtdTab - 1 do
	pt({ Size=Vector3.new(largTab - 0.08, 1, D*2),
		Position=Vector3.new(-W + i * largTab + largTab/2.1, 0.3, 0),
		Color=taboas[(i % #taboas) + 1], Material=Enum.Material.WoodPlanks })
end

-- Manchas de sujeira e graxa
for _, m in ipairs({
	{-16,  7, 4, 2}, { 11, -5, 3, 3}, { -4, 17, 5, 2},
	{ 21, -1, 2, 4}, {-24,-13, 3, 2}, {  4,-17, 4, 3}, {-11,  3, 3, 2},
}) do
	pt({ Size=Vector3.new(m[3], 0.09, m[4]), Position=Vector3.new(m[1], 0.05, m[2]),
		Color=C_SUJEIRA, Material=Enum.Material.SmoothPlastic, CanCollide=false })
end

-- ─────────────────────────────────────────────────────────────
-- PAREDES: compensado com remendos visíveis
-- ─────────────────────────────────────────────────────────────

pt({ Name="ParedeFundo",    Size=Vector3.new(W*2, H, 1),  Position=Vector3.new(0,  H/2, -D), Color=C_PAREDE, Material=Enum.Material.WoodPlanks })
pt({ Name="ParedeDireita",  Size=Vector3.new(1,   H, D*2), Position=Vector3.new(W,  H/2, 0),  Color=C_PAREDE, Material=Enum.Material.WoodPlanks })
pt({ Name="ParedeEsquerda", Size=Vector3.new(1,   H, D*2), Position=Vector3.new(-W, H/2, 0),  Color=C_PAREDE, Material=Enum.Material.WoodPlanks })

-- Frente fechada com porta
local lLado = W - DW
pt({ Name="FrenteEsq", Size=Vector3.new(lLado, H, 1),    Position=Vector3.new(-(DW + lLado/2), H/2,        D), Color=C_PAREDE, Material=Enum.Material.WoodPlanks })
pt({ Name="FrenteDir", Size=Vector3.new(lLado, H, 1),    Position=Vector3.new( (DW + lLado/2), H/2,        D), Color=C_PAREDE, Material=Enum.Material.WoodPlanks })
pt({ Name="Verga",     Size=Vector3.new(DW*2, H - DH, 1), Position=Vector3.new(0, DH + (H-DH)/2,           D), Color=C_PAREDE, Material=Enum.Material.WoodPlanks })

-- Remendos de reparo nas paredes (tom mais escuro)
local REM = Color3.fromRGB(82, 55, 25)
for _, r in ipairs({
	{ Vector3.new(10, 5, 0.22), Vector3.new(-17,  8, -D+0.12) },
	{ Vector3.new( 7, 4, 0.22), Vector3.new( 15, 13, -D+0.12) },
	{ Vector3.new( 0.22, 5, 8), Vector3.new(-W+0.12, 5, -4) },
	{ Vector3.new( 0.22, 6, 7), Vector3.new( W-0.12, 10, 9) },
	{ Vector3.new( 8, 3, 0.22), Vector3.new(  7,  5,  D-0.12) },
}) do
	pt({ Size=r[1], Position=r[2], Color=REM, Material=Enum.Material.WoodPlanks, CanCollide=false })
end

-- ─────────────────────────────────────────────────────────────
-- TETO: vigas expostas
-- ─────────────────────────────────────────────────────────────

pt({ Name="Teto", Size=Vector3.new(W*2, 1, D*2), Position=Vector3.new(0, H, 0),
	Color=C_TETO, Material=Enum.Material.WoodPlanks })

-- Vigas cruzando o teto
for bz = -D + 5, D - 5, 9 do
	pt({ Size=Vector3.new(W*2, 1.6, 2), Position=Vector3.new(0, H - 0.8, bz),
		Color=Color3.fromRGB(50, 34, 15), Material=Enum.Material.Wood })
end

-- ─────────────────────────────────────────────────────────────
-- BALCÃO-CAIXOTE (esquerda-centro — substitui a casinha rosa)
-- ─────────────────────────────────────────────────────────────

local BX, BZ = -14, 8   -- centro do balcão

-- Corpo do caixote (empilhado, remendado)
pt({ Size=Vector3.new(12, 4.2, 8),  Position=Vector3.new(BX, 2.1, BZ),
	Color=Color3.fromRGB(90, 62, 30), Material=Enum.Material.Wood })
-- Tábuas verticais visíveis nas faces
for xi = -4, 4, 2 do
	pt({ Size=Vector3.new(0.2, 4.4, 8.2), Position=Vector3.new(BX + xi, 2.1, BZ),
		Color=Color3.fromRGB(68, 46, 20), Material=Enum.Material.Wood, CanCollide=false })
end
-- Tampo desgastado
pt({ Size=Vector3.new(12.5, 0.32, 8.5), Position=Vector3.new(BX, 4.26, BZ),
	Color=Color3.fromRGB(150, 122, 88), Material=Enum.Material.SmoothPlastic })

-- "Teto" da casinha (simplório, de tábua)
pt({ Size=Vector3.new(14, 0.5, 10), Position=Vector3.new(BX, 10.5, BZ),
	Color=Color3.fromRGB(74, 50, 22), Material=Enum.Material.Wood })
-- Colunas da casinha
for _, cx in ipairs({ BX - 6, BX + 6 }) do
	pt({ Size=Vector3.new(0.55, 6.3, 0.55), Position=Vector3.new(cx, 7.15, BZ - 4.2),
		Color=Color3.fromRGB(80, 55, 24), Material=Enum.Material.Wood })
	pt({ Size=Vector3.new(0.55, 6.3, 0.55), Position=Vector3.new(cx, 7.15, BZ + 4.2),
		Color=Color3.fromRGB(80, 55, 24), Material=Enum.Material.Wood })
end

-- Itens no balcão: "bolos industriais" / sorvetes baratos
for i, dados in ipairs({
	{ Color3.fromRGB(205, 175, 138), Vector3.new(BX - 3.5, 4.72, BZ - 1.5) },
	{ Color3.fromRGB(188, 165, 125), Vector3.new(BX,       4.72, BZ + 1  ) },
	{ Color3.fromRGB(172, 152, 112), Vector3.new(BX + 3.5, 4.72, BZ - 1  ) },
}) do
	pt({ Size=Vector3.new(2.2, 1.8, 2.2), Position=dados[2],
		Color=dados[1], Material=Enum.Material.SmoothPlastic, CanCollide=false })
	-- "glace" barato por cima
	pt({ Size=Vector3.new(2.3, 0.4, 2.3), Position=dados[2] + Vector3.new(0, 1.1, 0),
		Color=Color3.fromRGB(218, 195, 158), Material=Enum.Material.SmoothPlastic, CanCollide=false })
end

-- ─────────────────────────────────────────────────────────────
-- NICHOS DE EXIBIÇÃO AO FUNDO (3 compartimentos abertos)
-- ─────────────────────────────────────────────────────────────

local NICHO_L = 14   -- largura de cada nicho
local NICHO_H = 14   -- altura
local NICHO_P = 5    -- profundidade

for _, nx in ipairs({ -18, 0, 18 }) do
	-- Paredes laterais
	pt({ Size=Vector3.new(0.55, NICHO_H, NICHO_P), Position=Vector3.new(nx - NICHO_L/2, NICHO_H/2, -D + NICHO_P/2), Color=C_MADEIRA, Material=Enum.Material.Wood })
	pt({ Size=Vector3.new(0.55, NICHO_H, NICHO_P), Position=Vector3.new(nx + NICHO_L/2, NICHO_H/2, -D + NICHO_P/2), Color=C_MADEIRA, Material=Enum.Material.Wood })
	-- Teto do nicho
	pt({ Size=Vector3.new(NICHO_L + 0.55, 0.55, NICHO_P), Position=Vector3.new(nx, NICHO_H, -D + NICHO_P/2), Color=C_MADEIRA, Material=Enum.Material.Wood })
	-- Piso elevado
	pt({ Size=Vector3.new(NICHO_L - 0.2, 0.45, NICHO_P - 0.2), Position=Vector3.new(nx, 0.23, -D + NICHO_P/2), Color=Color3.fromRGB(75, 50, 22), Material=Enum.Material.WoodPlanks })
	-- Barra de cabides tosca
	pt({ Size=Vector3.new(NICHO_L - 1.5, 0.2, 0.2), Position=Vector3.new(nx, 6, -D + 0.5),
		Color=Color3.fromRGB(128, 108, 88), Material=Enum.Material.Metal, CanCollide=false })

	-- 3 peças de roupa desbotadas + cabide
	for ri = 1, 3 do
		local cor = DESBOTADOS[((ri - 1) % #DESBOTADOS) + 1]
		pt({ Size=Vector3.new(2.8, 0.15, 0.12), Position=Vector3.new(nx - 4.5 + (ri-1)*4.5, 5.9, -D + 0.45),
			Color=Color3.fromRGB(115, 95, 75), Material=Enum.Material.Metal, CanCollide=false })
		pt({ Size=Vector3.new(2.5, 4.2, 0.22), Position=Vector3.new(nx - 4.5 + (ri-1)*4.5, 3.6, -D + 0.35),
			Color=cor, Material=Enum.Material.Fabric, CanCollide=false })
	end

	-- Teias de aranha nos cantos superiores do nicho
	for _, cx in ipairs({ nx - NICHO_L/2 + 0.8, nx + NICHO_L/2 - 0.8 }) do
		pt({ Size=Vector3.new(3.5, 0.07, 0.07), Position=Vector3.new(cx, NICHO_H - 0.35, -D + 0.8),
			Color=C_TEIA, Material=Enum.Material.SmoothPlastic, CanCollide=false })
		pt({ Size=Vector3.new(0.07, 3.5, 0.07), Position=Vector3.new(cx, NICHO_H - 2, -D + 0.8),
			Color=C_TEIA, Material=Enum.Material.SmoothPlastic, CanCollide=false })
		pt({ Size=Vector3.new(2.5, 0.06, 0.06), Position=Vector3.new(cx, NICHO_H - 1, -D + 1.5),
			Color=C_TEIA, Material=Enum.Material.SmoothPlastic, CanCollide=false })
	end
end

-- ─────────────────────────────────────────────────────────────
-- PRATELEIRAS LADO DIREITO (4 andares)
-- ─────────────────────────────────────────────────────────────

local PX = W - 1.5   -- encostado na parede direita

for andar = 0, 3 do
	local pY = 3.5 + andar * 4.8
	-- Tábua da prateleira
	pt({ Size=Vector3.new(0.32, 0.32, 22), Position=Vector3.new(PX, pY, -11),
		Color=C_MADEIRA, Material=Enum.Material.Wood })
	-- Suportes verticais
	for sz = -9, 9, 9 do
		pt({ Size=Vector3.new(0.28, pY, 0.28), Position=Vector3.new(PX, pY/2, -11 + sz),
			Color=Color3.fromRGB(78, 52, 23), Material=Enum.Material.Wood })
	end
	-- Itens desbotados
	for item = 0, 4 do
		local cor = DESBOTADOS[((andar * 5 + item) % #DESBOTADOS) + 1]
		pt({ Size=Vector3.new(1.9, 2.6, 1.3),
			Position=Vector3.new(PX - 0.8, pY + 1.5, -20 + item * 5),
			Color=cor, Material=Enum.Material.SmoothPlastic, CanCollide=false })
	end

	-- Teias nos cantos fundo-direito
	pt({ Size=Vector3.new(4, 0.07, 0.07), Position=Vector3.new(W - 0.6, pY + 0.2, -D + 1.2),
		Color=C_TEIA, Material=Enum.Material.SmoothPlastic, CanCollide=false })
	pt({ Size=Vector3.new(0.07, 4, 0.07), Position=Vector3.new(W - 2, pY - 1.5, -D + 1.2),
		Color=C_TEIA, Material=Enum.Material.SmoothPlastic, CanCollide=false })
end

-- ─────────────────────────────────────────────────────────────
-- LÂMPADAS NUAS (fios expostos + bulbo incandescente)
-- ─────────────────────────────────────────────────────────────

for _, pos in ipairs({
	Vector3.new(-14, H, -6),
	Vector3.new( 12, H, -6),
	Vector3.new(  0, H,  12),
}) do
	local fioH = 6
	-- Fio desgastado
	pt({ Size=Vector3.new(0.09, fioH, 0.09), Position=Vector3.new(pos.X, H - fioH/2, pos.Z),
		Color=Color3.fromRGB(25, 20, 14), Material=Enum.Material.SmoothPlastic, CanCollide=false })
	-- Bocal metálico
	pt({ Size=Vector3.new(0.65, 0.9, 0.65), Position=Vector3.new(pos.X, H - fioH - 0.45, pos.Z),
		Color=Color3.fromRGB(45, 40, 32), Material=Enum.Material.Metal, CanCollide=false })
	-- Bulbo (neon)
	local bulbo = pt({ Size=Vector3.new(0.95, 1.15, 0.95), Position=Vector3.new(pos.X, H - fioH - 1.5, pos.Z),
		Color=C_LUZ, Material=Enum.Material.Neon, CanCollide=false })
	local luz = Instance.new("PointLight")
	luz.Brightness = 1.1
	luz.Range      = 26
	luz.Color      = Color3.fromRGB(255, 192, 75)
	luz.Parent     = bulbo
end

-- ─────────────────────────────────────────────────────────────
-- SPAWN
-- ─────────────────────────────────────────────────────────────

local spawn = Instance.new("SpawnLocation")
spawn.Size          = Vector3.new(6, 1, 6)
spawn.Position      = Vector3.new(2, 0.5, D - 8)
spawn.Anchored      = true
spawn.Color         = C_CHAO
spawn.Material      = Enum.Material.WoodPlanks
spawn.TopSurface    = Enum.SurfaceType.Smooth
spawn.BottomSurface = Enum.SurfaceType.Smooth
spawn.Neutral       = true
spawn.Parent        = LOJA

-- ─────────────────────────────────────────────────────────────
-- ILUMINAÇÃO GLOBAL — fraca, amarelada, sombria
-- ─────────────────────────────────────────────────────────────

Lighting.Ambient        = Color3.fromRGB(32, 24, 12)
Lighting.Brightness     = 0.35
Lighting.ColorShift_Top = Color3.fromRGB(190, 155, 80)
Lighting.OutdoorAmbient = Color3.fromRGB(14, 10, 6)
Lighting.FogEnd         = 100
Lighting.FogColor       = Color3.fromRGB(165, 138, 95)

local atm = Lighting:FindFirstChildOfClass("Atmosphere")
if atm then atm:Destroy() end

local novaAtm = Instance.new("Atmosphere")
novaAtm.Density = 0.55
novaAtm.Offset  = 0.22
novaAtm.Color   = Color3.fromRGB(195, 162, 108)
novaAtm.Glare   = 0.04
novaAtm.Haze    = 3.5
novaAtm.Parent  = Lighting

print("[Environment] Loja Nível 1 'Pobre' construída.")
