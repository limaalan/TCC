# Documentacao Tecnica Resumida - Coleta de Metricas de Rede

## Objetivo

Este documento resume como a coleta de metricas de rede foi implementada no servidor do projeto, quais tecnologias foram usadas e por que esse conjunto de metricas foi escolhido para apoiar a analise de desempenho em testes multiplayer.

## Escopo Da Implementacao

A coleta foi implementada no projeto Godot do servidor, principalmente nos arquivos `initial_project/Server/server/server.gd` e `initial_project/Server/server/network_metrics_logger.gd`. O mecanismo registra metricas em CSV durante a execucao do servidor e trabalha por amostragem periodica, nao por captura individual de cada pacote trafegado.

## Tecnologias E Bibliotecas Utilizadas

- `Godot 4.5`: motor principal do projeto e ambiente de execucao do servidor.
- `GDScript`: linguagem usada para implementar a logica de amostragem, consolidacao e persistencia das metricas.
- `ENetMultiplayerPeer`: camada de rede usada pelo multiplayer do jogo.
- `ENetConnection`: interface usada para consultar estatisticas acumuladas do host de rede.
- `ENetPacketPeer`: interface usada para consultar estatisticas especificas de cada conexao cliente-servidor.
- `Timer`: mecanismo usado para disparar a coleta em intervalos configuraveis.
- `FileAccess` e `DirAccess`: usados para criar diretorios, abrir arquivos e gravar os CSVs em `user://network_metrics/`.
- `PacketPeerUDP`: usado para emitir um resumo compacto das metricas para consumo externo em tempo real, sem interferir no CSV historico.

## Como A Coleta E Feita

O servidor inicializa um `Timer` com intervalo configuravel e, a cada disparo, executa uma rotina de coleta. Nessa rotina, sao lidos os acumulados de bytes e pacotes enviados e recebidos durante a janela de amostragem; esses valores sao normalizados pelo tempo decorrido para produzir taxas por segundo. Em seguida, o servidor percorre os peers ativos e consulta as metricas instantaneas de latencia, ultima latencia observada, variacao de latencia e perda de pacotes. Ao final de cada ciclo, os dados sao serializados em linhas CSV, uma por peer ativo, formando um historico local de execucao.

## Metricas Coletadas

### Contexto Da Amostra

- `timestamp_ms`: identifica exatamente quando a amostra foi gerada.
- `role`: distingue a origem da amostra.
- `players_count`: informa a quantidade de jogadores conectados no instante da coleta.
- `peer_id`: associa a linha a uma conexao especifica.

Esses campos foram mantidos porque ajudam a contextualizar qualquer analise posterior. Sem esse contexto, os indicadores de rede ficam desconectados do estado real da sessao de teste.

### Latencia E Estabilidade

- `rtt_ms`
- `last_rtt_ms`
- `rtt_variance`
- `app_ping_ms`

Essas metricas foram escolhidas porque latencia e variacao de atraso influenciam diretamente a responsividade percebida em jogos online. Em aplicacoes interativas, nao basta saber a latencia media; tambem e importante observar sua oscilacao ao longo do tempo, ja que variacoes elevadas tendem a gerar sensacao de inconsistencias, atraso de resposta e pior sincronizacao entre cliente e servidor.

### Confiabilidade Da Comunicacao

- `packet_loss_percent`

Essa metrica foi escolhida porque perda de pacotes afeta tanto atualizacoes frequentes de estado quanto eventos criticos de jogo. Mesmo em arquiteturas com transmissao confiavel para parte das mensagens, perda elevada costuma aumentar retransmissoes, instabilidade percebida e degradacao geral da experiencia multiplayer.

### Carga De Rede

- `sent_kbps`
- `received_kbps`
- `sent_packets_per_sec`
- `received_packets_per_sec`

Essas metricas foram escolhidas para representar carga e intensidade do trafego. A taxa em kilobytes por segundo ajuda a enxergar consumo de banda, enquanto a taxa de pacotes por segundo ajuda a avaliar a frequencia de mensagens trocadas, o que pode indicar pressao sobre serializacao, atualizacao de estado e processamento de rede.

### Campo Reservado

- `fps`

Esse campo foi mantido no formato do CSV para permitir extensao futura, mas no logger atual do servidor ele nao e preenchido com um valor util.

## Justificativa Tecnica Para O Conjunto De Metricas

O conjunto escolhido cobre quatro dimensoes importantes do desempenho multiplayer: contexto de teste, qualidade da comunicacao, confiabilidade de entrega e carga de rede. Em vez de observar apenas ping ou apenas consumo de banda, a combinacao dessas medidas permite relacionar variacoes de desempenho a situacoes concretas, como aumento do numero de jogadores, instabilidade de latencia, perda de pacotes ou crescimento do trafego por segundo. Essa abordagem e adequada para testes de jogos em tempo real porque permite interpretar o comportamento da rede de forma mais completa do que metricas isoladas.

## Configurabilidade

A coleta pode ser ativada por argumentos de linha de comando e aceita intervalo configuravel de amostragem. Na implementacao atual, o valor padrao e de `1.0` segundo, mas esse periodo pode ser ajustado para aumentar ou reduzir a granularidade da observacao conforme o objetivo do teste.

## Armazenamento

Os arquivos sao gravados em `user://network_metrics/`, que no ambiente Windows do projeto corresponde ao diretorio de dados do Godot para o aplicativo `Server`. Cada execucao gera um arquivo CSV proprio, com nome baseado em timestamp.

## Limitacoes Atuais

- A coleta e baseada em janelas de amostragem, entao nao registra cada pacote individualmente.
- As taxas de envio e recebimento sao calculadas a partir de acumulados do host no periodo, nao por inspecao detalhada de cada mensagem de gameplay.
- O CSV do servidor registra uma linha por peer ativo, o que favorece analise por conexao, mas nao substitui ferramentas de captura de baixo nivel.
- O campo `fps` ainda nao representa uma medicao efetiva no servidor atual.

## Referencias Tecnicas Sugeridas

- Godot Engine. `ENetConnection` class reference. Disponivel em: [https://docs.godotengine.org/en/stable/classes/class_enetconnection.html](https://docs.godotengine.org/en/stable/classes/class_enetconnection.html)
- Godot Engine. `ENetPacketPeer` class reference. Disponivel em: [https://docs.godotengine.org/en/stable/classes/class_enetpacketpeer.html](https://docs.godotengine.org/en/stable/classes/class_enetpacketpeer.html)
- IETF. RFC 5481 - Packet Delay Variation Applicability Statement. Disponivel em: [https://www.rfc-editor.org/rfc/rfc5481.html](https://www.rfc-editor.org/rfc/rfc5481.html)
