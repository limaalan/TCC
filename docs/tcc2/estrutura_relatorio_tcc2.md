
# 1 Introdução

## 1.1 Contextualização

Apresentar o desenvolvimento de jogos independentes, a relevância de jogos multijogador e o uso de motores acessíveis como Godot. Aproveitar o contexto do TCC1, atualizando números, fontes e afirmações que dependam de data.

## 1.2 Problema e motivação

Explicar o desafio de desenvolver um FPS de arena 3D em rede como projeto individual, envolvendo gameplay, comunicação de rede, arte, interface, áudio, servidor dedicado e avaliação técnica.

## 1.3 Objetivos

### 1.3.1 Objetivo geral

Apresentar como objetivo o desenvolvimento de um jogo 3D multijogador competitivo, do gênero FPS de arena, executado em rede com servidor dedicado.

### 1.3.2 Objetivos específicos

Relacionar objetivos verificáveis, como implementar movimentação e combate, modos competitivos em equipes, arquitetura Client/Server, mapa jogável, interface, efeitos audiovisuais, builds executáveis e observabilidade por métricas.

## 1.4 Escopo do trabalho

Delimitar a versão entregue: plataforma PC, partidas em rede, mapa Highrise, dois times, presets TDM/KOTH, quantidade atual de jogadores por partida e funcionalidades que ficaram fora do escopo, como Capture the Flag.

## 1.5 Estrutura do relatório

Resumir em um parágrafo o conteúdo dos capítulos seguintes.

# 2 Fundamentação teórica

## 2.1 Motores de jogos e Godot Engine

Definir motor de jogos e apresentar os recursos da Godot utilizados no projeto, como cenas, nós, GDScript, física 3D, interface, áudio, RPC e exportação multiplataforma.

## 2.2 Jogos de tiro em primeira pessoa e arena shooters

Caracterizar FPS e arena shooter, destacando combate direto, mapas compactos, movimentação rápida, armas distribuídas pelo cenário e partidas orientadas a objetivos.

## 2.3 Elementos de jogos de plataforma em ambientes 3D

Relacionar verticalidade, salto duplo, plataformas e jump pads com a movimentação e a variedade de confrontos no mapa.

## 2.4 Jogos multijogador competitivos em tempo real

Retomar as classificações úteis do TCC1: jogo em rede, competitivo, simétrico e síncrono. Remover classificações que não contribuam para entender o produto final.

# 3 Inspirações visuais e de jogabilidade

Resumir em um ou dois parágrafos a influência de Quake III Arena e Unreal Tournament no combate e nos modos de jogo, e a de Lovely Planet na movimentação e na direção visual. Evitar subseções e tabela comparativa.

# 4 Materiais e métodos

## 4.1 Ferramentas e tecnologias

Apresentar Godot 4.5, GDScript, Blender, Git, PowerShell e Python/FastAPI no contexto em que foram usados. Incluir hardware ou ambiente de execução somente se for relevante para reproduzir testes e métricas.

## 4.2 Arquitetura e tecnologias de rede

### 4.2.1 Arquitetura de comunicação

Comparar brevemente peer-to-peer e Client/Server e fundamentar a escolha de um servidor dedicado e autoritativo. Explicar autoridade, replicação de estado e o risco de confiar decisões de gameplay ao Client.

### 4.2.2 Tecnologias de comunicação utilizadas

Apresentar UDP, ENet e chamadas RPC no nível necessário para compreender a implementação na Godot. Incluir conceitos como latência, perda de pacotes e sincronização apenas quando forem usados na discussão do projeto.

## 4.3 Observabilidade

Definir a finalidade da coleta de métricas de processo, partida e rede. Contextualizar o registro em CSV, a transmissão de telemetria por UDP e o uso de dashboards como instrumentos de acompanhamento e avaliação.

## 4.4 Processo de desenvolvimento

Descrever honestamente o processo empregado durante o TCC2. Relacionar planejamento, implementação incremental, testes, revisão e refinamento das features. Caso o Double Diamond do TCC1 não tenha sido seguido integralmente, explicar sua adaptação em vez de afirmar uma aplicação literal.

## 4.5 Evolução da proposta do TCC1

Apresentar e justificar as alterações realizadas em relação ao TCC1, relacionando-as ao processo de desenvolvimento e à redução de riscos técnicos. Incluir a adoção do servidor dedicado, a substituição de CTF por KOTH, a definição dos presets, a revisão das armas e power-ups e o amadurecimento do mapa.

## 4.6 Organização do projeto

Explicar a existência de dois projetos Godot, Client e Server, e o diretório `shared`. Mostrar como essa separação permitiu executar uma build visual para jogadores e uma build headless para o servidor.

## 4.7 Método de verificação funcional

Definir os cenários usados para verificar o jogo: conexão de Clients, início de partida, modos TDM/KOTH, movimentação, combate, pickups, power-ups, HUD, término e retorno ao menu.

## 4.8 Método de coleta e análise de métricas

Registrar o ambiente, número de jogadores, duração das execuções, intervalo de amostragem e métricas observadas. Explicar como CSV e dashboard serão usados para produzir tabelas ou gráficos comparáveis.

# 5 Desenvolvimento e resultados

Este deve ser o principal capítulo do relatório. Primeiro, apresentar o produto final do ponto de vista do jogador. Em seguida, concentrar no relatório técnico a explicação da implementação, das decisões de desenvolvimento e das evidências relevantes. Encerrar o capítulo com a verificação e a análise dos resultados.

## 5.1 Visão geral do jogo final

Apresentar esta seção como um guia conciso do produto entregue, escrito do ponto de vista do jogador. Explicar o funcionamento do jogo sem antecipar detalhes internos da implementação.

### 5.1.1 Conceito e ciclo principal de jogabilidade

Descrever a versão final do jogo: entrar em uma partida, movimentar-se pela arena, obter armas e recursos, enfrentar o time adversário e pontuar conforme o modo selecionado.

### 5.1.2 Controles e movimentação

Apresentar movimentação em primeira pessoa, câmera, corrida, salto duplo e lançamento por jump pads. Incluir o mapeamento final de teclado, mouse e controle, se ambos estiverem suportados na entrega.

### 5.1.3 Fluxo de telas

Mostrar o encadeamento entre menu principal, seleção de partida, jogo, pausa e resultado final. Uma figura de fluxo é mais adequada do que descrever cada botão em detalhes.

### 5.1.4 Modos de jogo e objetivos

Apresentar, sob a perspectiva do jogador, as regras de Team Deathmatch e King of the Hill, as formas de pontuar e as condições de encerramento da partida.

### 5.1.5 Armas, granadas e recursos da arena

Descrever brevemente pistola, SMG, shotgun e granadas, bem como munição, pickups e power-ups temporários. Explicar a função desses elementos durante a partida sem detalhar seu processamento interno.

### 5.1.6 Interface e feedback ao jogador

Apresentar as informações fornecidas pela HUD, a identificação dos times e os principais sinais sonoros e visuais usados para comunicar ações e estados do jogo.

## 5.2 Relatório técnico

Esta deve ser a seção principal do capítulo. Explicar como o produto foi desenvolvido, relacionando responsabilidades dos sistemas, decisões técnicas, comportamento das principais features e evidências visuais. Evitar transformar o texto em uma listagem de arquivos ou classes.

### 5.2.1 Separação entre Client, Server e shared

Explicar as responsabilidades de apresentação, entrada, simulação autoritativa e contratos compartilhados. Usar um diagrama com os três componentes.

### 5.2.2 Comunicação e autoridade do servidor

Mostrar o fluxo de uma ação representativa, como disparo ou coleta de item: solicitação do Client, validação no Server e replicação do resultado. Relacionar a decisão com consistência e prevenção de trapaças.

### 5.2.3 Sessões, lobbies e presets de partida

Descrever conexão, associação de jogadores, criação de lobbies e seleção dos presets TDM/KOTH em Highrise. Indicar os limites de jogadores e lobbies usados na versão entregue.

### 5.2.4 Sincronização de rede

Explicar o envio de movimento, snapshots, eventos e atualização dos demais estados compartilhados. Separar a interpolação visual dos estados remotos da compensação de latência usada na validação autoritativa dos disparos.

#### 5.2.4.1 Interpolação dos estados remotos

Apresentar o buffer de 100 milissegundos e a interpolação entre snapshots conhecidos, acompanhados da figura que compara a renderização imediata com a renderização atrasada.

#### 5.2.4.2 Compensação de latência dos disparos

Descrever o timestamp do disparo, a consulta ao histórico, o reposicionamento das representações auxiliares e o raycast realizado pelo Server. Esclarecer, com a figura correspondente, que o mecanismo não executa um rollback completo da partida.

### 5.2.5 Jogador, times e ciclo de vida

Explicar instanciação local e remota, atribuição de times, spawn, vida, morte e respawn. Mostrar como cores, anéis e indicador da HUD ajudam o jogador a identificar sua equipe.

Fonte técnica: `docs/features/player-and-network-session.md`.

### 5.2.6 Modos de jogo e fluxo da partida

Explicar a implementação de Team Deathmatch e King of the Hill, incluindo obtenção de pontos, atualização do placar e estados da zona de controle. Descrever também o limite de tempo, a pontuação alvo, a determinação do vencedor e os dados enviados para a tela final.

Fonte técnica: `docs/features/match-flow-and-game-modes.md`.

### 5.2.7 Mapa Highrise e level design

Descrever a organização espacial de Highrise, verticalidade, rotas, coberturas, posições de vantagem, distribuição de pickups, spawns, jump pads e localização da zona de KOTH. Relacionar decisões do mapa aos conceitos do Capítulo 2.

Também explicar a existência das representações visual e autoritativa do mapa, sem transformar a seção em um tutorial de importação.

Fonte técnica: `docs/features/highrise-map-and-traversal.md`.

### 5.2.8 Combate, granadas e recursos temporários

Explicar de forma integrada o processamento técnico das armas e granadas: entrada local, feedback imediato, solicitação ao Server, validação, aplicação de dano, morte e replicação do resultado. Apresentar os valores finais das armas em uma tabela somente se contribuírem para comparar seus papéis.

Descrever também o controle autoritativo de munição, pickups e power-ups, incluindo consumo, coleta, limites, multiplicadores, duração e correção do estado no Client.

Fonte técnica: `docs/features/weapons-combat-and-grenades.md`.
Fonte técnica: `docs/features/ammunition-and-ammo-pickups.md`.
Fonte técnica: `docs/features/powerups-and-temporary-effects.md`.

### 5.2.9 Interface, áudio e feedback visual

Explicar a implementação da HUD e sua atualização a partir do estado da partida. Relacionar sons de movimentação, armas, pickups e granadas, bem como muzzle flash, efeitos de impacto, emissão de power-up e materiais de time, à legibilidade das ações do jogo.

Fonte técnica: `docs/features/hud-menu-and-match-results.md`.
Fonte técnica: `docs/features/audio-and-visual-feedback.md`.

### 5.2.10 Coleta de métricas e dashboard

Explicar quais dados são produzidos pelo Server, como são organizados e com qual intervalo são amostrados. Descrever a gravação em CSV, a transmissão por UDP e suas limitações, além da recepção, do armazenamento temporário e da atualização da interface web. Incluir uma captura da dashboard durante uma partida e destacar os indicadores relevantes.

Fonte técnica: `docs/features/observability-metrics-and-dashboard.md`.

### 5.2.11 Build e execução

Descrever os artefatos finais para Client e Server, execução headless, separação dos presets de exportação e medidas adotadas para tornar a build reproduzível. Detalhes de comandos pertencem aos guias técnicos, não ao corpo principal do relatório.

## 5.3 Verificação e análise dos resultados

### 5.3.1 Resultados funcionais

Apresentar uma tabela relacionando funcionalidades, cenário verificado e resultado observado. Incluir TDM, KOTH, combate, pickups, power-ups, HUD, término de partida e reconexão apenas se ela tiver sido efetivamente testada.

### 5.3.2 Resultados das métricas

Apresentar tabelas ou gráficos obtidos nas execuções definidas no Capítulo 4. Interpretar comportamento de latência, uso do processo, jogadores/lobbies e tráfego sem afirmar conclusões além do que os dados sustentam.

### 5.3.3 Comparação entre proposta e entrega

Resumir em tabela o que foi proposto no TCC1, o que foi entregue e o que mudou. Remeter às justificativas apresentadas na Seção 4.5, evitando repetir toda a discussão e impedindo que itens não implementados sejam confundidos com falhas não discutidas.

### 5.3.4 Limitações

Registrar limitações conhecidas da versão avaliada, como escala reduzida dos testes, quantidade de jogadores, número de mapas, ausência de CTF e aspectos ainda não validados em diferentes condições de rede.

# 6 Conclusão

## 6.1 Síntese do trabalho

Retomar brevemente o problema, a abordagem e o produto obtido, sem repetir todo o capítulo de resultados.

## 6.2 Objetivos alcançados

Responder explicitamente ao objetivo geral e a cada objetivo específico apresentado na introdução, indicando as evidências discutidas no Capítulo 5.

## 6.3 Contribuições e aprendizado

Destacar as contribuições técnicas do trabalho: jogo funcional, arquitetura autoritativa, organização Client/Server, conjunto de features e infraestrutura de observabilidade.

## 6.4 Trabalhos futuros

Apresentar extensões coerentes com as limitações, como novos mapas, aumento da quantidade de jogadores, novos modos, melhoria da sincronização, testes sob diferentes condições de rede e evolução da dashboard.

# Elementos pós-textuais

## Referências

Reunir todas as fontes citadas na fundamentação, jogos similares, ferramentas e métodos. Não incluir uma fonte que não seja mencionada no texto.

## Apêndices e anexos

Usar somente quando acrescentarem material útil, como tabela completa de métricas, configuração dos cenários de teste, esquema de controles ou diagramas grandes. Evitar colocar listagens extensas de código.
