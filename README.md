# jumpnshoot

Jogo 3D multijogador de tiro em primeira pessoa desenvolvido como TCC. Combina combate em equipes e movimentação com salto duplo e jump pads. A versão atual reúne Team Deathmatch e King of the Hill no mapa Highrise, com Client e Server dedicado separados.

## Gerar as builds

O processo usa Docker Linux x86_64 e fixa Godot 4.5.1. No Windows, execute pelo WSL2. Na raiz do repositório, após preparar Docker e Compose:

```bash
mkdir -p build/releases build/smoke build/diagnostics
docker compose --profile tools build build
docker compose --profile tools run --rm build
```

A saída fica em `build/releases/local/`, com Client e Server para Windows/Linux, pacotes, manifesto e checksums. Os executáveis usam `jumpnshoot-client` e `jumpnshoot-server`; a imagem do servidor utiliza o mesmo binário Linux exportado.

O [guia de build e verificação](docs/how_to/build-client-and-server.md) cobre pré-requisitos, seleção de alvos, execução no Docker/WSL e testes dos artefatos. Use outra `BUILD_VERSION` para gerar uma nova release: uma saída existente não é sobrescrita.

## Executar e configurar

Inicie o Server antes dos Clients e configure endereço e porta no Client. No primeiro uso, o endereço vem vazio; a porta padrão de gameplay é **7777/UDP**.

- [Partida local com os projetos Godot](docs/how_to/run-local-match.md).
- [Execução de uma build do Server](docs/how_to/run-server-build.md).
- [Configuração: parâmetros, padrões e precedência](docs/how_to/configure-client-and-server.md).
- [CI, releases e deploy](docs/how_to/ci-cd.md).
- [Coleta de métricas em CSV](docs/how_to/use-and-extend-metrics.md).

## Onde alterar cada parte

| Parte | Local |
| --- | --- |
| Projetos Godot independentes | `initial_project/Client/` e `initial_project/Server/` |
| Contratos, presets e definições comuns | `initial_project/shared/` |
| Endereço e preferências iniciais do Client | `initial_project/Client/default_settings.cfg` |
| Preferências persistidas | `user://settings.cfg`, administrado por `initial_project/Client/game/settings_manager.gd` |
| Conexões e quantidade de lobbies | `initial_project/Server/server/server.gd` |
| Modo, mapa, lotação, tempo e pontuação | `initial_project/shared/match_preset_registry.gd` |
| Exportação | `export_presets.cfg` de cada projeto e `scripts/build_release.py` |

Os presets atuais usam dois participantes por partida. Limites configurados de conexões/lobbies não são capacidade de desempenho demonstrada. Consulte o guia de configuração antes de aumentar a lotação ou alterar mapas.

## Continuar o projeto

Comece pela [arquitetura](docs/architecture/overview.md) e pelo [índice técnico](docs/README.md). Os projetos compartilham definições, mas têm cenas, autoloads e comportamento de lobby próprios; preserve os contratos de rede entre os dois lados. O guia de build explica a preparação dos arquivos compartilhados.

Há testes das ferramentas em `scripts/tests/` e verificações headless das builds em `scripts/smoke/` e `scripts/test_exports.py`. Eles cobrem fluxos específicos e complementam a verificação manual de controles, imagem, áudio e combate.

O texto atual do TCC está em [docs/report](docs/report/LEIA-ME.md); use `main.tex` como documento principal. As tarefas também podem ser acompanhadas no GitHub Projects, com cards vinculados a issues. O padrão de commit do repositório é prefixado pelo número da tarefa, por exemplo: `2. Criação do modelo de personagem`.

## Créditos

Os [avisos de terceiros](THIRD_PARTY_NOTICES.md) identificam os ícones conferidos, a procedência dos áudios e as pendências de atribuição/distribuição. Esse registro ainda é parcial; não define uma licença única para todo o código, as artes ou o texto autoral.
