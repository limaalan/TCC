# Guia De Importação De Assets E Construção De Mapas

## Objetivo

Este guia descreve o fluxo recomendado para levar um asset pronto no Blender para a Godot e construir mapas no mesmo padrão do `map_farm` atual.

O projeto usa dois mapas equivalentes:

| Projeto | Cena | Papel |
| --- | --- | --- |
| Client | `initial_project/Client/maps/map_farm.tscn` | Visual, iluminação, áudio, UI, colisão local e feedback visual |
| Server | `initial_project/Server/maps/server_map_farm.tscn` | Colisão autoritativa, spawns, pickups, raycast de tiro e regras de gameplay |

Na prática: o Client pode ter meshes bonitas. O Server deve ter só o necessário para simulação.

## Formato Recomendado

Use `.glb` como formato padrão.

| Formato | Quando usar |
| --- | --- |
| `.glb` | Melhor padrão para este projeto: mesh, materiais e dados em um arquivo só |
| `.gltf` | Útil se quiser manter texturas externas separadas |
| `.blend` | Bom como arquivo fonte, mas não como asset final principal do jogo |
| `.obj`/`.fbx` | Evitar se não houver necessidade específica |

Fluxo recomendado:

```text
Blender source: assets_source/container.blend
Godot import: initial_project/Client/assets/meshes/props/container.glb
Godot scene: initial_project/Client/assets/props/container.tscn
```

## Preparar O Asset No Blender

Antes de exportar:

1. Deixe o asset em escala real, em metros.
2. Posicione o objeto de forma lógica: base no chão, frente apontando para uma direção consistente.
3. Aplique transforms com `Ctrl+A > All Transforms`.
4. Ajuste a origem/pivô no centro ou na base do asset.
5. Use poucos materiais, com nomes claros: `body_teal`, `trim_cream`, `team_blue`, `team_red`.
6. Remova geometria interna que nunca será vista.
7. Confirme que as normals estão corretas.
8. Exporte como `.glb`.

Configurações gerais de export no Blender:

| Opção | Recomendação |
| --- | --- |
| Format | `glTF Binary (.glb)` |
| Include | Selected Objects, se exportar asset isolado |
| Transform | Apply Modifiers ligado |
| Materials | Exportar materiais simples |
| Animation | Desligado para props estáticos |
| Compression | Opcional; usar só se não causar artefatos |

## Importar Na Godot

1. Copie o `.glb` para uma pasta do Client, por exemplo:

```text
initial_project/Client/assets/meshes/props/container.glb
```

2. Abra o projeto Client na Godot.
3. A Godot importa o arquivo automaticamente.
4. Clique no `.glb` no FileSystem para revisar materiais, escala e nós importados.
5. Arraste o asset para uma cena de teste ou para o mapa.
6. Se o asset será reutilizado, crie uma cena wrapper `.tscn`.

## Quando Criar Uma Cena Para Cada Asset

Crie uma cena `.tscn` para cada asset reutilizável.

Exemplos:

```text
assets/props/container.tscn
assets/props/crate.tscn
assets/props/jump_pad.tscn
assets/items/health_pickup_visual.tscn
assets/weapons/pistol_visual.tscn
```

Estrutura simples:

```text
Container
  MeshInstance3D ou instância do container.glb
```

Crie cena própria quando o asset:

- aparece várias vezes no mapa;
- precisa de material override;
- pode receber script depois;
- pode ter animação;
- pode virar pickup, plataforma, objetivo ou arma;
- precisa de colisão própria para preview/teste.

Para decoração única e simples, pode instanciar o `.glb` direto no mapa. Para produção, prefira `.tscn`.

## Estrutura Do Mapa Client

O mapa Client deve seguir este padrão:

```text
Map
  WorldSettings
    DirectionalLight3D
    WorldEnvironment
  SpawnPoints
    BluePlayerSpawnPoint
    BluePlayerSpawnPoint2
    RedPlayerSpawnPoint
    RedPlayerSpawnPoint2
  Meshes
    Ground
    Buildings
    Props
    Nature
    Boundaries
  PlayerBoundaries
  ExactCollisions
```

Uso de cada grupo:

| Node | Uso |
| --- | --- |
| `WorldSettings` | Luz, céu, fog, ambiente e pós-processamento |
| `SpawnPoints` | Pontos de spawn visíveis no editor |
| `Meshes` | Tudo que é visual no cliente |
| `PlayerBoundaries` | Colisão simples para movimento do jogador |
| `ExactCollisions` | Colisão mais fiel usada para raycasts de tiro/impacto |

## Estrutura Do Mapa Server

O mapa Server deve ser mais leve:

```text
Map
  SpawnPoints
    BluePlayerSpawnPoint
    BluePlayerSpawnPoint2
    RedPlayerSpawnPoint
    RedPlayerSpawnPoint2
  PlayerBoundaries
  ExactCollisions
  Pickups
    HealthPickup
    GrenadePickup
```

O Server não precisa de:

- meshes decorativos;
- grama;
- árvores só visuais;
- luz;
- câmera;
- world environment;
- UI.

Ele precisa de colisões e posições equivalentes ao Client.

## Spawns

Hoje o código depende dos nomes dos spawns.

Use este padrão:

```text
SpawnPoints
  BluePlayerSpawnPoint
  BluePlayerSpawnPoint2
  BluePlayerSpawnPoint3
  RedPlayerSpawnPoint
  RedPlayerSpawnPoint2
  RedPlayerSpawnPoint3
```

No Client, use o script `res://player/spawn_point/player_spawn_point.gd` para mostrar a seta no editor.

No Server, basta `Node3D` com o mesmo transform.

## Pickups

No Server, pickups ficam em:

```text
Pickups
  HealthPickup
  GrenadePickup
```

Cada pickup é uma instância de:

```text
res://player/pickups/pickup.tscn
```

O Server envia nome, tipo e posição para o Client. Por isso, mantenha nomes estáveis e únicos.

## PlayerBoundaries

`PlayerBoundaries` é a colisão simplificada de movimentação.

Use para responder perguntas como:

- Onde o jogador pode andar?
- Onde ele bate?
- Onde ele não pode passar?
- Qual cobertura bloqueia fisicamente o player?

Crie `StaticBody3D` com `CollisionShape3D` simples.

Exemplos:

| Asset visual | Colisão recomendada em `PlayerBoundaries` |
| --- | --- |
| Container | 1 ou 2 `BoxShape3D` |
| Crate | 1 `BoxShape3D` |
| Parede | 1 `BoxShape3D` |
| Silo | 1 `CapsuleShape3D` ou cilindro simples |
| Tanque cilíndrico | 1 `CapsuleShape3D` rotacionado |
| Prédio | Várias caixas grandes, não a mesh inteira |
| Chão | 1 `BoxShape3D` grande ou plano com espessura |
| Props pequenos | Muitas vezes sem colisão de player |

Configuração atual típica:

```text
StaticBody3D
  collision_layer = layer 1
  collision_mask = 0
  CollisionShape3D
```

No Client, layer 1 se chama `player_boundaries`. No Server, layer 1 se chama `enviroment`.

## ExactCollisions

`ExactCollisions` não é a colisão de movimento do jogador. Ela existe para raycasts e impactos serem mais fiéis ao visual.

No projeto atual, o Server usa esta layer no cálculo do tiro:

```gdscript
const PHYSICS_LAYER_EXACT = 16
ray_params.collision_mask = PHYSICS_LAYER_EXACT + PHYSICS_LAYER_HITBOX
```

Ou seja:

- layer `16` é a layer 5;
- no Server ela está nomeada como `enviroment_exact`;
- tiros testam contra hitboxes de jogadores e contra `ExactCollisions` do cenário.

### Preciso Fazer Outro Modelo Simplificado No Blender?

Depende do asset.

Para `PlayerBoundaries`: sim, você deve criar colisão simplificada, mas pode fazer isso direto na Godot com `BoxShape3D`, `CapsuleShape3D` e `ConvexShape`. Não precisa necessariamente modelar outra mesh no Blender.

Para `ExactCollisions`: você tem três opções.

| Opção | Quando usar | Recomendação |
| --- | --- | --- |
| Usar a mesh visual como trimesh/concave | Asset low-poly simples, sem geometria interna | Bom para props simples e mapas low-poly |
| Criar uma mesh de colisão dedicada no Blender | Asset visual tem muitos detalhes, buracos, partes internas ou shape ruim | Melhor para assets grandes/importantes |
| Usar shapes simples também no `ExactCollisions` | Asset é caixa, parede, chão, container ou prop modular | Melhor para performance e manutenção |

Então: você não precisa sempre criar outro modelo no Blender. Mas para assets gerados por IA ou muito detalhados, é melhor criar uma versão de colisão limpa.

### Diferença Prática

Exemplo: container.

```text
Visual:
  Container mesh com bevels e detalhes

PlayerBoundaries:
  1 BoxShape3D grande

ExactCollisions:
  Pode ser a própria mesh visual ou uma caixa, dependendo do nível de precisão desejado
```

Exemplo: prédio com porta e janelas.

```text
Visual:
  Mesh detalhada do prédio

PlayerBoundaries:
  Caixas grandes para paredes principais

ExactCollisions:
  Mesh simplificada feita no Blender, mantendo aberturas importantes
```

Exemplo: árvore decorativa.

```text
Visual:
  Árvore low-poly

PlayerBoundaries:
  Talvez nenhuma colisão ou apenas capsule no tronco

ExactCollisions:
  Só o tronco, se tiros devem bater nele; folhas podem ser ignoradas
```

## Como Criar ExactCollisions Na Godot

Fluxo simples usando a mesh visual:

1. Instancie o asset visual no mapa Client.
2. Selecione o `MeshInstance3D`.
3. Use a opção da Godot para criar colisão trimesh/concave a partir da mesh.
4. Mova o `StaticBody3D` criado para o grupo `ExactCollisions`.
5. Configure `collision_layer = 16`.
6. Configure `collision_mask = 0`.
7. Renomeie o node com nome legível, por exemplo `ExactContainerNorth`.
8. Repita ou duplique para o Server map.

Use esse fluxo apenas quando a mesh visual for limpa e leve.

## Como Criar ExactCollisions No Blender

Fluxo recomendado para asset complexo:

1. Duplique o asset visual no Blender.
2. Renomeie para algo como `container_collision_exact`.
3. Remova detalhes pequenos: parafusos, bevels finos, fios, detalhes internos.
4. Preserve apenas a silhueta que deve receber tiro.
5. Mantenha aberturas importantes, como portas e janelas.
6. Exporte essa mesh junto ou separada como `.glb`.
7. Na Godot, importe e use essa mesh para gerar `ConcavePolygonShape3D` ou `ConvexPolygonShape3D`.
8. Coloque o resultado em `ExactCollisions` com layer `16`.
9. Oculte/remova o mesh visual de colisão se ele foi importado só para gerar shape.

Nomes sugeridos no Blender:

```text
container_visual
container_collision_player
container_collision_exact
```

Você pode exportar só o visual e criar colisão na Godot, ou exportar visual + collision helpers. Para assets complexos, exportar collision helpers costuma ser mais controlável.

## Como Criar PlayerBoundaries No Blender

Para blocos grandes, pode ser útil criar colisões como cubos no Blender.

Exemplo:

```text
building_visual
col_player_wall_north
col_player_wall_south
col_player_roof
col_exact_facade
```

Mas não é obrigatório. Para o mapa atual, muitas colisões simples podem ser feitas direto no editor Godot.

Use Blender para colisão quando:

- há muitas peças alinhadas;
- a forma é inclinada;
- precisa casar exatamente com uma rampa;
- você quer duplicar o mesmo kit modular em vários mapas.

Use Godot para colisão quando:

- é uma caixa simples;
- é um capsule/cilindro simples;
- você está blocando o mapa;
- quer iterar rápido.

## Sincronizar Client Map E Server Map

Como existem dois projetos, os mapas precisam ficar equivalentes.

Processo seguro:

1. Monte o mapa visual no Client.
2. Crie `PlayerBoundaries`, `ExactCollisions`, `SpawnPoints` e pickups no Client.
3. Teste andar no Client.
4. Copie a estrutura gameplay para o Server map.
5. No Server map, remova visual pesado.
6. Confirme que transforms de spawns, pickups e colisões são iguais.
7. Rode server + dois clients.
8. Teste movimento, tiro contra cenário, granada, pickup e respawn.

O que precisa bater entre Client e Server:

| Elemento | Precisa ser igual? | Motivo |
| --- | --- | --- |
| `SpawnPoints` | Sim | Server escolhe spawn autoritativo |
| `Pickups` | Sim | Server envia pickups por nome/tipo/posição |
| `PlayerBoundaries` | Sim ou muito próximo | Client e Server devem concordar sobre movimento/obstáculos |
| `ExactCollisions` | Sim no Server; visualmente equivalente no Client | Server calcula tiro autoritativo |
| `Meshes` visuais | Não | Só o Client precisa renderizar |
| Luz/ambiente | Não | Só o Client precisa renderizar |

## Checklist Para Novo Asset

| Passo | Feito |
| --- | --- |
| Asset exportado do Blender como `.glb` |  |
| Arquivo colocado em `Client/assets/meshes/...` |  |
| Import abriu sem erro na Godot |  |
| Escala parece correta no mapa |  |
| Cena wrapper `.tscn` criada se asset for reutilizável |  |
| Visual colocado em `Meshes/...` |  |
| Colisão simples criada em `PlayerBoundaries` se bloqueia jogador |  |
| Colisão de tiro criada em `ExactCollisions` se deve receber tiro |  |
| `ExactCollisions` configurado na layer `16` |  |
| Server map recebeu colisões/spawns/pickups equivalentes |  |
| Testado com server + dois clients |  |

## Recomendação Prática

Para o seu estilo low-poly:

1. Faça visual low-poly no Blender.
2. Faça `PlayerBoundaries` quase sempre com shapes simples na Godot.
3. Use a mesh visual como `ExactCollisions` só se ela for limpa e leve.
4. Para assets gerados por IA, crie uma collision mesh simplificada no Blender antes de usar como `ExactCollisions`.
5. Nunca use automaticamente uma mesh gerada por IA como colisão sem revisar.

Resumo: outro modelo simplificado não é obrigatório para tudo, mas é recomendado para assets complexos, gerados por IA ou importantes para combate. Para assets modulares simples, shapes da Godot resolvem melhor e mais rápido.
