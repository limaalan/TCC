# Guia Da Arquitetura Do Projeto

## Objetivo

Este documento define a arquitetura de pastas recomendada para o projeto, com foco em:

- organizacao limpa dos mapas;
- organizacao limpa dos assets reutilizaveis;
- versionamento dos arquivos fonte de arte, como `.blend`;
- separacao clara entre arquivos de autoria e arquivos usados em runtime pela Godot;
- compatibilidade com a estrutura atual de dois projetos Godot separados: `Client` e `Server`.

## Decisao Arquitetural

O projeto vai seguir o modelo descentralizado.

Isso significa:

- cada asset importante vira um pacote autocontido;
- cada mapa fica dentro da propria pasta;
- o arquivo `.blend` original fica perto do asset ou mapa a que ele pertence;
- o `.glb` usado em runtime fica fora da pasta `source/`;
- arquivos auxiliares de autoria e exports intermediarios ficam dentro de `source/`.

Resumo pratico:

- o que a Godot usa em runtime fica visivel para a engine;
- o que serve para autoria, historico e retrabalho futuro fica versionado, mas fora do pipeline de import.

## Principios

1. Um asset reutilizavel deve ter uma pasta propria.
2. Um mapa deve ter uma pasta propria.
3. O `Client` e o `Server` continuam separados como projetos Godot independentes.
4. O `Client` concentra os assets visuais e os mapas renderizados.
5. O `Server` concentra os mapas autoritativos, colisao e nodes de gameplay.
6. Os arquivos fonte de arte devem ficar em `source/`, nunca misturados sem criterio com os arquivos de runtime.
7. O `.glb` canonico usado pela Godot deve ficar fora de `source/`.
8. Exports intermediarios que nao sao carregados pela Godot devem ficar em `source/exports/`.
9. Pastas e arquivos devem usar `snake_case`.
10. O nome base do asset deve ser consistente entre `.blend`, `.glb` e `.tscn`.

## Estrutura Macro Recomendada

```text
initial_project/
  Client/
    assets/
    maps/
    player/
    ui/
    game/

  Server/
    maps/
    player/
    server/
    game/
```

## Estrutura Recomendada Para Assets Reutilizaveis

Cada asset reutilizavel deve virar um pacote proprio.

Exemplo:

```text
initial_project/Client/assets/environment/buildings/barn_big/
  barn_big.glb
  barn_big.tscn
  source/
    .gdignore
    barn_big.blend
    exports/
      barn_big_collision.glb
      barn_big_lod0.glb
      barn_big_blockout.glb
```

### Regra desse pacote

- `barn_big.glb`: arquivo canonico de runtime usado pela Godot.
- `barn_big.tscn`: cena wrapper final usada no mapa.
- `source/barn_big.blend`: arquivo original editavel.
- `source/exports/`: exports auxiliares, testes, colisoes intermediarias e arquivos que nao devem ser usados diretamente no runtime.

## Estrutura Recomendada Para Mapas

Cada mapa deve ter a propria pasta.

Exemplo para o mapa `farm`:

```text
initial_project/Client/maps/farm/
  map_farm.tscn
  assets/
  source/
    .gdignore
    map_farm.blend
    exports/
      farm_blockout_reference.glb

initial_project/Server/maps/farm/
  server_map_farm.tscn
```

### Regra dos mapas

- `Client/maps/<mapa>/`: versao visual do mapa.
- `Server/maps/<mapa>/`: versao autoritativa do mapa para gameplay.
- `Client/maps/<mapa>/source/`: arquivo fonte do mapa, blockout e exports auxiliares.
- `Client/maps/<mapa>/assets/`: assets exclusivos daquele mapa, quando nao fizer sentido promovelos para `Client/assets/`.

## Quando Um Asset Vai Para `Client/assets/` Ou Para `Client/maps/<mapa>/assets/`

Use `Client/assets/` quando o asset:

- puder ser reutilizado em outros mapas;
- tiver identidade propria;
- merecer manutencao independente.

Use `Client/maps/<mapa>/assets/` quando o asset:

- for exclusivo de um mapa;
- depender fortemente daquele layout;
- nao fizer sentido como pacote reutilizavel global.

## Estrutura Recomendada De Categorias Em `Client/assets/`

```text
initial_project/Client/assets/
  environment/
    buildings/
    props/
    nature/
    terrain/
  characters/
  weapons/
  pickups/
  materials/
  textures/
  audio/
  multimeshes/
```

Observacao importante:

- o projeto atual ja usa `materials/`, `textures/`, `audio/` e `multimeshes`;
- a principal mudanca proposta aqui e encapsular melhor os assets 3D reutilizaveis em pacotes por asset.

## Estrutura Minima Obrigatoria De Um Asset 3D Novo

Para todo asset 3D novo reutilizavel, o padrao minimo passa a ser:

```text
nome_do_asset/
  nome_do_asset.glb
  nome_do_asset.tscn
  source/
    .gdignore
    nome_do_asset.blend
```

Se houver exports intermediarios:

```text
nome_do_asset/
  nome_do_asset.glb
  nome_do_asset.tscn
  source/
    .gdignore
    nome_do_asset.blend
    exports/
      nome_do_asset_lod0.glb
      nome_do_asset_collision.glb
      nome_do_asset_test.glb
```

## Regras De Nome

- Pastas e arquivos: `snake_case`.
- Nome base identico entre os arquivos principais.
- Evitar espacos em nomes de pasta e arquivo.
- Evitar nomes vagos como `final`, `novo`, `teste2`, `versao_certa`.

Exemplo bom:

```text
water_tower/
  water_tower.glb
  water_tower.tscn
  source/
    water_tower.blend
```

Exemplo ruim:

```text
torre/
  torre_final_mesmo.glb
  torre_nova_2.blend
  arquivo_certo_agora.tscn
```

## Regras Para O `Client`

- O `Client` deve guardar meshes, materiais, audio, texturas e cenas visuais.
- O `Client` deve ser o dono dos arquivos fonte de arte relacionados a assets visuais.
- O `Client` pode ter cenas wrapper `.tscn` para cada asset reutilizavel.
- O `Client` pode ter assets exclusivos por mapa dentro de `Client/maps/<mapa>/assets/`.

## Regras Para O `Server`

- O `Server` nao deve armazenar source art visual sem necessidade.
- O `Server` deve manter apenas o que entra na simulacao autoritativa.
- O `Server` deve conter mapas, colisao, pickups, spawns, objetivos e regras de gameplay.
- O `Server` nao deve virar deposito duplicado de `.blend` e `.glb` visuais do `Client`.

## Regra Importante Sobre `source/`

Nao usar `import/` como nome de pasta para originais e exports auxiliares.

Usar `source/` por tres motivos:

- o nome fica mais claro;
- evita confusao com o sistema de import da Godot;
- separa melhor autoria de runtime.

## Como Funciona O `.gdignore`

Trecho da documentacao oficial da Godot:

> "To prevent Godot from importing files contained in a specific folder, create an empty file called .gdignore in the folder (the leading . is required). This can be useful to speed up the initial project importing."

Aplicacao pratica neste projeto:

- toda pasta `source/` deve conter um arquivo vazio `.gdignore`;
- isso impede a Godot de importar `.blend` e exports auxiliares daquela pasta;
- os arquivos continuam versionados no Git normalmente;
- o FileSystem do editor fica mais limpo;
- o tempo de import inicial pode diminuir.

## Fluxo Recomendado Para Criar Um Asset Novo

1. Criar a pasta do asset no dominio correto, por exemplo `Client/assets/environment/props/crate/`.
2. Salvar o arquivo original em `source/crate.blend`.
3. Criar `source/.gdignore`.
4. Exportar o `.glb` canonico para `crate.glb` na raiz do pacote.
5. Criar `crate.tscn` como cena wrapper final.
6. Colocar exports auxiliares em `source/exports/`.
7. Instanciar preferencialmente `crate.tscn` no mapa, nao o `.glb` direto.

## Fluxo Recomendado Para Criar Um Mapa Novo

1. Criar `Client/maps/<nome_do_mapa>/`.
2. Criar `Server/maps/<nome_do_mapa>/`.
3. Colocar o arquivo original do mapa em `Client/maps/<nome_do_mapa>/source/`.
4. Deixar a cena visual no `Client`.
5. Deixar a cena autoritativa de gameplay no `Server`.
6. Promover para `Client/assets/` todo asset do mapa que passar a ser reutilizavel em outros cenarios.

## Diretivas Obrigatorias

- Todo asset novo reutilizavel deve ter pasta propria.
- Todo mapa novo deve ter pasta propria.
- Todo arquivo `.blend` novo deve ficar em `source/`.
- Todo `source/` deve ter `.gdignore` vazio.
- O `.glb` usado pela Godot deve ficar fora de `source/`.
- Exports auxiliares nao usados em runtime devem ficar em `source/exports/`.
- O `Server` nao deve duplicar source art do `Client` sem necessidade real.
- O nome base do asset deve ser consistente entre `.blend`, `.glb` e `.tscn`.

## Diretivas Recomendadas

- Instanciar `.tscn` wrapper nos mapas, nao o `.glb` bruto.
- Encapsular colisao junto com o prefab quando fizer sentido.
- Migrar gradualmente os assets atuais para o novo formato, sem renomear tudo de uma vez.
- Manter assets exclusivos do mapa dentro da pasta do mapa ate existir reuso real.

## Anti Padroes A Evitar

- uma pasta `assets/` gigante sem divisao clara;
- varios `.glb` com nomes ambiguos para o mesmo asset;
- `.blend` solto ao lado de arquivos de runtime sem `source/`;
- duplicar o mesmo source art em `Client` e `Server`;
- usar `import/` para guardar originais;
- usar a pasta do `Server` como arquivo morto de assets visuais.

## Observacoes Especificas Do Estado Atual Do Repositorio

Hoje existe uma incompatibilidade importante com este guia:

- o `.gitignore` atual ignora `initial_project/Client/assets`.

Se este guia for adotado como padrao oficial, essa regra precisara ser revista para permitir o versionamento dos assets de runtime do `Client`.

Recomendacao:

- nao fazer uma migracao total de uma vez;
- aplicar o padrao primeiro em assets e mapas novos;
- migrar os antigos conforme houver manutencao real.

## Fontes

### Documentacao oficial da Godot

- Project organization:
  - https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html
- Importing 3D scenes:
  - https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/index.html

### Contexto interno analisado no repositorio

- `README.md`
- `.gitignore`
- `implementation_plan/08_guia_importacao_assets_mapas.md`
- `how_to/01-como_importar_glb.md`
- `how_to/02-template_prefab_modular_cenario.md`

## Conclusao

O padrao oficial recomendado para este projeto e:

- `Client` como dono dos assets visuais e do source art associado;
- `Server` como dono da simulacao autoritativa;
- um pacote por asset importante;
- uma pasta por mapa;
- `source/` com `.gdignore` para todos os arquivos de autoria;
- apenas o `.glb` canonico e a `.tscn` final expostos ao runtime da Godot.
