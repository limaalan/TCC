# Executar uma partida local

## Objetivo

Subir o Server e conectar um ou mais Clients locais para validar gameplay.

## Procedimento

1. Crie as junctions de código compartilhado, se ainda não existirem:

```powershell
.\initial_project\setup_shared_links.ps1
```

2. Em um terminal, inicie o Server:

```powershell
godot --path initial_project/Server --headless -- --port=7777
```

3. Em outro terminal, inicie o Client:

```powershell
godot --path initial_project/Client
```

4. Configure o endereço como `127.0.0.1` e a porta como `7777` no Client, se necessário, e entre em uma partida.

## Alternativa com script

`scripts/start_server.ps1` prepara os links e inicia o Server. `scripts/start_with_metrics.ps1` inicia a execução local com a dashboard de métricas.

## Verificação

Faça o teste mínimo com dois Clients: conexão, spawn, HUD, dano, munição, pickup, placar e retorno ao menu.
