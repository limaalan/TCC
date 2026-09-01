# Plano de Implementacao e Documentacao Tecnica

Este diretorio reune a documentacao gerada a partir da analise de `TCC.md` e dos dois projetos Godot em `initial_project/Client` e `initial_project/Server`.

## Arquivos

- `01_documentacao_tecnica.md`: resumo das funcionalidades ja implementadas e das tecnicas usadas para resolver problemas de jogos multijogador citados no TCC.
- `02_comparativo_proposta_implementacao.md`: comparacao entre a proposta do capitulo `Proposta` do `TCC.md` e o estado atual do projeto.
- `03_plano_de_implementacao.md`: plano pratico para implementar o que ainda falta para aproximar o jogo da proposta original.
- `04_referencias_tutoriais.md`: referencias externas avaliadas e notas de adaptacao para implementar as funcionalidades restantes no modelo cliente/servidor atual.
- `05_plano_de_refatoracao.md`: plano de refatoracao para reduzir contratos implicitos, strings soltas, configuracao espalhada e facilitar novas funcionalidades.
- `06_plano_de_testes_deploy_cli.md`: proximos passos para testar, exportar e hospedar o jogo via Godot CLI/headless.
- `07_lista_de_assets_arte.md`: lista de assets low-poly reutilizaveis, metas de poligonos e prompts base para geracao 3D.
- `08_guia_importacao_assets_mapas.md`: guia Blender/Godot para importar assets, criar mapas Client/Server e configurar colisoes simplificadas/exatas.
- `09_backlog_tarefas_quebradas.md`: backlog em cards pequenos para refactors, multi-mapa, dois modos de jogo e deploy basico.
- `10_prompt_criar_issues.md`: versao pronta para colar em outro ChatGPT e criar as issues no GitHub.
- `11_prompt_planejar_task.md`: prompt reutilizavel para pedir analise e plano de implementacao de uma task, sem editar codigo.
- `12_task-priorization.md`: priorizacao de tarefas e criterio de ordem de execucao.
- `13_skill_validacao_arquitetura_paths.md`: skill/documento para checagem de paths e limites entre os projetos Client e Server.
- `14_documentacao_tecnica_metricas_rede.md`: documentacao tecnica resumida da coleta de metricas de rede.
- `15_runtime_observabilidade_e_comandos_servidor.md`: contrato operacional de flags, exemplos de build/export e modelos de scripts para subir servidor e dashboard.
- `16_plano_muzzle_fx_por_arma.md`: arquitetura de cenas de muzzle FX por arma, selecionadas via `WeaponPresentationData` e executadas por uma interface comum.

## Escopo Da Analise

- A analise considera o estado atual dos arquivos em `initial_project/Client` e `initial_project/Server`.
- O projeto atual usa dois projetos Godot 4.5 separados: um cliente e um servidor.
- A proposta em `TCC.md` previa P2P/hospedeiro e uso de `MultiplayerSynchronizer`; a implementacao atual usa um servidor separado autoritativo com RPCs, snapshots de estado e interpolacao no cliente.
