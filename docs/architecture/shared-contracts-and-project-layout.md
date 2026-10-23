# Código compartilhado e organização dos projetos

## Como funciona

`initial_project/shared` é a fonte canônica do código usado por Client e Server. Os caminhos `Client/shared` e `Server/shared` são junctions locais criados por `initial_project/setup_shared_links.ps1`; não são duas cópias para editar separadamente.

O conteúdo compartilhado inclui, entre outros:

- enums e configurações de partida;
- chaves e payloads de rede;
- catálogo e definição de armas;
- inventário de munição;
- tipos de power-up;
- registros de mapas e entidades de rede;
- infraestrutura de métricas.

## Onde fica no projeto

```text
initial_project/
  Client/     apresentação e entrada
  Server/     simulação autoritativa
  shared/     contratos e regras comuns
```

## Regras de alteração

- Edite o arquivo em `initial_project/shared`, nunca a junction dentro de Client ou Server.
- Mantenha comportamento visual exclusivo no Client e simulação exclusiva no Server.
- Mova uma regra para `shared` somente quando ela tiver de ser interpretada pelos dois projetos; não use `shared` como depósito de assets visuais.
- Antes de abrir os dois projetos em uma máquina nova, execute `initial_project/setup_shared_links.ps1`.

## Layout de assets

O Client é dono de modelos, materiais, texturas, áudio e cenas visuais; o Server deve manter apenas o conteúdo necessário para a simulação, como colisão, spawns, pickups e objetivos. Não duplique arte visual no Server apenas para resolver uma referência.

Os assets existentes usam a pasta `import/` para reunir arquivos relacionados à importação e autoria. Preserve esse padrão ao alterar um asset: mantenha a cena e os caminhos que a Godot já consome, evite criar cópias de texturas ou materiais sem necessidade e pesquise referências antes de apagar um recurso.

## Como testar

Depois de alterar um contrato ou tipo compartilhado, abra ambos os projetos Godot e rode uma partida local. Erros de parse ou de RPC tendem a aparecer logo no carregamento do lobby.
