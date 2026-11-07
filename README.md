# jumpnshoot

Jogo 3D multijogador de tiro em primeira pessoa desenvolvido como TCC. Combina combate em equipes, salto duplo e plataformas de impulso. Possui modos Team Deathmatch e King of the Hill no mapa Highrise, com cliente e servidor dedicado em projetos Godot separados.

## Começar

As [releases](https://github.com/limaalan/TCC/releases) oferecem cliente e servidor para Windows/Linux. Inicie o servidor antes dos clientes e configure endereço e porta; o padrão é **7777/UDP**. As predefinições normais usam dois participantes por partida.

Para gerar as quatro builds, use Docker Linux x86_64; no Windows, execute no terminal WSL2:

```bash
mkdir -p build/releases build/smoke build/diagnostics
docker compose --profile tools build build
docker compose --profile tools run --rm build
```

A saída fica em `build/releases/local/`. O processo fixa Godot 4.5.1. Veja os pré-requisitos e comandos de execução no guia de build.

## Documentação técnica

| Guia | Conteúdo |
| --- | --- |
| [Build e execução](docs/build.md) | Exportações, partida local e verificação dos artefatos. |
| [Configuração](docs/configuration.md) | Arquivos, parâmetros, padrões e precedência. |
| [Arquitetura](docs/architecture.md) | Responsabilidades, rede e onde alterar cada sistema. |
| [Publicação](docs/publishing.md) | CI, releases, configuração do deploy e diagnóstico. |
| [Manutenção](docs/maintenance.md) | Mapas, recursos 3D e contratos compartilhados. |
| [Métricas](docs/metrics.md) | Configuração da coleta e leitura dos CSVs. |

O [guia de teste de carga](docs/how_to/run-load-pilot.md) explica como executar uma partida com bots e coletar métricas.

## Código e trabalhos acadêmicos

- `initial_project/Client/` e `initial_project/Server/`: projetos Godot independentes.
- `initial_project/shared/`: contratos e definições comuns; não editar pelas junções dentro dos projetos.
- `scripts/`, `docker/` e `.github/workflows/`: ferramentas de build, verificação e publicação.
- [TCC2](docs/report/LEIA-ME.md): fontes LaTeX atuais; compilação a partir de `main.tex`.
- [TCC1](docs/tcc/TCC1.pdf): versão original em PDF.

Os testes headless cobrem fluxos específicos e complementam a conferência manual de controles, imagem, áudio e combate. Tarefas do projeto são acompanhadas no GitHub Projects; o padrão de commit é prefixado pelo número da tarefa, por exemplo `2. Criação do modelo de personagem`.

## Créditos

Os [avisos de terceiros](THIRD_PARTY_NOTICES.md) registram os ícones identificados, a procedência dos áudios e os limites da verificação de atribuições. Esse registro não define uma licença única para o jogo, suas artes ou o texto acadêmico.
