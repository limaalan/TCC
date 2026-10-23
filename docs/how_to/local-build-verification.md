# Verificação local — 2026-10-22

Branch: `feat/add-docker`. Commit-base: `a452b516c00a135b14e440ac3a24bba8b48817d9`.
Builds com alterações locais (`dirty=true`); nenhum commit ou push feito.

## Ambiente e resultados

- Windows: Godot 4.5.1 e Python; Ubuntu WSL2 x86_64 com Docker Engine 29.8.0 e Compose 5.5.1.
- Builder: Godot 4.5.1 standard oficial e templates release Windows/Linux, com checksums conferidos. Blender ausente.
- Importações Client/Server em cópias limpas sem `.godot`, com `.blend` preservados e importação Blender desativada: passaram.
- Baseline Client Windows/Server Linux sem stripping: `build/releases/baseline`.
- A primeira tentativa de stripping foi rejeitada pelo teste do recurso real: o valor do preset precisava ser a string `strip`. Corrigido; a tentativa anterior ficou em `build/releases/local-before-strip` para diagnóstico.
- Quatro builds finais em `build/releases/local`, com pacotes, manifesto e SHA256SUMS.
- Repetição limpa dos quatro alvos em `build/releases/local-repeat`: passou. Não se exigiu igualdade byte a byte.
- Server Linux: modo dedicado e `PlaceholderTexture2D` confirmados antes de publicar cada release local.
- Runtime: usuário sem privilégios, filesystem somente leitura, logs de startup, handshake ENet positivo e negativo com destino indisponível.
- Dois Clients Linux contra Server Linux Docker: TDM e KOTH em Highrise, mapa/spawn de dois jogadores e snapshots recebidos.
- Dois Clients Windows contra Server Linux Docker: TDM e KOTH com os mesmos critérios.
- Server Windows: feature dedicada/stripping e partida com dois Clients Windows confirmados.
- Menu do Client Windows renderizado com Vulkan/Forward+ na GPU e inspecionado: `build/smoke/render/frame00000004.png`. O teste não substitui jogar uma partida com interface.
- Onze testes de comportamento dos scripts passaram; todos os arquivos de SHA256SUMS foram conferidos. Hash do executável no runtime igual ao pacote distribuído; usuário do runtime é UID 10001.
- Revisão inline contra o plano: sem achados críticos no processo de build/container. Aceite manual de jogabilidade permanece pendente; mensagens de teardown estão descritas abaixo.

## Achados e limites

- Houve tentativas Windows -> WSL com timeout. UDP simples no WSL e numa porta Docker publicada passou. Observou-se o dockerd e o serviço voltando a iniciar entre chamadas WSL isoladas, com RestartCount=0: isso é consistente com encerramento da distribuição, não com restart do jogo pelo Docker. Manter uma sessão WSL acompanhando logs estabilizou a continuidade do daemon/container. O guia exige terminal WSL aberto durante testes Windows. Não houve mudança de firewall, modo de rede WSL ou IP de produção.
- No cliente original e nos testes aparece `resources still in use at exit`; é um aviso de teardown registrado separadamente. Não se considera sucesso se faltar marcador de partida ou houver outro erro de runtime.
- Durante desconexão, foi observado `Unable to send packet on channel 0, max channels: 0`. No teste do Server nativo, confere-se o log antes de encerrar os clientes; essa mensagem exata é reportada separadamente apenas no teardown após essa conferência. A lógica de rede do jogo não foi alterada para corrigir esse comportamento.
- Testes automáticos são headless. Ainda é necessário jogar manualmente para conferir imagem, áudio, entrada, colisões/dano, respawn, pickups, granadas e resultado final. Mapa/spawn/snapshots não equivalem à cobertura completa de gameplay.
- Sem VPS, GHCR, GitHub Actions, assinatura ou alterações de métricas nesta etapa.

## Evidências locais (ignoradas pelo Git)

- `build/releases/local.logs/`: importações, exportações e `server-dedicated-check.log`.
- `build/releases/local-repeat.logs/`: repetição limpa.
- `build/smoke/windows-docker-tdm/` e `windows-docker-koth/`: Clients Windows no Server Docker.
- `build/smoke/windows-native-tdm/`: Server Windows e dois Clients Windows.
- `build/smoke/linux/` e `linux-koth/`: testes Linux iniciais; novas execuções separam logs por preset.
- `build/local-runtime-build.log`: construção do runtime.

## Validação após atualização dos nomes técnicos para jumpnshoot

Commit-base: `9dc6de2`, com alterações locais. As releases anteriores foram preservadas.

- Nova release `build/releases/jumpnshoot-local/`: quatro executáveis e pacotes com o novo nome; todos os arquivos de `SHA256SUMS` conferidos.
- Importações limpas, quatro exportações e teste dedicado/stripping do Server Linux passaram.
- Onze testes dos scripts, sintaxe Bash, configuração Compose e JSON do design system passaram.
- Runtime `jumpnshoot-server:jumpnshoot-local` reconstruído e iniciado no Docker.
- Dois Clients Linux contra Docker: TDM; dois Clients Windows contra Docker: KOTH; Server Windows com dois Clients Windows: TDM. Todos receberam os marcadores de partida esperados.
- Os avisos conhecidos de recursos no encerramento continuam registrados; não houve erro novo nesses testes. A conferência manual completa de gameplay continua pendente.
- Evidências: `build/jumpnshoot-build.log`, `build/releases/jumpnshoot-local.logs/`, `build/smoke/linux-tdm_highrise/`, `build/smoke/jumpnshoot-native/` e `build/smoke/jumpnshoot-windows-docker/`.

Após essa validação, o nome de apresentação foi corrigido nos fontes para
**Jump'n'Shoot**, mantendo `jumpnshoot` nos nomes técnicos. Os onze testes e
as conferências de sintaxe/configuração passaram novamente; os artefatos
acima não foram regenerados após essa correção textual.
