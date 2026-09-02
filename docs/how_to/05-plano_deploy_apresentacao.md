# 05 - Plano de deploy para apresentacao

Plano simples para colocar o servidor do jogo na internet apenas para demonstracao no dia da apresentacao.

## Objetivo

Subir o servidor do projeto em uma maquina Linux na internet, com baixa complexidade operacional e preferencia por infraestrutura no Brasil para reduzir latencia.

Este plano assume:

- escopo pequeno
- poucos jogadores simultaneos
- sem necessidade de escalabilidade
- foco em funcionar bem no dia da apresentacao

## Recomendacao principal

Escolher uma VPS Linux com IP publico no Brasil.

Melhores opcoes para este caso:

1. **Vultr Sao Paulo**
2. **Locaweb VPS**
3. **KingHost VPS**

Essas opcoes fazem mais sentido do que AWS, Azure ou GCP para este contexto porque:

- sao mais simples de operar
- exigem menos configuracao de cloud enterprise
- resolvem bem um servidor pequeno e temporario
- ajudam a evitar custo e complexidade desnecessarios

## Minha recomendacao pratica

Se for para escolher uma so:

### Opcao 1 - Vultr Sao Paulo

Melhor equilibrio entre:

- simplicidade
- controle tecnico
- painel limpo
- IP publico facil
- datacenter em Sao Paulo

Perfil ideal:

- voce quer uma experiencia tipo DigitalOcean
- quer uma VM simples e direta
- quer evitar burocracia de cloud maior

### Opcao 2 - Locaweb VPS

Boa opcao se voce quiser:

- pagar em reais
- suporte em portugues
- infraestrutura no Brasil
- operacao mais nacional e menos "cloud hyperscaler"

### Opcao 3 - KingHost VPS

Boa alternativa semelhante a Locaweb:

- acesso root
- infraestrutura brasileira
- suporte em portugues

## O que nao faz sentido aqui

Para esta apresentacao, eu evitaria:

- AWS
- Azure
- arquitetura com containers e orquestracao
- Kubernetes
- balanceador
- multiregiao
- automacao complexa de deploy

Nada disso agrega para a banca se o objetivo e so provar que o jogo funciona online.

## Especificacao minima sugerida

Para o servidor atual do projeto:

- Linux
- 2 vCPU
- 2 GB RAM
- 20 GB SSD ou mais
- IP publico

Se quiser economizar ao maximo, ate 1 vCPU e 1 GB pode servir para teste, mas eu recomendaria **2 vCPU / 2 GB** para ter mais folga e reduzir risco no dia.

## Rede necessaria

O servidor do projeto usa a porta `7777`.

No host remoto, voce precisa liberar:

- **UDP 7777**

Checklist:

- firewall da VPS liberado
- firewall do sistema operacional liberado
- IP publico anotado para os clientes conectarem

## Por que Linux headless e o melhor caminho

O servidor atual do projeto e um bom candidato para headless porque:

- o `main_game.tscn` do Server e minimo
- a inicializacao real acontece no autoload
- o servidor sobe `ENetMultiplayerPeer`
- nao depende de UI ou janela para funcionar

Entao a abordagem correta e:

- exportar o projeto Server para Linux
- rodar em modo headless

## Fluxo de deploy recomendado

### Passo 1 - Escolher a VPS

Escolher uma das opcoes recomendadas com:

- Ubuntu Server ou Debian
- 2 vCPU
- 2 GB RAM
- IP publico

### Passo 2 - Preparar o servidor Linux

Instalar atualizacoes basicas e ferramentas uteis.

Exemplo de pacote minimo:

- `unzip`
- `screen` ou `tmux`
- `ufw` se quiser firewall simples

### Passo 3 - Exportar o projeto Server

Exportar apenas o projeto:

- `initial_project/Server`

Alvo:

- Linux/X11 ou Linux headless, dependendo do preset que voce usar

Se o export headless puro nao estiver pronto no projeto, pode usar export Linux normal e executar com `--headless`.

### Passo 4 - Enviar os arquivos

Copiar para a VPS:

- executavel do servidor
- `.pck`
- arquivos auxiliares gerados no export

### Passo 5 - Liberar a porta

Liberar `UDP 7777` na VPS.

### Passo 6 - Rodar o servidor

Executar o binario em headless.

Exemplo generico:

```bash
./Server.x86_64 --headless
```

Ou manter com:

- `tmux`
- `screen`
- ou `systemd`

Para apresentacao, `tmux` ja resolve. Se quiser algo mais confiavel, use `systemd`.

### Passo 7 - Testar externamente

No Client:

- apontar para o IP publico da VPS
- testar conexao real por internet

Fazer isso antes do dia da apresentacao.

## Estrategia de risco baixa para o dia

Para reduzir risco na apresentacao:

1. Subir a VPS com pelo menos alguns dias de antecedencia.
2. Testar o jogo com internet real, nao so localhost.
3. Deixar um comando pronto para reiniciar o servidor rapidamente.
4. Manter backup do build exportado localmente.
5. Se possivel, manter uma segunda VPS barata ou um plano B local.

## Plano A e plano B

### Plano A

- Vultr Sao Paulo
- Ubuntu Server
- 2 vCPU / 2 GB
- servidor rodando em `tmux` ou `systemd`

### Plano B

- Locaweb VPS ou KingHost VPS
- mesma configuracao

Se por algum motivo a primeira opcao falhar em prazo, va para uma dessas nacionais mais diretas.

## O que preparar antes da banca

Checklist final:

1. Export do `Server` funcionando.
2. VPS contratada e acessivel por SSH.
3. Porta `7777/UDP` liberada.
4. Servidor inicializando sem erro.
5. Client conectando pelo IP publico.
6. Teste com pelo menos 2 clientes fora do localhost.
7. Comando de restart salvo.
8. Build local de emergencia pronto.

## Conclusao

Para este projeto e esta apresentacao, o melhor plano e manter tudo simples.

Escolha recomendada:

1. **Vultr Sao Paulo**
2. **Locaweb VPS**
3. **KingHost VPS**

Arquitetura recomendada:

- uma VPS Linux pequena
- servidor Godot em headless
- porta `7777/UDP` aberta
- sem cloud pesada e sem escalabilidade desnecessaria

Esse e o caminho mais pragmatico para mostrar o jogo funcionando online com baixo risco operacional.
