# Build e execução

Execute os comandos na raiz do repositório. O builder usa Godot **4.5.1 standard** e seus templates oficiais. No Windows, os comandos Docker abaixo são executados no terminal WSL2, com Docker Engine e Compose funcionando; Godot e Blender no host não são necessários para exportar.

## Gerar cliente e servidor

```bash
mkdir -p build/releases build/smoke build/diagnostics
docker compose --profile tools build build
docker compose --profile tools run --rm build
```

Saída em `build/releases/local/`: cliente e servidor para Windows/Linux, quatro pacotes, `BUILD.json` e `SHA256SUMS`. Os executáveis usam os nomes `jumpnshoot-client` e `jumpnshoot-server`.

O builder `scripts/build_release.py` copia os projetos sem cache `.godot`, materializa `shared` e importa cada projeto separadamente. Os servidores são exportados como dedicados, com remoção de recursos visuais. Logs ficam em `build/releases/local.logs/`.

Uma saída existente não é sobrescrita. Para gerar outra versão:

```bash
export BUILD_VERSION=local-2
docker compose --profile tools run --rm build
```

Mantenha `BUILD_VERSION` definido nos comandos seguintes para usar essa mesma versão. Para selecionar apenas um alvo:

```bash
docker compose --profile tools run --rm build \
  --source /source --output /output --version client-check --targets client-windows
```

## Executar os projetos no Godot

Com Godot 4.5.1 disponível no PATH, prepare os links uma vez no PowerShell:

```powershell
.\initial_project\setup_shared_links.ps1
godot --path initial_project/Server --headless -- --port=7777
```

Em outros terminais, execute `godot --path initial_project/Client`. Configure `127.0.0.1:7777` no cliente e abra dois clientes para formar uma partida padrão.

Para iniciar um servidor Linux exportado:

```bash
chmod +x ./jumpnshoot-server.x86_64
./jumpnshoot-server.x86_64 --headless -- --port=7777
```

## Executar e verificar a build no Docker

```bash
docker compose build server
docker compose up -d server
docker compose logs --tail 30 server
docker compose --profile tools run --rm smoke
docker compose --profile tools run --rm test
MATCH_PRESET=koth_highrise docker compose --profile tools run --rm test
```

O serviço publica `127.0.0.1:7777/UDP` por padrão. Para clientes Windows com WSL em NAT, use o IP privado do WSL e defina `SERVER_BIND_ADDRESS` com esse IP ao criar o serviço. `SERVER_PORT` altera a porta publicada. Mantenha o terminal WSL ativo durante os testes Windows.

O smoke verifica handshake ENet. O teste de partida usa dois clientes headless e exige carregamento, jogadores e snapshots. Para testar os executáveis Windows com Python 3.11+, no PowerShell:

```powershell
python scripts/test_exports.py --release build/releases/local --platform windows --local-server --port 17778 --logs build/smoke/windows-native
```

Troque `--release` se tiver definido outra versão. Para apontar a um servidor existente, substitua `--local-server` por `--host ENDERECO` e ajuste `--port` para a porta desejada. Os registros ficam em `build/smoke/`; os testes das ferramentas estão em `scripts/tests/`.

Na verificação manual, confira conexão, movimentação, combate, recursos, morte/retorno, HUD e resultado em TDM e KOTH, incluindo imagem e áudio. Para encerrar o serviço local, use `docker compose stop server`.

Veja [configuração](configuration.md), [métricas](metrics.md) e [publicação](publishing.md).
