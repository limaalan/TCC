# CI, releases e deploy

Os workflows estão em `.github/workflows/ci.yml` e `release.yml`. Usam o mesmo builder da [execução local](build.md).

| Gatilho | Validação | Publicação |
| --- | --- | --- |
| PR com alteração em jogo/scripts/Docker/workflows | Checks e partida com executáveis Linux. | Não. |
| Push na `main` nesses caminhos | Checks leves. | Não. |
| CI manual com `full` | Quatro alvos e testes Linux/Windows; sem `full`, modo rápido Linux. | Não. |
| Release manual | Validação completa. | Não. |
| Tag `vMAJOR.MINOR.PATCH` ou pré-release | Validação completa, integridade e identidade dos artefatos. | Release, imagem e deploy. |

Mudanças apenas documentais não disparam o CI automaticamente. Os filtros e nomes dos jobs no YAML são a referência para regras de proteção da branch. Alterações de exportação específicas de Windows devem passar pela validação completa.

## Publicar uma versão

1. Integre o commit de release à `main` e execute a validação completa.
2. Crie e envie uma tag válida, por exemplo `v0.2.0`.
3. Acompanhe os jobs de validação, publicação e deploy no Actions.

O workflow exige que o commit da tag pertença à `main` e rejeita uma release já existente. Publica os quatro pacotes, `BUILD.json`, `SHA256SUMS` e `image.json`; o manifesto identifica commit, versão e estado da árvore de trabalho. O runtime usa o executável Linux testado e é publicado como `ghcr.io/<proprietario>/jumpnshoot-server`, com identidade por digest.

## Configuração remota

| Secret ou variável | Uso |
| --- | --- |
| Secrets `VPS_HOST`, `VPS_USER`, `VPS_PORT` | Destino e porta SSH. |
| Secrets `VPS_SSH_KEY`, `VPS_KNOWN_HOSTS` | Autenticação e identidade do host. |
| Variável `VPS_DEPLOY_DIR` | Diretório remoto; padrão `/opt/jumpnshoot`. |
| Variável `VPS_GAME_PORT` | Porta UDP publicada; padrão `7777`. |

`scripts/deploy-vps.sh` chama o procedimento de deploy; `scripts/deploy_server.py` administra a imagem, verifica o serviço e oferece rollback. `compose.prod.yaml` recebe a imagem pronta por `SERVER_IMAGE`. Não inclua credenciais no repositório.

## Cache e diagnóstico

O cache GHA do Buildx acelera a preparação de Godot/templates. Não guarda fontes do jogo ou cache `.godot` dos projetos; as importações continuam em cópias temporárias. Para preparar uma base de cache, execute o CI manualmente na `main`.

Consulte os logs de cada job e, em falhas, os artifacts de diagnóstico. A release [v0.1.0](https://github.com/limaalan/TCC/releases/tag/v0.1.0) possui um [workflow concluído](https://github.com/limaalan/TCC/actions/runs/39897211695); isso documenta aquela versão, não valida alterações posteriores.
