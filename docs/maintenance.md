# Manutenção de mapas, recursos e contratos

Veja a [arquitetura](architecture.md) para localizar cada sistema e o [guia de build](build.md) para executar as verificações.

## Recursos 3D

- Recursos reutilizáveis ficam em `initial_project/Client/assets/`; os exclusivos de um mapa ficam no pacote correspondente em `Client/maps/`.
- Preserve o padrão de organização do pacote, incluindo `import/` quando utilizado. Mantenha o nome-base de `.blend`, `.glb` e cena wrapper coerente.
- Use uma cena `.tscn` para colisão, script ou material override. Instancie essa cena no mapa.
- Confira materiais, texturas, colisores e camadas. Antes de retirar um recurso, verifique seus usos nas cenas e a importação pelo Godot.
- As fontes de autoria em `assets/` na raiz são preservadas separadamente dos recursos consumidos pelos projetos.

## Highrise

Os projetos mantêm cenas próprias: `Client/maps/highrise/map_highrise.tscn` e `Server/maps/highrise/server_map_highrise.tscn`, dentro de `initial_project/`.

Após alterar a geometria do mapa visual, feche cenas que possam regravar o arquivo e execute, na raiz do repositório:

```powershell
.\initial_project\generate_highrise_server_map.ps1
```

Reabra a cena do servidor e confira colisão, nascimentos, plataformas de impulso, coletáveis e zona de captura numa partida local. O registro separado de mapas de cada projeto deve continuar apontando para a cena correspondente.

## Contratos e verificação

Edite definições comuns em `initial_project/shared/`. Payloads, chaves, nomes de RPC e seus consumidores precisam permanecer compatíveis nos dois projetos. Os grupos e métodos de integração da interface estão em `Client/game/client_names.gd`.

Depois de uma alteração funcional, confira console, conexão, carregamento, movimentação, combate, coleta, morte/retorno e resultado nos dois modos. Os testes headless cobrem fluxos específicos; imagem, áudio e entrada exigem observação manual.

O preview isolado do cliente é descrito em [Client/_debug/README.md](../initial_project/Client/_debug/README.md). Ele serve para inspecionar mapa, câmera e colisão sem executar uma partida em rede.
