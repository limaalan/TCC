# Importar e manter assets 3D

## Objetivo

Adicionar ou alterar um asset 3D sem deixar exports intermediários, materiais duplicados ou referências quebradas no projeto Godot.

## Procedimento

1. Escolha o domínio do asset: reutilizável em `Client/assets/` ou exclusivo de mapa em `Client/maps/<mapa>/assets/`.
2. Siga o padrão já usado pelo pacote do asset, inclusive a pasta `import/` para seus arquivos relacionados.
3. Mantenha uma cena wrapper `.tscn` quando o asset precisar de colisão, material override, script ou configuração própria.
4. Reabra o projeto no Godot, aguarde a importação e confira a árvore de nós, materiais e colisores.
5. Instancie a cena wrapper no mapa, não um export de teste.

## Regras

- Use `snake_case` e mantenha o mesmo nome-base em `.blend`, `.glb` e `.tscn`.
- Só extraia um material para `.tres` quando ele precisar de edição ou reuso deliberado. Materiais internos ao GLB são preferíveis quando não há override.
- Antes de remover uma textura ou material, procure referências com `rg` e abra as cenas que usam o asset.

## Validar

Use [validar prefab e mapa](validate-prefab-and-map-content.md) e rode uma partida local quando o asset tiver colisão ou comportamento de gameplay.
