# Estrutura sugerida para o relatório de TCC2

## Orientações gerais

- Use este arquivo como roteiro de escrita, não como sumário definitivo. A numeração e a profundidade das subseções podem ser ajustadas conforme o volume de conteúdo e as orientações do professor.
- Descreva o produto que foi realmente entregue. O TCC1 registra a proposta inicial e deve ser usado para explicar a evolução do projeto, não como fonte do estado atual.
- Escreva a implementação e os resultados predominantemente no passado. Reserve o futuro para limitações e trabalhos futuros.
- Organize o capítulo principal por funcionalidades do jogo. Para cada feature, explique sua finalidade, seu comportamento e a solução técnica adotada. Não é necessário repetir uma estrutura rígida quando algum desses pontos não for relevante.
- Separe fundamentação de implementação: conceitos externos e afirmações gerais precisam de referências; decisões e comportamentos do próprio projeto devem ser demonstrados com diagramas, capturas de tela, tabelas e pequenos trechos de código quando ajudarem a explicação.
- Evite transformar o relatório em uma listagem de arquivos ou classes. Os caminhos registrados em `docs/features/` servem para localizar a implementação, enquanto o relatório deve explicar as responsabilidades e relações entre os sistemas.
- Apresente uma figura ou evidência relevante para as principais features: fluxo de telas, arquitetura Client/Server, mapa, HUD, modos de jogo, combate e dashboard de métricas.
- Explique em um único ponto as diferenças entre a proposta e o resultado. As principais mudanças identificadas são:
  - substituição da arquitetura peer-to-peer por Client/Server com servidor dedicado e autoritativo;
  - implementação de Team Deathmatch e King of the Hill, sem Capture the Flag;
  - uso de presets de partida em vez de configuração livre feita por um jogador hospedeiro;
  - conjunto final de armas composto por pistola, SMG e shotgun, além de granadas;
  - power-ups de dano e cadência de tiro, em vez do aumento de velocidade de movimentação proposto inicialmente;
  - adoção de Highrise como mapa principal, mantendo Prototype somente como mapa de desenvolvimento;
  - inclusão de coleta de métricas e dashboard como parte do produto técnico.
- Na parte de métricas, separe três assuntos: o método de avaliação definido no Capítulo 4, a implementação da coleta/dashboard no Capítulo 5 e os dados observados nos resultados.
- Mantenha nomes consistentes ao longo do texto: Client para o projeto do jogador, Server para o servidor autoritativo e `shared` para os contratos e regras compartilhados.

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

## 2.5 Arquiteturas de comunicação para jogos

Comparar brevemente peer-to-peer e Client/Server e fundamentar a escolha de um servidor dedicado e autoritativo. Explicar autoridade, replicação de estado e o risco de confiar decisões de gameplay ao Client.

## 2.6 Tecnologias de rede utilizadas

Apresentar UDP, ENet e chamadas RPC no nível necessário para compreender a implementação na Godot. Incluir conceitos como latência, perda de pacotes e sincronização apenas quando forem usados na discussão do projeto.

## 2.7 Observabilidade em jogos em rede

Definir a finalidade de coletar métricas de processo, partida e rede. Contextualizar CSV, transmissão de telemetria por UDP e dashboards como instrumentos de acompanhamento e avaliação.

## 2.8 Level design para arenas competitivas

Apresentar os conceitos aproveitados no mapa, como verticalidade, rotas alternativas, pontos de conflito, cobertura, simetria e distribuição de recursos.

# 3 Jogos similares e referências

## 3.1 Critérios de comparação

Explicar por que os jogos foram escolhidos e quais aspectos serão comparados: combate em arena, verticalidade, modos em equipe, estilo visual e organização do mapa.

## 3.2 Referências clássicas de FPS e arena shooter

Retomar de forma condensada as referências do TCC1, como Doom, Quake e Unreal Tournament, concentrando a análise nas características que influenciaram o projeto.

## 3.3 Referências visuais e de jogabilidade

Apresentar jogos que contribuíram para o estilo cartunesco, legibilidade visual ou mistura entre tiro e plataforma, como Lovely Planet, quando a influência puder ser demonstrada no resultado.

## 3.4 Comparação com o jogo desenvolvido

Usar uma tabela para relacionar as referências com as decisões adotadas em movimentação, armas, modos, mapa e direção visual. Evitar apenas descrever cada produto isoladamente.

# 4 Materiais e métodos

## 4.1 Ferramentas e tecnologias

Apresentar Godot 4.5, GDScript, Blender, Git, PowerShell e Python/FastAPI no contexto em que foram usados. Incluir hardware ou ambiente de execução somente se for relevante para reproduzir testes e métricas.

## 4.2 Processo de desenvolvimento

Descrever honestamente o processo empregado durante o TCC2. Relacionar planejamento, implementação incremental, testes, revisão e refinamento das features. Caso o Double Diamond do TCC1 não tenha sido seguido integralmente, explicar sua adaptação em vez de afirmar uma aplicação literal.

## 4.3 Evolução da proposta do TCC1

Comparar a proposta com as decisões finais: mudança para servidor dedicado, substituição de CTF por KOTH, definição dos presets, revisão das armas e power-ups e amadurecimento do mapa. Apresentar as mudanças como resultado do processo de desenvolvimento e da redução de riscos técnicos.

## 4.4 Organização do projeto

Explicar a existência de dois projetos Godot, Client e Server, e o diretório `shared`. Mostrar como essa separação permitiu executar uma build visual para jogadores e uma build headless para o servidor.

## 4.5 Método de verificação funcional

Definir os cenários usados para verificar o jogo: conexão de Clients, início de partida, modos TDM/KOTH, movimentação, combate, pickups, power-ups, HUD, término e retorno ao menu.

## 4.6 Método de coleta e análise de métricas

Registrar o ambiente, número de jogadores, duração das execuções, intervalo de amostragem e métricas observadas. Explicar como CSV e dashboard serão usados para produzir tabelas ou gráficos comparáveis.

# 5 Desenvolvimento e resultados

Este deve ser o principal capítulo do relatório. A organização segue as features do jogo e pode combinar explicação funcional, solução técnica e evidência visual.

## 5.1 Visão geral do jogo final

### 5.1.1 Conceito e ciclo principal de jogabilidade

Descrever a versão final do jogo: entrar em uma partida, movimentar-se pela arena, obter armas e recursos, enfrentar o time adversário e pontuar conforme o modo selecionado.

### 5.1.2 Controles e movimentação

Apresentar movimentação em primeira pessoa, câmera, corrida, salto duplo e lançamento por jump pads. Incluir o mapeamento final de teclado, mouse e controle, se ambos estiverem suportados na entrega.

### 5.1.3 Fluxo de telas

Mostrar o encadeamento entre menu principal, seleção de partida, jogo, pausa e resultado final. Uma figura de fluxo é mais adequada do que descrever cada botão em detalhes.

## 5.2 Arquitetura do sistema

### 5.2.1 Separação entre Client, Server e shared

Explicar as responsabilidades de apresentação, entrada, simulação autoritativa e contratos compartilhados. Usar um diagrama com os três componentes.

### 5.2.2 Comunicação e autoridade do servidor

Mostrar o fluxo de uma ação representativa, como disparo ou coleta de item: solicitação do Client, validação no Server e replicação do resultado. Relacionar a decisão com consistência e prevenção de trapaças.

### 5.2.3 Sessões, lobbies e presets

Descrever conexão, associação de jogadores, criação de lobbies e seleção dos presets TDM/KOTH em Highrise. Indicar os limites de jogadores e lobbies usados na versão entregue.

## 5.3 Jogador, times e ciclo de vida

Explicar instanciação local e remota, atribuição de times, spawn, vida, morte e respawn. Mostrar como cores, anéis e indicador da HUD ajudam o jogador a identificar sua equipe.

Fonte técnica: `docs/features/player-and-network-session.md`.

## 5.4 Modos de jogo e fluxo da partida

### 5.4.1 Team Deathmatch

Descrever a obtenção de pontos por eliminações, atualização do placar e condições de encerramento.

### 5.4.2 King of the Hill

Explicar a zona de controle, os estados livre/controlada/contestada, a pontuação por domínio e a representação visual do objetivo.

### 5.4.3 Encerramento e resultado

Apresentar limite de tempo, pontuação alvo, determinação do vencedor e dados enviados para a tela final.

Fonte técnica: `docs/features/match-flow-and-game-modes.md`.

## 5.5 Mapa Highrise e level design

Descrever a organização espacial de Highrise, verticalidade, rotas, coberturas, posições de vantagem, distribuição de pickups, spawns, jump pads e localização da zona de KOTH. Relacionar decisões do mapa aos conceitos do Capítulo 2.

Também explicar a existência das representações visual e autoritativa do mapa, sem transformar a seção em um tutorial de importação.

Fonte técnica: `docs/features/highrise-map-and-traversal.md`.

## 5.6 Armas, combate e granadas

### 5.6.1 Armas disponíveis

Apresentar pistola, SMG e shotgun, comparando papel, dano, cadência, alcance e consumo de munição. Usar uma tabela com os valores finais quando eles estiverem estabilizados.

### 5.6.2 Processamento do disparo e dano

Explicar entrada local, feedback imediato, validação do Server, aplicação de dano, morte e comunicação aos jogadores.

### 5.6.3 Granadas

Descrever coleta ou disponibilidade, lançamento, identificação em rede, trajetória, explosão e remoção da entidade.

Fonte técnica: `docs/features/weapons-combat-and-grenades.md`.

## 5.7 Munição e pickups

Explicar inventário por arma, munição inicial, consumo por disparo, limite máximo, coleta no mapa, atualização imediata da HUD e correção pelo estado autoritativo do Server.

Fonte técnica: `docs/features/ammunition-and-ammo-pickups.md`.

## 5.8 Power-ups temporários

Apresentar os buffs de dano e cadência de tiro, incluindo coleta, multiplicadores, duração controlada pelo Server, término do efeito e indicador visual com temporizador no Client.

Fonte técnica: `docs/features/powerups-and-temporary-effects.md`.

## 5.9 Interface do jogador

Descrever as informações exibidas durante a partida: vida, time, arma, munição, granadas, buffs, placar e objetivo do modo. Mostrar como a HUD procura fornecer informação sem ocultar a visão da arena.

Fonte técnica: `docs/features/hud-menu-and-match-results.md`.

## 5.10 Áudio e feedback visual

Apresentar sons de movimentação, armas, pickups e granadas, além de muzzle flash, efeitos de impacto, emissão de power-up e materiais de time. Relacionar esses recursos à legibilidade das ações do jogo.

Fonte técnica: `docs/features/audio-and-visual-feedback.md`.

## 5.11 Coleta de métricas e dashboard

### 5.11.1 Coleta e contrato das métricas

Explicar quais dados são produzidos pelo Server, como são organizados no contrato e com qual intervalo são amostrados.

### 5.11.2 Registro e transmissão

Descrever os modos de gravação em CSV e transmissão por UDP, suas finalidades e as limitações de um transporte que não garante entrega.

### 5.11.3 Dashboard

Explicar recepção, armazenamento temporário e atualização da interface web. Incluir uma captura da dashboard durante uma partida e destacar os indicadores relevantes.

Fonte técnica: `docs/features/observability-metrics-and-dashboard.md`.

## 5.12 Build e execução

Descrever os artefatos finais para Client e Server, execução headless, separação dos presets de exportação e medidas adotadas para tornar a build reproduzível. Detalhes de comandos pertencem aos guias técnicos, não ao corpo principal do relatório.

## 5.13 Verificação e análise dos resultados

### 5.13.1 Resultados funcionais

Apresentar uma tabela relacionando funcionalidades, cenário verificado e resultado observado. Incluir TDM, KOTH, combate, pickups, power-ups, HUD, término de partida e reconexão apenas se ela tiver sido efetivamente testada.

### 5.13.2 Resultados das métricas

Apresentar tabelas ou gráficos obtidos nas execuções definidas no Capítulo 4. Interpretar comportamento de latência, uso do processo, jogadores/lobbies e tráfego sem afirmar conclusões além do que os dados sustentam.

### 5.13.3 Comparação entre proposta e entrega

Resumir em tabela o que foi proposto no TCC1, o que foi entregue, o que mudou e o motivo. Esta subseção deve evitar que itens não implementados sejam confundidos com falhas não discutidas.

### 5.13.4 Limitações

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
