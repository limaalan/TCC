# CI e releases de jumpnshoot

O nome canônico do jogo e seu identificador técnico são **jumpnshoot**.
O mesmo builder `scripts/build_release.py` atende ao uso local e ao GitHub Actions.

## Quando cada validação roda

| Evento | Checks leves | Exportações e testes de jogo | Pacotes e upload | Publicação/deploy |
| --- | --- | --- | --- | --- |
| PR com mudanças em jogo/scripts/Docker/workflows | Sim | Client/Server Linux, ENet e TDM/KOTH | Não | Não |
| Push na `main` nesses caminhos | Sim | Não | Não | Não |
| CI manual, `full` marcado (padrão) | Sim | Quatro alvos e testes Linux/Windows | Sim | Não |
| CI manual, `full` desmarcado | Sim | Mesmo modo rápido dos PRs | Não | Não |
| Release manual | Sim | Sempre completa | Sim | Não |
| Tag `vMAJOR.MINOR.PATCH` ou prerelease, em commit da `main` | Sim | Sempre completa | Sim | Sim |

Mudanças apenas em documentação não acionam o CI automaticamente. Builds Linux
e Windows passam antes de publicar uma tag. O workflow de Release obriga `full: true`
e também confere que o manifesto contém os quatro alvos e `packaged: true`.

Os PRs recebem verificação de jogo em Linux. Problemas específicos de Windows
são detectados na validação completa; execute-a manualmente antes de integrar
alterações de exportação, configuração ou comportamentos específicos de Windows.
O merge na main não repete os testes de jogo já executados no PR.

## Cache do builder

`docker/setup-buildx-action` e `docker/build-push-action`, fixados por SHA, constroem
`docker/build.Dockerfile` e carregam a imagem local `jumpnshoot-builder:4.5.1`.
Depois o Compose usa essa imagem para chamar o mesmo script de exportação local.
Não é publicada uma imagem extra de builder no GHCR.

O cache GHA v2 reaproveita camadas com dependências, Godot e templates. Alterações
no Dockerfile/instalador invalidam as camadas correspondentes automaticamente.
O cache não contém fontes do jogo, `.godot` ou executáveis exportados. Cada build
continua copiando os projetos para diretórios temporários e importando do zero.

A primeira execução sem cache prepara tudo normalmente. Cache ausente ou removido
não exige ação do desenvolvedor: as ferramentas são reconstruídas. Falhas ao salvar
o cache não reprovam a build; exportação de cache tem timeout de dois minutos.
O cache acelera as ferramentas, mas importação dos assets e exportação do jogo
continuam consumindo tempo em cada validação de jogo.

O GitHub limita a visibilidade dos caches por branch. Para oferecer um cache base
aos PRs, execute uma vez **CI → Run workflow → branch main**, depois de integrar
estes arquivos. O modo completo é o padrão; desmarcar `full` também prepara o cache
com uma validação Linux. Isso é uma otimização inicial, não um requisito para funcionar.
Quando mudar Godot/dependências, repetir uma execução manual na main atualiza essa base.

## Configuração no GitHub

1. Envie os arquivos quando decidir fazer commit/push. Nenhuma configuração de cache
   precisa ser criada manualmente: o backend usa as credenciais temporárias do Actions.
2. Se **Settings → Actions → General** restringir Actions permitidos, além dos
   Actions do GitHub já usados, libere `docker/setup-buildx-action` e
   `docker/build-push-action`. Se usa uma lista de SHAs, use os fixados no `ci.yml`.
3. Se há checks obrigatórios na proteção da branch/ruleset, use `checks` e `linux`
   para PRs. Windows agora pertence à validação completa; remova uma exigência
   independente dele em PRs. Não dependa apenas de `checks`, pois ele não testa o jogo.
4. Os filtros de caminhos também se aplicam ao workflow: se aceitar PRs só de docs,
   adapte os checks obrigatórios para não esperar um workflow que não foi disparado.
5. Depois do merge, rode CI manualmente na main uma vez para preparar o cache base.
   As execuções podem ser conferidas em **Actions → Caches**.

Não são necessários secrets novos nem mudanças na VPS. O deploy continua usando
`VPS_USER=root` na Hostinger e os secrets SSH já definidos. A tag continua sendo
o gatilho de publicação e deploy; `Run workflow` continua apenas um ensaio.

## Uso local

Build completa (padrão existente):

```bash
mkdir -p build/releases build/smoke build/diagnostics
docker compose --profile tools build build
docker compose --profile tools run --rm build
```

Modo rápido, depois de preparar o builder:

```bash
export BUILD_VERSION=preview-1
docker compose --profile tools run --rm build \
  --source /source --output /output --version "$BUILD_VERSION" \
  --targets client-linux server-linux --no-package
```

O modo rápido mantém os executáveis Linux, dependências, instruções, `BUILD.json`
e `SHA256SUMS`, mas não cria ZIP/tar.gz. O manifesto registra `packaged: false`.
Ele continua apto ao teste local com o runtime Docker; não é um pacote de release.
O comando sem `--no-package` mantém o comportamento completo anterior.

## Artifacts e diagnósticos

Somente validações completas enviam os quatro pacotes, `BUILD.json` e `SHA256SUMS`
para transferência ao runner Windows/publicação. Não há cópia adicional dos
executáveis descompactados. A retenção continua de três dias.

Logs de diagnóstico são enviados como artifact apenas em falhas, inclusive nos
PRs; os logs dos próprios steps continuam no Actions. O upload automático de
registros do Buildx foi desativado para não gerar artifacts extras em todo PR.
Execuções antigas do mesmo PR continuam sendo canceladas automaticamente.

Referências: [cache Docker no Actions](https://docs.docker.com/build/ci/github-actions/cache/)
e [escopo do cache GHA](https://docs.docker.com/build/cache/backends/gha/).
