# 04 - Validar cena com asset importado

Use este arquivo como instrucoes de prompt para um agente validar se uma cena com asset importado esta no formato correto para o projeto.

## Objetivo

Verificar se um asset importado do Blender para o Godot esta:

- com paths corretos
- com import funcionando
- com prefab modular valido
- com colisoes corretas
- compativel com Client e Server
- pronto para ser instanciado em mapas do projeto

## Escopo

O agente deve validar principalmente:

- cena do asset principal `.tscn`
- subcenas compostas por ele
- arquivos `.glb` usados como fonte
- compatibilidade com `res://shared/...` quando aplicavel
- funcionamento ao instanciar em mapa Client e Server

## Entradas esperadas

O agente deve receber:

- caminho da cena principal do asset
- caminhos das subcenas relacionadas, se houver
- caminhos dos mapas onde o asset foi instanciado, se houver

Exemplo:

- `initial_project/shared/teste_assets/andaime/andaime.tscn`
- `initial_project/shared/teste_assets/andaime/andaime_base.tscn`
- `initial_project/shared/teste_assets/andaime/tabua_andaime.tscn`
- `initial_project/Client/maps/map_prototype.tscn`
- `initial_project/Server/maps/server_map_prototype.tscn`

## Passo 1 - Conferir paths dos ext_resource

Ler os `.tscn` e verificar se todos os `ext_resource` apontam para arquivos que existem.

Validar especialmente:

- subcenas apontando para `res://shared/...` quando o asset esta em `shared`
- `.glb` apontando para o local real do arquivo
- ausencia de paths antigos ou quebrados como `res://maps/...` ou `res://assets/...` de outro contexto

Falha se:

- qualquer `ext_resource` referenciar recurso inexistente

## Passo 2 - Conferir se o GLB foi importado

Se o asset usa `.glb`, validar se cada projeto ja importou esse arquivo.

Como validar:

- rodar import no Client
- rodar import no Server

Comandos uteis:

```powershell
godot --headless --path "initial_project/Client" --import
godot --headless --path "initial_project/Server" --import
```

Falha se:

- houver erro de `Cannot open file 'res://.godot/imported/...`'
- houver erro de recurso nao encontrado para `.glb`

## Passo 3 - Conferir a estrutura do prefab

Verificar se a cena do asset segue o padrao modular esperado.

Estrutura recomendada:

```text
NomeDoAsset
- VisualRoot ou mesh importada
- PlayerCollision
  - CollisionShape3D
- ExactCollision
  - CollisionShape3D
```

Aceitar pequenas variacoes de nome, mas conferir se semanticamente existem:

- visual
- colisao simples
- colisao exact

Falha se:

- nao existir colisao simples
- nao existir colisao exact

## Passo 4 - Conferir a colisao simples

Verificar se o collider de movimento:

- e um `StaticBody3D`
- possui `CollisionShape3D`
- usa shape simples, preferencialmente `BoxShape3D` ou `ConvexPolygonShape3D`
- nao depende de mesh visual para funcionar

Aceitavel:

- `collision_mask = 0`
- `collision_layer` default ou layer normal de cenario

Falha se:

- o body nao tiver shape
- o body estiver vazio

## Passo 5 - Conferir a colisao exact

Verificar se o collider exact:

- e um `StaticBody3D`
- possui `CollisionShape3D`
- esta na `collision_layer = 16`
- usa shape apropriada para raycast exact

Preferencia:

- `ConcavePolygonShape3D` para superficies mais fieis

Falha se:

- a layer nao for `16`
- o `CollisionShape3D` nao existir
- a shape estiver vazia

## Passo 6 - Conferir se a ConcavePolygonShape3D foi realmente gerada

Nos `.tscn`, conferir se a shape concave tem geometria serializada.

Errado:

```tscn
[sub_resource type="ConcavePolygonShape3D" id="..."]
```

Certo:

```tscn
[sub_resource type="ConcavePolygonShape3D" id="..."]
data = PackedVector3Array(...)
```

Falha se:

- a `ConcavePolygonShape3D` existir mas nao tiver `data`

## Passo 7 - Conferir cenas compostas

Se a cena principal instancia outras subcenas, verificar se:

- todas resolvem corretamente
- os colliders das subcenas vao junto
- nao ha dependencia oculta de um mapa especifico

Exemplo valido:

```text
Andaime
- andaime_base.tscn
- tabua_andaime.tscn
```

Falha se:

- a cena composta instancia subcena quebrada
- as subcenas perderem as colisoes ao serem compostas

## Passo 8 - Conferir compatibilidade com shared

Se o asset estiver em `initial_project/shared/...`, validar que:

- Client consegue carregar `res://shared/...`
- Server consegue carregar `res://shared/...`

Lembrar:

- a pasta fonte pode ser compartilhada
- o cache `.godot/imported` continua separado por projeto

Falha se:

- importar no Client funcionar e no Server nao
- ou vice versa

## Passo 9 - Conferir instanciacao em mapa Client e Server

Se o asset foi colocado em mapas reais, validar que os mapas abrem sem erro.

Comandos uteis:

```powershell
godot --headless --path "initial_project/Client" "maps/map_prototype.tscn" --quit-after 1
godot --headless --path "initial_project/Server" "maps/server_map_prototype.tscn" --quit-after 1
```

Aceitar warnings que nao sejam do asset testado, mas reporta-los.

Falha se:

- o mapa nao abrir por causa do asset
- houver parse error do `.tscn`
- houver missing resource do prefab ou `.glb`

## Passo 10 - Conferir compatibilidade com o gameplay atual

Verificar se o formato do asset e compativel com o projeto atual:

- colisao simples serve para movimento de player e granada
- colisao exact serve para raycast de tiro
- nao depende de estar debaixo de um no global chamado `ExactCollisions`

Lembrar:

- o codigo atual depende da layer exact
- nao depende necessariamente da organizacao em arvore antiga do mapa

Falha se:

- o asset so funcionar quando manualmente colocado em `PlayerBoundaries` ou `ExactCollisions`

## Passo 11 - Checar problemas visuais comuns

Se o asset ja estiver em jogo, observar:

- decal de tiro aparecendo do lado errado
- marcas vazando para o outro lado de geometria fina
- hit FX deslocado

Interpretacao:

- vazamento de decal em geometria fina costuma ser problema de `Decal.size` e profundidade, nao necessariamente normal invertida
- se a orientacao da superficie parecer invertida, conferir normals no Blender

## Saida esperada do agente

O agente deve responder com este formato:

### Status

- `OK` se a cena estiver pronta
- `OK com ressalvas` se houver warnings aceitaveis
- `FALHOU` se houver problema estrutural

### Achados

- lista objetiva dos problemas encontrados
- apontar arquivo e linha quando possivel

### Validacoes aprovadas

- paths
- import
- prefab modular
- collider simples
- collider exact
- carga em Client
- carga em Server

### Proximos ajustes

- o minimo necessario para deixar o asset correto

## Criterio final de aprovado

Uma cena com asset importado esta no formato correto quando:

1. Todos os recursos resolvem corretamente.
2. O `.glb` importa nos dois projetos.
3. O prefab tem colisao simples e exact.
4. A colisao exact usa layer `16`.
5. A `ConcavePolygonShape3D` tem `data` real.
6. A cena composta instancia corretamente.
7. O asset pode ser colocado em mapa Client e Server sem quebrar carregamento.

Se todos esses pontos passarem, o asset esta apto para teste de gameplay no projeto.
