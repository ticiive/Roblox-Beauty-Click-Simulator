-- SCRIPT TEMPORÁRIO: delete após ajustar o tamanho

local model = workspace:FindFirstChild("Loja-Roupa")
if not model then
	warn("[ScaleLoja] Modelo 'Loja-Roupa' não encontrado")
	return
end

local fator = 1.5  -- AJUSTE AQUI: 1.5 = 50% maior, 2.0 = dobro
model:ScaleTo(fator)
print("[ScaleLoja] Loja escalada para fator", fator)
