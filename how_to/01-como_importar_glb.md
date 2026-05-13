# 01 - Como importar GLB

Resumo prático do fluxo discutido para levar um asset do Blender ate o Godot e montar um prefab modular compativel com o projeto.

## Objetivo

Cada asset de cenario pode ser responsavel pelas proprias colisoes.
Nao e necessario manter manualmente grandes arvores globais como `PlayerBoundaries` e `ExactCollisions` no mapa inteiro, desde que cada prefab tenha:

- uma colisao simples para movimento
- uma colisao exact para raycast de tiro

No projeto atual, o tiro do server usa raycast contra a layer exact em:

`initial_project/Server/server/lobby.gd`

```gdscript
ray_params.collision_mask = PHYSICS_LAYER_EXACT + PHYSICS_LAYER_HITBOX
```

Entao o importante nao e o nome do no, e sim a layer e a shape fisica correta.

## Fluxo Blender -> GLB -> Godot

1. Modele o asset no Blender.
2. Exporte em `.glb`.
3. Coloque o `.glb` dentro da pasta de assets do projeto Godot.
4. Deixe o Godot importar o arquivo automaticamente.
5. Crie uma cena `.tscn` propria para o asset, em vez de usar so o `.glb` direto no mapa.

Exemplo:

- `tabua_andaime.glb` = mesh importada
- `tabua_andaime.tscn` = prefab final usado no mapa

## Estrutura recomendada do prefab

Para cada asset modular, use uma estrutura como esta:

```text
TabuaAndaime
- VisualRoot / mesh importada
- PlayerCollision (StaticBody3D)
  - CollisionShape3D (BoxShape3D ou ConvexPolygonShape3D)
- ExactCollision (StaticBody3D)
  - CollisionShape3D (ConcavePolygonShape3D ou shape exata)
```

Configuracao:

- `PlayerCollision`
  - `collision_layer = 1` ou default
  - `collision_mask = 0`
- `ExactCollision`
  - `collision_layer = 16`
  - `collision_mask = 0`

## Qual shape usar

- `BoxShape3D`: melhor default para colisao de movimento
- `ConvexPolygonShape3D`: quando a caixa fica ruim demais
- `ConcavePolygonShape3D`: so para exact/raycast ou cenario estatico complexo

Evite usar `ConcavePolygonShape3D` para tudo. Ela e melhor para fidelidade do tiro, mas pior para a colisao grossa de movimento.

## Como gerar a colisao exact no Godot

Para `tabua_andaime.tscn`, faca assim no editor do Godot:

1. Abra `tabua_andaime.tscn`.
2. Encontre o `MeshInstance3D` que veio do `tabua_andaime.glb`.
3. Selecione esse `MeshInstance3D`.
4. No topo do editor 3D, use a opcao de mesh:
   - `Mesh` -> `Create Trimesh Static Body`
   - em algumas versoes aparece como `Create Trimesh Collision Sibling`
5. O Godot vai criar automaticamente:
   - um `StaticBody3D`
   - um `CollisionShape3D`
   - uma `ConcavePolygonShape3D` preenchida com a geometria da mesh

Depois:

- mantenha um body simples para movimento:
  - `PlayerCollision` com `BoxShape3D`
- reaproveite ou copie o body gerado para o exact:
  - `ExactCollision`
  - `collision_layer = 16`
  - `collision_mask = 0`
  - shape = `ConcavePolygonShape3D` gerada

## Como saber se a shape exact foi gerada de verdade

No `.tscn`, a shape concave nao pode ficar vazia.

Errado:

```tscn
[sub_resource type="ConcavePolygonShape3D" id="..."]
```

Certo:

```tscn
[sub_resource type="ConcavePolygonShape3D" id="..."]
data = PackedVector3Array(...)
```

Se existir `data = PackedVector3Array(...)`, a geometria foi gerada.

## Como o projeto atual faz hoje

Os nos dentro de `ExactCollisions` dos mapas atuais nao tem nada magico.
Eles sao apenas colliders invisiveis com:

- `StaticBody3D`
- `CollisionShape3D`
- `collision_layer = 16`

Ou seja:

- o tiro nao acerta mesh renderizada
- o tiro acerta shapes fisicas na layer 16

## Resumo pratico para usar daqui pra frente

- cada asset do mapa pode se autoencapsular com suas colisoes
- o mapa final pode apenas instanciar esses assets
- nao e necessario montar manualmente uma arvore gigante de `PlayerBoundaries` e `ExactCollisions`
- mas ainda e necessario manter a separacao funcional entre:
  - colisao de movimento
  - colisao exact para raycast

## Padrao recomendado para o projeto

1. Cada asset de cenario se responsabiliza por suas colisoes.
2. O mapa final so compoe esses prefabs.
3. `PlayerCollision` usa shape simples.
4. `ExactCollision` usa shape exata na layer 16.
5. No futuro, um script pode gerar automaticamente:
   - mapa client com mesh + colisao
   - mapa server com so colisao + nodes de gameplay

## Observacao sobre nomes

Os nomes `PlayerBoundaries` e `ExactCollisions` eram uma convencao de organizacao dos mapas antigos.
Para o codigo atual, o que realmente importa e:

- a shape fisica existir
- a layer estar correta
- os roots de gameplay do `GameMap` continuarem existindo quando necessario, como `SpawnPoints`, `Pickups`, `Objectives` e `SpecialPlatforms`

## Caso concreto da `tabua_andaime.tscn`

O estado ideal e:

- manter o collider simples atual como `PlayerCollision`
- gerar a `ConcavePolygonShape3D` real a partir da mesh
- colocar essa shape no `ExactCollision`

Com isso, o asset fica modular, facil de montar no mapa e alinhado com a logica atual do projeto.
