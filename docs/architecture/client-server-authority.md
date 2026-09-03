# Client, Server e autoridade

## Como funciona

O Client envia intenção do jogador; o Server mantém o estado aceito da partida e replica suas consequências. Isso evita que um Client decida sozinho dano, munição disponível, coleta de item ou pontuação.

```text
entrada local -> RPC/estado enviado -> Server valida e simula
                                             |
                                             v
                                  RPC/estado replicado ao Client
                                             |
                                             v
                                    HUD e mundo são atualizados
```

## Onde fica no projeto

- `Server/server/server.gd`: cria e associa jogadores a lobbies.
- `Server/server/lobby.gd`: ponto central de carregamento de partida, sincronização e RPCs.
- `Client/server/lobby.gd`: recebe eventos e constrói a apresentação local.
- `shared/net/net_keys.gd` e `shared/net/net_payloads.gd`: chaves e payloads compartilhados.
- `shared/network_entity.gd`: identificadores estáveis para entidades dinâmicas, como granadas.

## Regras importantes

- Dano, morte, munição, granadas, power-ups, placar e fim de partida são confirmados no Server.
- A HUD pode reagir imediatamente a uma ação local, mas deve aceitar a correção posterior enviada pelo Server.
- Mensagens novas devem reutilizar `NetKeys` e, quando aplicável, um construtor em `NetPayloads`; não introduza strings avulsas nos dois projetos.
- Uma alteração de contrato exige atualização coordenada no emissor, receptor e documentação da feature afetada.

## Como testar

Execute Server e Client, entre com dois jogadores e confirme que ambos observam o mesmo placar, pickups removidos, explosões e encerramento. Para um procedimento completo, veja [executar partida local](../how_to/run-local-match.md).
