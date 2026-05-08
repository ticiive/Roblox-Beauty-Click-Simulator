-- Constrói o ambiente 3D da loja de roupas no Workspace.
-- Loja: 140 studs de largura × 120 de profundidade × 36 de altura.
-- Parede frontal fechada com abertura de porta dupla (12×16 studs).

local Workspace = game:GetService("Workspace")
local Lighting  = game:GetService("Lighting")

-- ─────────────────────────────────────────────────────────────
-- Dimensões globais (altere aqui para redimensionar tudo)
-- ─────────────────────────────────────────────────────────────

local W  = 70   -- metade da largura  (loja total = 140)
local D  = 60   -- metade da profundidade (loja total = 120)
local H  = 36   -- altura das paredes
local DW = 6    -- metade da largura da porta (porta total = 12)
local DH = 16   -- altura da porta

-- ─────────────────────────────────────────────────────────────
-- Utilitários
-- ─────────────────────────────────────────────────────────────

local LOJA = Instance.new("Model")
LOJA.Name   = "Loja"
LOJA.Parent = Workspace

local function parte(props: { [string]: any }): Part
	local p      = Instance.new("Part")
	p.Anchored   = true
	p.CanCollide = true
	p.CastShadow = true
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = LOJA
	return p
end

local function luzSpot(parent: Part, brilho: number, alcance: number, angulo: number, cor: Color3)
	local s      = Instance.new("SpotLight")
	s.Brightness = brilho
	s.Range      = alcance
	s.Angle      = angulo
	s.Color      = cor
	s.Face       = Enum.NormalId.Bottom
	s.Parent     = parent
end

-- ─────────────────────────────────────────────────────────────
-- Cores recorrentes
-- ─────────────────────────────────────────────────────────────

local C_PAREDE  = Color3.fromRGB(245, 238, 225)
local C_PISO    = Color3.fromRGB(72, 44, 22)
local C_METAL   = Color3.fromRGB(185, 180, 195)
local C_OURO    = Color3.fromRGB(200, 165, 50)
local C_MADEIRA = Color3.fromRGB(100, 62, 28)

local COR_ROUPAS = {
	Color3.fromRGB(210, 60,  90),
	Color3.fromRGB(70,  110, 210),
	Color3.fromRGB(50,  170, 110),
	Color3.fromRGB(220, 185, 40),
	Color3.fromRGB(160, 60,  170),
	Color3.fromRGB(230, 130, 50),
	Color3.fromRGB(255, 200, 210),
	Color3.fromRGB(30,  160, 200),
}

-- ─────────────────────────────────────────────────────────────
-- Limpeza
-- ─────────────────────────────────────────────────────────────

local baseplate = Workspace:FindFirstChild("Baseplate")
if baseplate then baseplate:Destroy() end

-- ─────────────────────────────────────────────────────────────
-- PISO
-- ─────────────────────────────────────────────────────────────

parte({ Name="Piso", Size=Vector3.new(W*2, 1, D*2), Position=Vector3.new(0, -0.5, 0),
	Color=C_PISO, Material=Enum.Material.Wood })

-- Tapete bordô central
parte({ Name="Tapete", Size=Vector3.new(40, 0.12, 70), Position=Vector3.new(0, 0.06, -5),
	Color=Color3.fromRGB(90, 18, 38), Material=Enum.Material.Fabric, CanCollide=false })

-- Faixa dourada na borda do tapete
for _, d in ipairs({
	{ Vector3.new(40.8, 0.12, 0.6),  Vector3.new(0, 0.06, 29.6)  },
	{ Vector3.new(40.8, 0.12, 0.6),  Vector3.new(0, 0.06, -39.6) },
	{ Vector3.new(0.6,  0.12, 70.8), Vector3.new(19.7,  0.06, -5) },
	{ Vector3.new(0.6,  0.12, 70.8), Vector3.new(-19.7, 0.06, -5) },
}) do
	parte({ Size=d[1], Position=d[2], Color=C_OURO, Material=Enum.Material.SmoothPlastic, CanCollide=false })
end

-- ─────────────────────────────────────────────────────────────
-- PAREDES (4 lados)
-- ─────────────────────────────────────────────────────────────

local C_P = { Color=C_PAREDE, Material=Enum.Material.SmoothPlastic }

-- Fundo
parte(table.move({ Name="ParedeFundo", Size=Vector3.new(W*2, H, 1), Position=Vector3.new(0, H/2, -D) }, 1, 6, 1, table.clone(C_P)))

-- Laterais
parte(table.move({ Name="ParedeDireita",  Size=Vector3.new(1, H, D*2), Position=Vector3.new(W,  H/2, 0) }, 1, 6, 1, table.clone(C_P)))
parte(table.move({ Name="ParedeEsquerda", Size=Vector3.new(1, H, D*2), Position=Vector3.new(-W, H/2, 0) }, 1, 6, 1, table.clone(C_P)))

-- Frente: lado esquerdo, lado direito e verga acima da porta
local largLado = W - DW   -- 70 - 6 = 64
parte(table.move({ Name="FrenteEsq",   Size=Vector3.new(largLado, H, 1),    Position=Vector3.new(-(DW + largLado/2), H/2,    D) }, 1, 6, 1, table.clone(C_P)))
parte(table.move({ Name="FreintDir",   Size=Vector3.new(largLado, H, 1),    Position=Vector3.new( (DW + largLado/2), H/2,    D) }, 1, 6, 1, table.clone(C_P)))
parte(table.move({ Name="Verga",       Size=Vector3.new(DW*2, H - DH, 1),   Position=Vector3.new(0, DH + (H - DH)/2,        D) }, 1, 6, 1, table.clone(C_P)))

-- Vitrine de vidro acima da porta (entre verga e teto — decorativa)
parte({ Name="VidrinePorta", Size=Vector3.new(DW*2 - 0.4, H - DH - 0.4, 0.15),
	Position=Vector3.new(0, DH + (H - DH)/2, D - 0.1),
	Color=Color3.fromRGB(180, 220, 245), Material=Enum.Material.Glass, Reflectance=0.3, CanCollide=false })

-- ─────────────────────────────────────────────────────────────
-- TETO
-- ─────────────────────────────────────────────────────────────

parte({ Name="Teto", Size=Vector3.new(W*2, 1, D*2), Position=Vector3.new(0, H, 0),
	Color=Color3.fromRGB(255, 252, 248), Material=Enum.Material.SmoothPlastic })

-- Faixas neon no teto (2 paralelas)
for _, xn in ipairs({ -18, 18 }) do
	local fn = parte({ Size=Vector3.new(1.5, 0.25, D * 1.5), Position=Vector3.new(xn, H - 0.5, -D/4),
		Color=Color3.fromRGB(255, 220, 165), Material=Enum.Material.Neon, CanCollide=false })
	local pl = Instance.new("PointLight")
	pl.Brightness = 1.2
	pl.Range      = 35
	pl.Color      = Color3.fromRGB(255, 218, 155)
	pl.Parent     = fn
end

-- ─────────────────────────────────────────────────────────────
-- RODAPÉ dourado em todas as paredes
-- ─────────────────────────────────────────────────────────────

local rodapes = {
	{ Vector3.new(W*2 + 1, 0.9, 0.35), Vector3.new(0,  0.45, -D)     },   -- fundo
	{ Vector3.new(W*2 + 1, 0.9, 0.35), Vector3.new(0,  0.45,  D)     },   -- frente
	{ Vector3.new(0.35, 0.9, D*2),     Vector3.new( W, 0.45,  0)     },   -- direita
	{ Vector3.new(0.35, 0.9, D*2),     Vector3.new(-W, 0.45,  0)     },   -- esquerda
}
for _, r in ipairs(rodapes) do
	parte({ Size=r[1], Position=r[2], Color=C_OURO, Material=Enum.Material.SmoothPlastic, CanCollide=false })
end

-- ─────────────────────────────────────────────────────────────
-- MOLDURA DA PORTA
-- ─────────────────────────────────────────────────────────────

local molduraOuro = { Color=C_OURO, Material=Enum.Material.Metal, CanCollide=false }
-- Montantes verticais
parte(table.move({ Size=Vector3.new(0.5, DH, 0.5), Position=Vector3.new(-DW, DH/2, D) }, 1, 4, 1, table.clone(molduraOuro)))
parte(table.move({ Size=Vector3.new(0.5, DH, 0.5), Position=Vector3.new( DW, DH/2, D) }, 1, 4, 1, table.clone(molduraOuro)))
-- Verga horizontal
parte(table.move({ Size=Vector3.new(DW*2 + 0.5, 0.5, 0.5), Position=Vector3.new(0, DH, D) }, 1, 4, 1, table.clone(molduraOuro)))

-- ─────────────────────────────────────────────────────────────
-- ARARAS DE ROUPA
-- ─────────────────────────────────────────────────────────────

local function arara(cx: number, cz: number, comprimento: number?)
	local L = comprimento or 8

	parte({ Size=Vector3.new(0.25, 5, 0.25), Position=Vector3.new(cx - L/2, 2.5, cz), Color=C_METAL, Material=Enum.Material.Metal })
	parte({ Size=Vector3.new(0.25, 5, 0.25), Position=Vector3.new(cx + L/2, 2.5, cz), Color=C_METAL, Material=Enum.Material.Metal })
	parte({ Size=Vector3.new(L, 0.2, 0.2),   Position=Vector3.new(cx, 5, cz),         Color=C_METAL, Material=Enum.Material.Metal })
	parte({ Size=Vector3.new(L * 0.65, 0.15, 1.6), Position=Vector3.new(cx, 0.08, cz), Color=C_METAL, Material=Enum.Material.Metal })

	local qtd = math.floor(L / 1.4)
	for i = 1, qtd do
		local cor  = COR_ROUPAS[((i - 1) % #COR_ROUPAS) + 1]
		local offX = -(L/2 - 0.7) + (i - 1) * (L - 1.4) / math.max(qtd - 1, 1)
		parte({ Size=Vector3.new(1.4, 0.12, 0.08), Position=Vector3.new(cx + offX, 4.9, cz), Color=C_METAL, Material=Enum.Material.Metal, CanCollide=false })
		parte({ Size=Vector3.new(1.2, 1.6, 0.12),  Position=Vector3.new(cx + offX, 3.9, cz), Color=cor, Material=Enum.Material.Fabric, CanCollide=false })
	end
end

-- Fileira do fundo  (z = -48)
arara(-50, -48)
arara(-26, -48)
arara(  0, -48)
arara( 26, -48)
arara( 50, -48)

-- Fileira do meio-fundo  (z = -30)
arara(-46, -30)
arara(-22, -30)
arara( 22, -30)
arara( 46, -30)

-- Fileira do meio-frente  (z = -10)
arara(-42, -10)
arara( 42, -10)

-- Araras laterais (paralelas à parede, orientação Z)
-- usa a mesma função mas troca eixos criando uma versão rotacionada
local function araraDireita(cx: number, cz: number)
	parte({ Size=Vector3.new(0.25, 5, 0.25), Position=Vector3.new(cx, 2.5, cz - 4), Color=C_METAL, Material=Enum.Material.Metal })
	parte({ Size=Vector3.new(0.25, 5, 0.25), Position=Vector3.new(cx, 2.5, cz + 4), Color=C_METAL, Material=Enum.Material.Metal })
	parte({ Size=Vector3.new(0.2, 0.2, 8),   Position=Vector3.new(cx, 5, cz),        Color=C_METAL, Material=Enum.Material.Metal })
	parte({ Size=Vector3.new(1.6, 0.15, 5),  Position=Vector3.new(cx, 0.08, cz),     Color=C_METAL, Material=Enum.Material.Metal })
	for i = 1, 5 do
		local cor = COR_ROUPAS[((i - 1) % #COR_ROUPAS) + 1]
		local offZ = -2 + (i - 1)
		parte({ Size=Vector3.new(0.08, 0.12, 1.4), Position=Vector3.new(cx, 4.9, cz + offZ), Color=C_METAL, Material=Enum.Material.Metal, CanCollide=false })
		parte({ Size=Vector3.new(0.12, 1.6, 1.2),  Position=Vector3.new(cx - 0.7, 3.9, cz + offZ), Color=cor, Material=Enum.Material.Fabric, CanCollide=false })
	end
end

araraDireita(60, -40)
araraDireita(60, -20)
araraDireita(-60, -40)
araraDireita(-60, -20)

-- ─────────────────────────────────────────────────────────────
-- PRATELEIRAS (parede esquerda e direita, zona fundo)
-- ─────────────────────────────────────────────────────────────

for lado = -1, 1, 2 do
	for i = 0, 3 do
		local y = 5 + i * 5.5
		local xBase = lado * (W - 1.2)
		parte({ Size=Vector3.new(0.3, 0.15, 18), Position=Vector3.new(xBase, y, -38),
			Color=C_MADEIRA, Material=Enum.Material.Wood })
		for j = 0, 5 do
			local cor = COR_ROUPAS[((i * 6 + j) % #COR_ROUPAS) + 1]
			parte({ Size=Vector3.new(1.3, 1.3, 1.0), Position=Vector3.new(xBase - lado * 0.4, y + 0.75, -45 + j * 3),
				Color=cor, Material=Enum.Material.SmoothPlastic, CanCollide=false })
		end
	end
end

-- ─────────────────────────────────────────────────────────────
-- BALCÃO DE ATENDIMENTO (fundo, com ilha e caixa)
-- ─────────────────────────────────────────────────────────────

parte({ Name="Balcao",      Size=Vector3.new(22, 3.8, 4),   Position=Vector3.new(0, 1.9, -D + 7),
	Color=C_MADEIRA, Material=Enum.Material.Wood })
parte({ Name="BalcaoTampo", Size=Vector3.new(23, 0.3, 4.6), Position=Vector3.new(0, 3.95, -D + 7),
	Color=Color3.fromRGB(230, 220, 205), Material=Enum.Material.Marble })

-- Caixa registradora
parte({ Size=Vector3.new(2.5, 1.4, 1.5), Position=Vector3.new(-7, 4.5, -D + 7),
	Color=Color3.fromRGB(25, 25, 32), Material=Enum.Material.SmoothPlastic })
parte({ Size=Vector3.new(2,   1.1, 0.1), Position=Vector3.new(-7, 5.5, -D + 6.8),
	Color=Color3.fromRGB(50, 195, 255), Material=Enum.Material.Neon, CanCollide=false })

-- Expositor de perfumes / acessórios no balcão
for j = 0, 4 do
	local cor = COR_ROUPAS[(j % #COR_ROUPAS) + 1]
	parte({ Size=Vector3.new(0.7, 1.5 - j * 0.1, 0.7), Position=Vector3.new(4 + j * 1.5, 5.1, -D + 6.5),
		Color=cor, Material=Enum.Material.Glass, Reflectance=0.4, CanCollide=false })
end

-- ─────────────────────────────────────────────────────────────
-- PROVADORES (canto fundo-direito e fundo-esquerdo)
-- ─────────────────────────────────────────────────────────────

local function provador(px: number, pz: number, ladoX: number)
	local LS = 8   -- largura
	local PS = 10  -- profundidade
	local PH = 14  -- altura

	-- Paredes do provador (3 lados; frente aberta com cortina)
	parte({ Size=Vector3.new(LS, PH, 0.3), Position=Vector3.new(px, PH/2, pz - PS/2),     Color=C_PAREDE, Material=Enum.Material.SmoothPlastic })
	parte({ Size=Vector3.new(0.3, PH, PS), Position=Vector3.new(px - ladoX * LS/2, PH/2, pz), Color=C_PAREDE, Material=Enum.Material.SmoothPlastic })
	parte({ Size=Vector3.new(0.3, PH, PS), Position=Vector3.new(px + ladoX * LS/2, PH/2, pz), Color=C_PAREDE, Material=Enum.Material.SmoothPlastic })
	-- Cortina
	parte({ Size=Vector3.new(LS - 0.5, PH * 0.85, 0.15), Position=Vector3.new(px, PH * 0.57, pz + PS/2),
		Color=Color3.fromRGB(160, 30, 60), Material=Enum.Material.Fabric, CanCollide=false })
	-- Espelho interno
	parte({ Size=Vector3.new(0.15, 9, 4), Position=Vector3.new(px - ladoX * (LS/2 - 0.2), PH/2, pz),
		Color=Color3.fromRGB(210, 230, 245), Material=Enum.Material.Glass, Reflectance=0.6, CanCollide=false })
	-- Banco
	parte({ Size=Vector3.new(3, 0.4, 1.5), Position=Vector3.new(px + ladoX * 2, 1.8, pz - PS/2 + 1.5),
		Color=C_MADEIRA, Material=Enum.Material.Wood })
end

provador(-55, -15, -1)
provador( 55, -15,  1)

-- ─────────────────────────────────────────────────────────────
-- ESPELHOS NA PAREDE (zona central)
-- ─────────────────────────────────────────────────────────────

for i = 0, 2 do
	local zM = -35 + i * 18
	-- Parede direita
	parte({ Size=Vector3.new(0.2, 14, 8), Position=Vector3.new(W - 0.4, 9, zM),
		Color=Color3.fromRGB(210, 230, 245), Material=Enum.Material.Glass, Reflectance=0.65, CanCollide=false })
	parte({ Size=Vector3.new(0.3, 14.5, 0.5), Position=Vector3.new(W - 0.3, 9, zM - 4.25),
		Color=C_OURO, Material=Enum.Material.Metal, CanCollide=false })
	parte({ Size=Vector3.new(0.3, 14.5, 0.5), Position=Vector3.new(W - 0.3, 9, zM + 4.25),
		Color=C_OURO, Material=Enum.Material.Metal, CanCollide=false })
	-- Parede esquerda (espelhos menores)
	if i < 2 then
		parte({ Size=Vector3.new(0.2, 12, 6), Position=Vector3.new(-W + 0.4, 8, zM),
			Color=Color3.fromRGB(210, 230, 245), Material=Enum.Material.Glass, Reflectance=0.65, CanCollide=false })
	end
end

-- ─────────────────────────────────────────────────────────────
-- MANEQUINS (vitrine próxima à entrada)
-- ─────────────────────────────────────────────────────────────

local function manequim(px: number, pz: number, cor: Color3)
	parte({ Size=Vector3.new(1.6, 0.35, 1.6), Position=Vector3.new(px, 0.18, pz),
		Color=Color3.fromRGB(45, 35, 30), Material=Enum.Material.SmoothPlastic })
	parte({ Size=Vector3.new(0.22, 4.2, 0.22), Position=Vector3.new(px, 2.1, pz),
		Color=Color3.fromRGB(155, 142, 125), Material=Enum.Material.Metal })
	parte({ Size=Vector3.new(2.0, 2.8, 1.0), Position=Vector3.new(px, 5.5, pz),
		Color=cor, Material=Enum.Material.Fabric })
	-- Cabeça
	parte({ Size=Vector3.new(1.1, 1.1, 1.0), Position=Vector3.new(px, 7.5, pz),
		Color=Color3.fromRGB(230, 210, 190), Material=Enum.Material.SmoothPlastic })
end

manequim(-55, 35, Color3.fromRGB(15, 15, 75))
manequim(-35, 38, Color3.fromRGB(175, 20, 55))
manequim(  0, 40, Color3.fromRGB(30, 100, 55))
manequim( 35, 38, Color3.fromRGB(200, 165, 30))
manequim( 55, 35, Color3.fromRGB(80, 20, 110))

-- ─────────────────────────────────────────────────────────────
-- PLANTAS DECORATIVAS
-- ─────────────────────────────────────────────────────────────

local function planta(px: number, pz: number)
	parte({ Size=Vector3.new(1.4, 1.4, 1.4), Position=Vector3.new(px, 0.7, pz),
		Color=Color3.fromRGB(85, 50, 22), Material=Enum.Material.SmoothPlastic })
	parte({ Size=Vector3.new(1.8, 2.2, 1.8), Position=Vector3.new(px, 2.4, pz),
		Color=Color3.fromRGB(38, 115, 46), Material=Enum.Material.Grass })
	parte({ Size=Vector3.new(1.0, 2.8, 1.0), Position=Vector3.new(px + 0.6, 2.9, pz - 0.4),
		Color=Color3.fromRGB(30, 95, 38), Material=Enum.Material.Grass, CanCollide=false })
	parte({ Size=Vector3.new(0.8, 2.4, 0.8), Position=Vector3.new(px - 0.5, 2.6, pz + 0.5),
		Color=Color3.fromRGB(42, 128, 50), Material=Enum.Material.Grass, CanCollide=false })
end

-- Cantos internos
planta(-67, 57)  planta(67,  57)
planta(-67, -57) planta(67, -57)
-- Flanqueando a entrada
planta(-12, 52)  planta(12,  52)

-- ─────────────────────────────────────────────────────────────
-- LUSTRES DECORATIVOS (centro do teto)
-- ─────────────────────────────────────────────────────────────

local function lustre(lx: number, lz: number)
	-- Corrente
	parte({ Size=Vector3.new(0.3, 3, 0.3), Position=Vector3.new(lx, H - 1.5, lz),
		Color=C_OURO, Material=Enum.Material.Metal, CanCollide=false })
	-- Base
	local base = parte({ Size=Vector3.new(2.5, 0.4, 2.5), Position=Vector3.new(lx, H - 3.2, lz),
		Color=C_OURO, Material=Enum.Material.Metal })
	-- Braços com lâmpadas
	for a = 0, 3 do
		local angle = math.rad(a * 90)
		local bx = lx + math.cos(angle) * 1.5
		local bz = lz + math.sin(angle) * 1.5
		parte({ Size=Vector3.new(0.18, 0.18, 3), CFrame=CFrame.new(lx + math.cos(angle)*0.75, H - 3.2, lz + math.sin(angle)*0.75) * CFrame.Angles(0, angle, 0),
			Color=C_OURO, Material=Enum.Material.Metal, CanCollide=false })
		local lamp = parte({ Size=Vector3.new(0.6, 0.6, 0.6), Position=Vector3.new(bx, H - 3.5, bz),
			Color=Color3.fromRGB(255, 245, 200), Material=Enum.Material.Neon, CanCollide=false })
		luzSpot(lamp, 3, 22, 70, Color3.fromRGB(255, 235, 185))
	end
end

lustre(-35, -45)
lustre( 35, -45)
lustre(-35,  -5)
lustre( 35,  -5)
lustre(  0, -25)

-- ─────────────────────────────────────────────────────────────
-- LUZES DE TETO em grade (distribuição uniforme)
-- ─────────────────────────────────────────────────────────────

local luzX = { -55, -30, 0, 30, 55 }
local luzZ = { -50, -28, -6, 16, 38 }

for _, lx in ipairs(luzX) do
	for _, lz in ipairs(luzZ) do
		local lamp = parte({
			Size     = Vector3.new(0.55, 0.3, 0.55),
			Position = Vector3.new(lx, H - 0.3, lz),
			Color    = Color3.fromRGB(255, 248, 220),
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
		luzSpot(lamp, 3.5, 30, 50, Color3.fromRGB(255, 232, 182))
	end
end

-- ─────────────────────────────────────────────────────────────
-- SPAWN dentro da loja (logo atrás da porta)
-- ─────────────────────────────────────────────────────────────

local spawn = Instance.new("SpawnLocation")
spawn.Size          = Vector3.new(8, 1, 6)
spawn.Position      = Vector3.new(0, 0.5, D - 10)
spawn.Anchored      = true
spawn.Color         = C_PISO
spawn.Material      = Enum.Material.Wood
spawn.TopSurface    = Enum.SurfaceType.Smooth
spawn.BottomSurface = Enum.SurfaceType.Smooth
spawn.Neutral       = true
spawn.Parent        = LOJA

-- ─────────────────────────────────────────────────────────────
-- ILUMINAÇÃO GLOBAL
-- ─────────────────────────────────────────────────────────────

Lighting.Ambient        = Color3.fromRGB(55, 42, 32)
Lighting.Brightness     = 0.7
Lighting.ColorShift_Top = Color3.fromRGB(255, 220, 170)
Lighting.OutdoorAmbient = Color3.fromRGB(25, 18, 12)
Lighting.FogEnd         = 400
Lighting.FogColor       = Color3.fromRGB(245, 230, 210)

local atm = Instance.new("Atmosphere")
atm.Density = 0.25
atm.Offset  = 0.08
atm.Color   = Color3.fromRGB(240, 215, 185)
atm.Glare   = 0.15
atm.Haze    = 1.2
atm.Parent  = Lighting

print("[Environment] Loja de roupas construída — 140×120 studs, 4 paredes fechadas.")
