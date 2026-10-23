# Imagens e diagramas a produzir para o TCC2

Checklist elaborado a partir do texto LaTeX atual, das notas de “Evidência pendente” e do apêndice de revisão. O objetivo é acrescentar seis figuras, com uma sétima opcional. Várias capturas podem formar painéis de uma única figura; não é necessário dedicar uma figura a cada funcionalidade.

Coloque os arquivos em `docs/report/figuras/tcc2/`. Os números da primeira coluna indicam a ordem sugerida de produção, não a numeração final das figuras no PDF, que será automática.

## Fila de produção

| Ordem | Imagem ou diagrama | O que produzir | Local principal de inclusão | Arquivos sugeridos |
| --- | --- | --- | --- | --- |
| 1 | Acesso ao jogo e resultado da partida | Duas capturas: menu principal com nome e seleção de partida visíveis; tela final com equipes, pontuação e resultados individuais. Montar uma figura com dois painéis, preservando a legibilidade. Complementa o fluxograma de telas que já existe. | 5.1.3 — Fluxo de telas. Referenciar também em 5.2.9, sem repetir a figura. | `menu-principal.png` e `resultado-partida.png` |
| 2 | HUD em TDM e KOTH | Duas capturas durante partidas: uma em cada modo. Mostrar vida, time, arma, munição, granadas, placar e tempo; em pelo menos uma delas, um buff ativo com temporizador. Na de KOTH, mostrar a zona e seu indicador. Quando possível, enquadrar outro personagem para mostrar a identificação da equipe. Reunir em uma figura com dois painéis e poucas chamadas numeradas. | 5.1.6 — Interface e feedback ao jogador. Referenciar em 5.2.5, 5.2.6, 5.2.8 e 5.2.9 conforme o assunto. | `hud-tdm.png` e `hud-koth.png` |
| 3 | Visão geral anotada de Highrise | Uma vista elevada ou oblíqua que permita entender a arena e a verticalidade. Identificar nascimentos azul/vermelho, zona KOTH, jump pads e principais recursos, usando números e uma legenda curta. A figura deve mostrar a versão final do mapa. | 5.2.7 — Mapa Highrise e level design, junto da nota de evidência pendente. | `highrise-visao-geral.png` |
| 4 | Sequência de processamento do disparo | Um diagrama compacto de sequência Client → Server → Clients: entrada e feedback local; pedido com instante do disparo; verificação do jogador, arma e munição; consulta histórica/raycast; aplicação de dano e envio das atualizações. Remeter à figura de compensação de latência existente para os detalhes do histórico. Explicitar que o Server não valida atualmente a cadência mínima, conforme o texto. | 5.2.2 — Comunicação e autoridade do servidor. Referenciar em 5.2.8. | `fluxo-disparo.pdf` ou `fluxo-disparo.tex` |
| 5 | Dashboard durante uma partida | Uma captura limpa e legível, com jogadores/lobbies e os indicadores relevantes da execução visíveis. Registrar fora da imagem a versão/build, o modo, a data e a rodada a que corresponde. Mostrar CPU/memória somente quando o monitor tiver acesso ao processo correto. | 5.2.10 — Coleta de métricas e dashboard, junto da nota de evidência pendente. | `dashboard-metricas.png` |
| 6 | Resultados do experimento de métricas | Depois de coletar os dados, produzir uma figura com até três painéis: RTT ENet em ms, tráfego em KiB/s e tempo do trecho instrumentado dos lobbies na unidade registrada. Comparar espera, TDM e KOTH conforme o protocolo, com eixos, unidades e identificação das rodadas. Distinguir envio/recepção e soma/máximo quando esses campos forem utilizados. | 5.3.2 — Resultados das métricas. O método permanece descrito em 4.8. | `resultados-metricas.pdf` ou `resultados-metricas.png` |
| 7 — opcional | Estados da zona de KOTH | Três recortes da zona/indicador: vazia, controlada e contestada, sob condições comparáveis. Usar uma única figura com três painéis. Produzir apenas se a captura geral de KOTH do item 2 não deixar esses estados claros. | 5.2.6 — Modos de jogo e fluxo da partida, após a explicação de KOTH. | `koth-vazia.png`, `koth-controlada.png` e `koth-contestada.png` |

## Controle de produção

- [ ] 1. Menu e resultado.
- [ ] 2. HUD de TDM e KOTH, incluindo buff ativo.
- [ ] 3. Visão geral de Highrise.
- [ ] 4. Diagrama do processamento do disparo.
- [ ] 5. Dashboard durante uma rodada identificada.
- [ ] 6. Gráficos obtidos dos dados reais.
- [ ] 7. Estados da zona KOTH, somente se necessário.

Os itens 1, 2, 3, 5 e 6 atendem às notas explícitas de evidência pendente. O item 4 é uma sugestão adicional para explicar a divisão de responsabilidades no combate. O item 7 pode ser dispensado para manter o relatório enxuto.

## Figuras que já estão incluídas

| Figura atual | Conteúdo | Arquivo em `figuras/tcc2/` |
| --- | --- | --- |
| 1 | Fluxo de telas e participação | `fluxo-telas.tex` |
| 2 | Responsabilidades de Client, Server e shared | `arquitetura.tex` |
| 3 | Interpolação de snapshots | `interpolacao-snapshots.png` |
| 4 | Compensação de latência dos disparos | `compensacao-latencia-disparos.png` |
| 5 | Coleta, registro e apresentação de métricas | `fluxo-metricas.tex` |

Com os seis itens principais, o relatório passa de cinco para aproximadamente onze figuras. Os painéis de uma composição contam como partes de uma figura, mas precisam manter texto e detalhes legíveis no tamanho de impressão. Não é necessário criar outro diagrama geral de arquitetura ou de sincronização.

## Orientações de captura

Use a mesma build para as imagens do jogo e registre seu commit/versão. Guarde as capturas originais, de preferência em PNG, sem cursor ou sobreposições externas. Para diagramas e gráficos, PDF vetorial é adequado; evite EPS no editor integrado. Não reduza a imagem a ponto de tornar a HUD ilegível: painéis podem ser empilhados em vez de colocados lado a lado.

Não é necessário montar as composições antecipadamente: os arquivos separados podem ser organizados como painéis no LaTeX. Setas, números e legendas devem destacar somente elementos mencionados no texto.

Os gráficos do item 6 dependem de dados preservados. Uma captura da dashboard demonstra a apresentação da ferramenta; as conclusões de desempenho dependem das rodadas documentadas. Períodos sem peers não devem receber RTT artificialmente igual a zero. CPU e memória, se usados, precisam de registro adicional, pois a dashboard não os acrescenta ao CSV do Godot.

## Pendências que não exigem novas imagens

O registro do teste integrado, a identificação da build, a reprodução em checkout limpo e a consolidação bibliográfica devem ser documentados em texto, tabelas ou arquivos de apoio. Não precisam virar capturas de terminal ou figuras adicionais. Para a avaliação funcional, completar a tabela já existente em 5.3.1 é mais útil do que acrescentar um print para cada cenário.

A tabela de armas já cobre seus parâmetros; o mapa e as capturas da HUD podem apresentar visualmente os recursos. Neste momento, não é necessário produzir galerias separadas de armas, granadas, pickups, expressões faciais ou telas de pausa.
