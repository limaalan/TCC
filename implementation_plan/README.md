# Plano de Implementação e Documentação Técnica

Este diretório reúne a documentação gerada a partir da análise de `TCC.md` e dos dois projetos Godot em `initial_project/Client` e `initial_project/Server`.

## Arquivos

- `01_documentacao_tecnica.md`: resumo das funcionalidades já implementadas e das técnicas usadas para resolver problemas de jogos multijogador citados no TCC.
- `02_comparativo_proposta_implementacao.md`: comparação entre a proposta do capítulo `Proposta` do `TCC.md` e o estado atual do projeto.
- `03_plano_de_implementacao.md`: plano prático para implementar o que ainda falta para aproximar o jogo da proposta original.
- `04_referencias_tutoriais.md`: referências externas avaliadas e notas de adaptação para implementar as funcionalidades restantes no modelo cliente/servidor atual.
- `05_plano_de_refatoracao.md`: plano de refatoração para reduzir contratos implícitos, strings soltas, configuração espalhada e facilitar novas funcionalidades.
- `06_plano_de_testes_deploy_cli.md`: próximos passos para testar, exportar e hospedar o jogo via Godot CLI/headless.
- `07_lista_de_assets_arte.md`: lista de assets low-poly reutilizáveis, metas de polígonos e prompts base para geração 3D.
- `08_guia_importacao_assets_mapas.md`: guia Blender/Godot para importar assets, criar mapas Client/Server e configurar colisões simplificadas/exatas.
- `09_backlog_tarefas_quebradas.md`: backlog em cards pequenos para refactors, multi-mapa, dois modos de jogo e deploy básico.
- `10_prompt_criar_issues.md`: versão pronta para colar em outro ChatGPT e criar as issues no GitHub.
- `11_prompt_planejar_task.md`: prompt reutilizável para pedir análise e plano de implementação de uma task, sem editar código.

## Escopo Da Análise

- A análise considera o estado atual dos arquivos em `initial_project/Client` e `initial_project/Server`.
- O projeto atual usa dois projetos Godot 4.5 separados: um cliente e um servidor.
- A proposta em `TCC.md` previa P2P/hospedeiro e uso de `MultiplayerSynchronizer`; a implementação atual usa um servidor separado autoritativo com RPCs, snapshots de estado e interpolação no cliente.
