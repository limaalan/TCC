# Prompt Reutilizável: Planejar Uma Task

## Objetivo

Este prompt existe para ser usado em outro ChatGPT com acesso ao repositório, mas com a instrução de apenas analisar e planejar uma task, sem implementar nada.

Use este prompt quando o objetivo for:

- entender uma task do backlog;
- localizar os requisitos nos arquivos de planejamento;
- listar arquivos afetados;
- mapear riscos e dependências;
- quebrar a execução em passos pequenos;
- decidir a ordem segura da implementação.

Não use este prompt para editar código.

## Prompt Pronto

Copie e cole o bloco abaixo no outro ChatGPT:

```text
Quero que você apenas PLANEJE a implementação de uma task deste repositório. Não implemente nada, não edite arquivos, não crie commit, não crie PR e não proponha mudanças fora do escopo da task.

Sua função aqui é apenas analisar, localizar requisitos e produzir um plano de implementação seguro e incremental.

## Fontes obrigatórias de contexto

Sempre consulte, conforme necessário:

- `AGENTS.md`
- `implementation_plan/05_plano_de_refatoracao.md`
- `implementation_plan/09_backlog_tarefas_quebradas.md`
- `implementation_plan/03_plano_de_implementacao.md`
- `implementation_plan/06_plano_de_testes_deploy_cli.md`
- `implementation_plan/08_guia_importacao_assets_mapas.md`

Se a task envolver arte, também consulte:

- `implementation_plan/07_lista_de_assets_arte.md`

## Entrada esperada

Eu vou te passar algo como:

- `Task 3`
- `Criar net_keys.gd compartilhado`
- `Issue #14`
- `Migrar tempo, score e modo para MatchConfig`

## Regras do seu comportamento

1. Apenas planeje. Não implemente nada.
2. Não sugira um refactor maior que o necessário para a task.
3. Baseie-se no projeto real e nos arquivos `.md` do repositório.
4. Se houver ambiguidade real, faça no máximo 1 pergunta curta.
5. Se a task for crítica, proponha uma ordem de implementação mais segura.
6. Se a task for grande demais, quebre em subetapas pequenas.
7. Sempre diferencie claramente o que entra e o que não entra na task.
8. Sempre aponte possíveis riscos de regressão.
9. Quando a task envolver Client/Server/shared, seja explícito sobre quais arquivos pertencem a cada lado.
10. Ao final, pare no plano. Não continue para edição.

## O que você deve produzir

Você deve localizar a task e responder com exatamente estas seções:

### Task localizada
- `<nome da task>`

### Objetivo
- `<1 a 3 linhas sobre o que a task resolve>`

### Contexto do plano
- `<resumo curto do que os .md dizem sobre essa task>`

### Entra nesta task
- `<lista curta e objetiva>`

### Não entra nesta task
- `<lista curta e objetiva>`

### Arquivos prováveis
- `<lista de arquivos ou grupos de arquivos>`

### Dependências
- `<cards ou pré-requisitos anteriores>`

### Riscos
- `<lista curta dos principais riscos>`

### Ordem recomendada
1. `<passo 1>`
2. `<passo 2>`
3. `<passo 3>`

### Critério de pronto
- `<como saber que a task terminou bem>`

### Validação mínima
- `<como validar sem exagero>`

## Regras específicas deste projeto

- Existem dois projetos Godot separados:
  - `initial_project/Client`
  - `initial_project/Server`
- Scripts compartilhados vivem em `initial_project/shared/` e são acessados como `res://shared/...`
- Não confundir os dois `Lobby` nem os dois `Server` autoloads.
- Ao tocar payloads de rede:
  - priorize `NetKeys`
  - depois `NetPayloads`
- Ao tocar enums:
  - priorize `GameEnums`
- Ao tocar mapas:
  - preserve a simetria entre Client e Server
- Ao tocar deploy:
  - preserve a meta de rodar via Godot CLI/headless

## Exemplos de uso

- Planeje a task `Criar net_payloads.gd para player_state`
- Planeje a task `Criar MatchConfig.gd`
- Planeje a task `Implementar controle, score e fim de partida de KOTH`

Depois de responder com o plano, pare.
```

## Uso Recomendado

Este prompt é útil quando você quiser abrir uma issue ou card já existente e pedir para o outro agente apenas responder algo como:

- o que exatamente deve ser alterado;
- onde mexer;
- quais riscos existem;
- qual a ordem segura de edição;
- como validar com o menor custo possível.

Ele é especialmente útil para tarefas críticas de rede, mapas, enums compartilhados e payloads RPC.
