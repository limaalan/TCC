# Validar prefab e conteúdo de mapa

## Objetivo

Verificar se uma cena importada pode entrar no jogo sem introduzir erro de referência, colisão ausente ou material inesperado.

## Checklist

- A cena abre no Godot sem recurso ausente ou nó quebrado.
- Os arquivos do pacote seguem o padrão `import/` já adotado pelo asset e não há export de teste referenciado pelo mapa.
- Os materiais necessários são internos ao GLB ou referenciados por caminho explícito.
- O prefab possui colisão e camadas corretas quando participa da simulação.
- Texturas e materiais compartilhados não foram copiados desnecessariamente.
- A cena foi instanciada no mapa correto e não apenas salva isoladamente.
- Client e Server concordam sobre a geometria que afeta gameplay.

## Validação no jogo

1. Rode Server e Client.
2. Entre no mapa que usa o prefab.
3. Teste colisão, raycast/disparo, pickup ou plataforma conforme o papel do asset.
4. Confira o console dos dois projetos por erros de recurso ou RPC.

Para Highrise, use também [sincronizar o mapa do Server](synchronize-highrise-server-map.md).
