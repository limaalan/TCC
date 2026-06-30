# 02 - Template prefab modular de cenario

Guia curto para padronizar prefabs de cenario modulares no projeto.

## Objetivo

Cada asset de cenario deve ser auto contido:

- visual dentro do proprio prefab
- colisao de movimento dentro do proprio prefab
- colisao exact para tiro dentro do proprio prefab

Isso facilita:

- montar o mapa
- mover e reaproveitar pecas
- editar o layout sem remontar colisoes globais
- gerar uma versao server do mapa no futuro

## Estrutura recomendada

Use este padrao em cada asset:

```text
NomeDoAsset
- VisualRoot
  - Mesh importada do GLB
- PlayerCollision
  - CollisionShape3D
- ExactCollision
  - CollisionShape3D
```

Exemplo:

```text
TabuaAndaime
- VisualRoot
  - tabua_andaime.glb
- PlayerCollision
  - CollisionShape3D (BoxShape3D)
- ExactCollision
  - CollisionShape3D (ConcavePolygonShape3D)
```

## Nomes recomendados

Prefira estes nomes:

- root: nome do asset, por exemplo `TabuaAndaime`
- visual: `VisualRoot`
- colisao simples: `PlayerCollision`
- colisao exact: `ExactCollision`

Evite usar dentro do prefab nomes como:

- `PlayerBoundaries`
- `ExactCollisions`

Esses nomes faziam sentido como agrupadores do mapa antigo. Dentro de prefabs, `PlayerCollision` e `ExactCollision` deixam a intencao mais clara.

## Configuracao das layers

`PlayerCollision`:

- `type = StaticBody3D`
- `collision_layer = 1` ou default
- `collision_mask = 0`

`ExactCollision`:

- `type = StaticBody3D`
- `collision_layer = 16`
- `collision_mask = 0`

No projeto atual, a layer `16` e a layer usada pelo raycast de tiro no server.

## Qual shape usar

Para `PlayerCollision`:

- prefira `BoxShape3D`
- use `ConvexPolygonShape3D` quando a caixa ficar ruim demais

Para `ExactCollision`:

- prefira `ConcavePolygonShape3D` gerada da mesh
- use shape mais simples so quando fizer sentido e nao afetar a precisao do tiro

## Regra pratica

- movimento precisa de shape simples e robusta
- tiro pode usar shape mais fiel

Nao use `ConcavePolygonShape3D` para tudo por padrao.

## Transform e escala

Boas praticas:

- ajuste a escala principal no prefab, nao no mapa final
- mover e rotacionar a instancia no mapa: ok
- evitar escalas fortes depois que a shape exact ja foi gerada

Se a escala mudar muito, gere a shape exact novamente.

## Cena composta

Uma cena maior pode ser composta por varias cenas menores.

Exemplo:

```text
Andaime
- andaime_base.tscn
- tabua_andaime.tscn
```

Isso funciona corretamente no Godot:

- os `StaticBody3D` internos sao instanciados junto
- as `CollisionShape3D` internas tambem
- as layers continuam funcionando

Entao uma cena composta pode ser colocada diretamente no mapa, sem precisar recriar os colliders no root do mapa.

## Checklist antes de colocar no mapa

Antes de usar o prefab no mapa, confirme:

1. Existe um `PlayerCollision` com shape valida.
2. Existe um `ExactCollision` com shape valida.
3. O `ExactCollision` esta na layer `16`.
4. A `ConcavePolygonShape3D` nao esta vazia.
5. O prefab funciona sozinho antes de ser usado numa cena maior.

## Exemplo de validacao no .tscn

Errado:

```tscn
[sub_resource type="ConcavePolygonShape3D" id="..."]
```

Certo:

```tscn
[sub_resource type="ConcavePolygonShape3D" id="..."]
data = PackedVector3Array(...)
```

## Relacao com o projeto atual

O codigo atual nao depende de um no global chamado `ExactCollisions`.
Ele depende de colisoes fisicas corretas na layer exact.

Entao o padrao modular e compativel com o projeto, desde que:

- os roots de gameplay do mapa continuem corretos quando necessario
- as layers das colisoes estejam corretas

## Conclusao

Padrao recomendado para novos assets:

- prefab modular por asset
- `VisualRoot`
- `PlayerCollision`
- `ExactCollision`

Esse e o formato mais facil para autoria de mapa e o melhor ponto de partida para automatizar a geracao do mapa server no futuro.
