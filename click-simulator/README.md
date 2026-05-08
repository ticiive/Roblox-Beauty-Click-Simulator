# ClickSimulator

Jogo de Click Simulator para Roblox, construído com **Rojo** (sem dependência de UI pré-montada no Studio).

## O que é

Clique num botão para ganhar moedas, compre upgrades para aumentar seu poder de clique, e veja seu progresso salvo entre sessões via DataStore.

## Como rodar

### Pré-requisitos
- [Rojo CLI](https://rojo.space/docs/installation/) instalado
- [Plugin Rojo](https://create.roblox.com/store/asset/13916111004) instalado no Roblox Studio

### Passos

```bash
# 1. Dentro da pasta do projeto, inicie o servidor Rojo:
rojo serve

# 2. No Roblox Studio, abra o plugin Rojo (aba Plugins)
#    e clique em "Connect" (ele vai detectar localhost:34872)

# 3. Pressione F5 ou clique em "Play" para testar
```

> **Importante — DataStore no Studio:** Para o salvamento funcionar em testes locais, ative `Enable Studio Access to API Services` em:
> **Game Settings → Security → Enable Studio Access to API Services**

## Estrutura

```
click-simulator/
├── default.project.json        Mapeamento Rojo → Roblox Services
├── README.md
└── src/
    ├── server/
    │   ├── Setup.server.luau       Cria os RemoteEvents em ReplicatedStorage
    │   └── GameLogic.server.luau   Lógica principal, DataStore, anti-exploit
    ├── client/
    │   └── ClientUI.client.luau    Interface completa criada via código
    └── shared/
        └── GameConfig.luau         Upgrades e configurações globais
```

## Upgrades disponíveis

| Nome        | Custo   | Bônus de clique |
|-------------|---------|-----------------|
| Click +1    | 50      | +1              |
| Click +5    | 500     | +5              |
| Click +25   | 5.000   | +25             |
| Click +100  | 50.000  | +100            |
