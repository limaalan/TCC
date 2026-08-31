# Plano De Fechamento Das Pontas Para A Entrega Final Do TCC

## Objetivo

Este plano organiza o trabalho restante para transformar o estado atual do projeto em uma entrega demonstravel, distribuivel e defensavel no TCC.

O foco final e:

1. apresentar um jogo multiplayer funcional;
2. manter o servidor dedicado publicado;
3. permitir que outras pessoas baixem o Client Windows e joguem durante a apresentacao;
4. aplicar um passe artistico coerente e garantir licencas dos assets;
5. executar um experimento simples com as metricas implementadas;
6. concluir o relatorio tecnico com base no sistema realmente entregue.

Data deste diagnostico: 21 de julho de 2026.

## Decisoes De Escopo

### Entrega Alvo

- Client nativo para Windows, distribuido como ZIP portatil.
- Servidor Linux dedicado e autoritativo.
- Mapa final: Highrise.
- Modos demonstrados: Team Deathmatch e King of the Hill.
- Pagina publica no itch.io para apresentar o jogo e hospedar o download.
- GitHub Release como espelho e backup do Client.
- IP e porta configuraveis no Client.
- Dashboard de metricas como parte da demonstracao tecnica.

### Fora Do Escopo Da Entrega

- Export Web jogavel.
- Capture the Flag.
- Lancador de foguetes e canhao laser.
- Vidas limitadas.
- Plataforma quebradica.
- Lobby browser publico.
- Matchmaking escalavel.
- Sistema de contas.
- Refatoracao geral de todo o codigo.
- Automacao completa de deploy antes de o processo manual estar validado.

O export Web fica fora do escopo porque o Client atual usa `ENetMultiplayerPeer` sobre UDP, transporte indisponivel no navegador. Uma versao Web exigiria migrar a rede para WebSocket ou WebRTC e adaptar o projeto ao renderizador Compatibility.

## Estado Atual Confirmado

O projeto ja possui:

- projetos Godot 4.5 separados para Client e Server;
- servidor dedicado autoritativo com ENet;
- Team Deathmatch e King of the Hill;
- mapa Highrise em versoes Client e Server;
- movimentacao, corrida, pulo duplo e JumpPad;
- pistola, SMG e shotgun;
- troca de arma e municao;
- granadas, vida, dano, respawn e placar;
- pickups de vida, municao e powerups;
- menu, HUD, pausa e configuracoes de audio/tela;
- presets de export para Windows, Linux Client e Linux Server;
- coleta de metricas em CSV, streaming UDP e dashboard Python.

Os dois projetos foram carregados pelo Godot 4.5.1 em modo headless sem erros de parse de scripts ou cenas. Isso nao substitui o smoke test multiplayer manual.

## Riscos Que Bloqueiam A Entrega

### Assets E Build Nao Reproduziveis

O diagnostico local encontrou:

- 155 arquivos de assets ignorados pelo Git;
- 59 recursos ignorados que sao referenciados por scripts ou cenas;
- audio, materiais compartilhados e texturas de interface fora do versionamento;
- Client exportado com aproximadamente 129 MB e desatualizado em relacao ao codigo;
- binario Linux do Server versionado na raiz do projeto Server;
- logs e executaveis soltos nos projetos;
- preset `all_resources`, que inclui conteudo antigo no pacote.

O jogo pode funcionar na maquina atual e ainda falhar em um clone limpo.

### Conexao Publica Incompleta

O Client agora usa o endereco persistido em `user://settings.cfg` como unica fonte de verdade em execucao. `default_settings.cfg` serve apenas para preencher esse arquivo no primeiro uso da build e deve receber o IP da VPS antes da exportacao. Se nenhum endereco estiver configurado, o Client nao tenta conectar e avisa o jogador no menu.

### Matchmaking Arriscado Para A Apresentacao

O estado atual comporta dois lobbies de quatro jogadores. Cada partida so inicia quando quatro pessoas escolhem o mesmo preset. Se o publico se dividir entre TDM e KOTH, os lobbies podem nao iniciar.

### Licencas Nao Registradas

Nao existe inventario consolidado de autor, origem e licenca para os audios e demais assets de terceiros. Nenhum arquivo sem origem comprovavel deve entrar na release final.

### Metricas Sem Experimento

Os CSVs existentes possuem apenas amostras com zero jogadores. A infraestrutura de coleta existe, mas ainda nao existe um conjunto de dados util, analise estatistica ou conclusao para o TCC.

### Texto Do TCC Desatualizado

`TCC.md` ainda e essencialmente a proposta do TCC1. Ele descreve P2P, hospedeiro, `MultiplayerSynchronizer`, CTF e outras funcionalidades que nao representam o produto atual. Tambem nao contem resultados e conclusao finais, nao possui bibliografia `.bib` no repositorio e referencia varias imagens por caminhos incorretos.

## Regra De Execucao

O trabalho deve seguir os gates abaixo em ordem. Nao iniciar o gate seguinte enquanto o criterio de saida do atual nao for cumprido.

Nao adicionar nova feature que nao esteja explicitamente neste plano. Bugs encontrados durante um gate devem ser corrigidos apenas quando bloquearem seu criterio de saida.

## Pendencias Pequenas Antes Da Limpeza Grande

As tarefas abaixo podem avancar em paralelo antes do refactor de build reproduzivel e da limpeza geral. A ordem esta organizada da menor para a maior dificuldade.

| Ordem | Dificuldade | Pendencia | Descricao Rapida | Pode Comecar Antes Da #119? |
| --- | --- | --- | --- | --- |
| 1 | Muito baixa | [#133 - Atualizar controles no relatorio](https://github.com/limaalan/TCC/issues/133) | Corrigir os vetores, a figura e a tabela do TCC para refletirem tres armas, granada, L3, Start/Menu e os bindings finais. | Sim; os arquivos do relatorio ficam fora do projeto Godot. |
| 2 | Baixa | Textos e foco basico da [#103](https://github.com/limaalan/TCC/issues/103) | Padronizar a interface em portugues, revisar `Voltar`, `ui_cancel` e o foco ao abrir/fechar telas. | Sim; e trabalho em cenas e scripts. |
| 3 | Baixa a media | [#132 - Tela Como jogar](https://github.com/limaalan/TCC/issues/132) | Criar dois cards responsivos, um para teclado/mouse e outro para gamepad, alem de resumos curtos de TDM e KOTH. | Parcialmente; a cena pode ser criada agora, mas os exports finais dependem de #63/#119. |
| 4 | Media | Estrutura de creditos da [#123](https://github.com/limaalan/TCC/issues/123) | Criar a tela e registrar autor, curso, tecnologias e espaco para atribuicoes de terceiros. | Sim para a estrutura; o conteudo final depende da auditoria. |
| 5 | Media | [#134 - Identidade final da release](https://github.com/limaalan/TCC/issues/134) | Definir nome final, titulo da janela, icone, splash e versao visivel. | Parcialmente; nome e icone raiz podem avancar, novos assets de runtime dependem de #63/#119. |
| 6 | Media | Capa, menu, pausa e 16:9 da [#103](https://github.com/limaalan/TCC/issues/103) | Aplicar capa, hierarquia visual e validar 720p/1080p com mouse, teclado e controle. | O layout pode avancar; a integracao da arte final deve esperar a politica de assets. |
| 7 | Media a alta | Auditoria de licencas e creditos da [#123](https://github.com/limaalan/TCC/issues/123) | Inventariar origem, autor e licenca de audio, HDR, fontes, modelos, texturas e icones. | Sim; e levantamento documental independente do refactor. |
| 8 | Alta | Paleta completa da [#121](https://github.com/limaalan/TCC/issues/121) | Centralizar e aplicar as cores em menu, HUD, times, pickups, powerups, mapas e VFX. | Pode iniciar como guia, mas a aplicacao completa atravessa muitos assets. |

### Decisao Para A Imagem De Controles

Nao reconstruir teclado, mouse e gamepad tecla por tecla usando dezenas de nos `Control`. Os arquivos vetoriais originais devem ser atualizados e exportados em duas imagens com fundo transparente:

- uma imagem para teclado e mouse;
- uma imagem para gamepad.

A UI da Godot deve montar somente os cards responsivos ao redor dessas imagens usando `Container`, `TextureRect`, titulos, textos auxiliares e botao de voltar. Isso preserva a qualidade visual dos vetores, reduz o tempo de implementacao e continua permitindo foco, navegacao por controle e adaptacao para 720p/1080p.

Novos exports dentro de `initial_project/Client/assets/` continuam ignorados pelo `.gitignore`. A integracao definitiva dessas imagens e da capa deve acontecer junto da solucao das issues #63 e #119, evitando assets que funcionam apenas na maquina local.

## Gate 0 - Fechar O Trabalho Em Andamento

### Trabalho

- Finalizar a arquitetura de muzzle FX por arma que esta parcialmente staged e parcialmente unstaged.
- Validar o efeito da pistola, SMG e shotgun.
- Confirmar que o efeito continua puramente visual e nao altera rede ou dano.
- Criar um commit isolado.
- Criar ou escolher a branch que recebera a release final.
- Congelar novas features.

### Criterio De Saida

- Working tree conhecido, sem implementacao pela metade.
- Muzzle FX das tres armas validado no jogo.
- Godot carrega Client e Server sem erro de parse.

### GitHub

- Issue: [#118 - Finalizar muzzle FX especifico por arma](https://github.com/limaalan/TCC/issues/118).

## Gate 1 - Tornar O Build Reproduzivel

### Trabalho

- Identificar os assets realmente usados pelo Highrise e pelo runtime final.
- Classificar os arquivos em `runtime`, `source` e `unused`.
- Versionar todo asset final necessario ao Client.
- Colocar arquivos Blender e fontes de autoria dentro de `source/` com `.gdignore`.
- Remover `.blend1`, logs e builds do escopo de export e versionamento.
- Parar de versionar o executavel do Server.
- Mover saidas de export para diretorios `build/` ignorados.
- Remover ou excluir do pacote mapas e assets antigos que nao pertencem a release.
- Rever `export_filter="all_resources"` para evitar empacotar conteudo antigo.
- Executar o setup dos links `shared` em um checkout limpo.
- Exportar Client e Server a partir desse checkout.

### Criterio De Saida

- Um clone limpo produz Client Windows e Server Linux sem recursos ausentes.
- Nenhum arquivo necessario depende apenas da maquina de desenvolvimento.
- Nenhum executavel ou log e adicionado ao Git.
- Tamanho do ZIP final conhecido e justificado.

### GitHub

- Executar [#63 - Garantir assets do Client no build final](https://github.com/limaalan/TCC/issues/63).
- Usar apenas a parte essencial de [#92 - Criar validacao de estrutura dos arquivos](https://github.com/limaalan/TCC/issues/92); a automacao completa pode esperar.
- Issue: [#119 - Higienizar artefatos de build e reduzir o pacote final](https://github.com/limaalan/TCC/issues/119).

## Gate 2 - Fechar A Conexao Publica

### Trabalho

- Adicionar campo de endereco e porta ao fluxo de conexao.
- Usar o IP de producao atual como default da release.
- Manter `127.0.0.1` disponivel para desenvolvimento.
- Persistir host e porta em `user://settings.cfg`.
- Criar o peer somente quando o jogador mandar conectar, ou recria-lo com seguranca.
- Permitir nova tentativa sem reiniciar o Client.
- Exibir estados de conexao, falha, desconexao, lobby cheio e espera por jogadores.
- Validar endereco vazio e intervalo da porta.

### Criterio De Saida

- Um usuario em outro computador baixa o ZIP e conecta ao servidor remoto sem editar arquivo e sem usar terminal.
- Uma falha de endereco pode ser corrigida dentro do jogo.

### GitHub

- Executar e ampliar [#74 - Criar tela simples de conexao por IP](https://github.com/limaalan/TCC/issues/74).
- Executar [#76 - Mostrar estado basico do servidor no Client](https://github.com/limaalan/TCC/issues/76).
- Atualizar a #74 para incluir persistencia, reconexao e default de producao; nao criar issue duplicada.

## Gate 3 - Criar O Perfil De Demonstracao Publica

### Trabalho

- Definir um perfil de execucao para a apresentacao.
- Comecar o teste com dois jogadores por lobby e quatro lobbies.
- Definir uma fila/preset principal para o publico, evitando fragmentar os jogadores.
- Manter TDM e KOTH disponiveis para demonstracao controlada.
- Tornar capacidade e quantidade de lobbies configuraveis por argumentos ou por um preset de deploy simples.
- Testar desconexao no lobby e durante a partida.
- Testar fim de partida, retorno ao menu e nova busca.
- Executar teste continuo de pelo menos 30 minutos.

### Criterio De Saida

- Dois usuarios que nao conhecem o projeto conseguem entrar e concluir uma partida.
- O servidor suporta a capacidade escolhida sem degradacao observavel.
- O publico recebe uma instrucao unica sobre qual fila selecionar.

### GitHub

- Reescrever [#75 - Permitir configurar partida por parametros do Server](https://github.com/limaalan/TCC/issues/75) para o estado atual: Highrise, presets atuais, quantidade de lobbies e jogadores por lobby.
- [#83 - Criar scripts batch para iniciar Server com presets](https://github.com/limaalan/TCC/issues/83) e opcional; o deploy real e Linux.
- Issue: [#120 - Criar perfil de servidor para demonstracao publica](https://github.com/limaalan/TCC/issues/120).

## Gate 4 - Adicionar Suporte A Controle

### Trabalho

- Mapear movimento no analogico esquerdo.
- Implementar camera no analogico direito com deadzone e sensibilidade.
- Mapear tiro, pulo, sprint, granada e pausa.
- Habilitar foco e navegacao de gamepad no menu, selecao de arma e pausa.
- Adicionar indicacao visual de foco.
- Adicionar acesso a tela `Como jogar` pelo menu principal e pela pausa.
- Testar uma partida completa com um controle fisico.

### Criterio De Saida

- O jogador consegue abrir o jogo, entrar em partida, jogar, pausar e sair sem teclado ou mouse.
- Mouse e teclado continuam funcionando.

### GitHub

- Executar [#77 - Adicionar suporte basico a controle/gamepad](https://github.com/limaalan/TCC/issues/77).
- Ampliar a #77 para incluir foco e navegacao real da UI; nao criar issue duplicada.
- Executar [#132 - Adicionar tela Como jogar com controles e objetivos dos modos](https://github.com/limaalan/TCC/issues/132).

## Gate 5 - Fechar A Identidade Visual

### Ordem Obrigatoria

1. Criar uma pagina de direcao visual com paleta e regras de uso.
2. Centralizar cores de times, interface, pickups, powerups e efeitos.
3. Corrigir estados e transicoes de animacao do personagem.
4. Repaginar a pistola.
5. Repaginar a SMG.
6. Aplicar o tema no menu, HUD, Highrise e VFX de maior destaque.
7. Padronizar nome, icone, splash, capa e versao da release.

### Escopo Da Paleta

A paleta deve definir, no minimo:

- cor de fundo/ceu;
- cor de superficie clara;
- cor estrutural escura;
- cor do time azul;
- cor do time coral/vermelho;
- cor de destaque/interacao;
- cor de dano/perigo;
- cor de powerup/energia.

Evitar espalhar novos valores hexadecimais em scripts e cenas. Preferir recursos de tema, materiais reutilizaveis e constantes centrais.

### Animacao

O fluxo atual mapeia caminhada e corrida para a mesma animacao `hover_walk`. O passe minimo deve diferenciar `idle`, `walk`, `run` e `air`, revisar blend e validar a aparencia de jogadores remotos.

### Criterio De Saida

- Menu, gameplay e tela de KOTH parecem pertencer ao mesmo jogo.
- Pistola e SMG possuem silhuetas distintas e usam a paleta.
- Jogador remoto nao apresenta transicoes visualmente quebradas nos estados basicos.
- Capa, titulo da janela, icone e pagina publica usam a mesma identidade.
- Existem tres screenshots finais aprovadas: menu, combate e KOTH.

### GitHub

- Reescrever [#106 - Modelar e animar personagem do jogador](https://github.com/limaalan/TCC/issues/106) para focar no polimento das animacoes finais, caso o modelo atual seja mantido.
- Executar/validar [#107 - Importar personagem e animacoes na Godot](https://github.com/limaalan/TCC/issues/107).
- Executar [#103 - Refatorar main menu e tela de pause](https://github.com/limaalan/TCC/issues/103) somente depois de definir a paleta.
- Aproveitar o escopo necessario de [#62 - Criar modelos 3D minimos](https://github.com/limaalan/TCC/issues/62), removendo dependencias de plataforma movel se ela continuar fora do recorte.
- [#105 - Melhorar cenario do mapa Highrise](https://github.com/limaalan/TCC/issues/105) e P1: fazer apenas se a leitura visual do mapa continuar fraca.
- Issue: [#121 - Definir e aplicar paleta de cores do jogo](https://github.com/limaalan/TCC/issues/121).
- Issue: [#122 - Repaginar modelos da pistola e SMG](https://github.com/limaalan/TCC/issues/122).
- Issue: [#134 - Aplicar identidade final da release no Client](https://github.com/limaalan/TCC/issues/134).

## Gate 6 - Substituir E Licenciar O Audio

### Trabalho

- Inventariar todos os audios atuais.
- Substituir qualquer arquivo sem origem comprovavel.
- Priorizar audio proprio ou CC0.
- Registrar titulo, autor, URL, licenca, data de acesso e alteracoes.
- Criar `THIRD_PARTY_NOTICES.md` ou documento equivalente.
- Registrar tambem HDRs, texturas, fontes e modelos de terceiros.
- Adicionar creditos na pagina de download e no jogo quando a licenca exigir.
- Testar volume, clipping, repeticao e espacializacao.

### Criterio De Saida

- Todo audio e asset de terceiro presente na release possui origem e licenca comprovavel.
- Nenhuma dependencia juridicamente desconhecida entra no ZIP final.

### GitHub

- Executar [#104 - Refatorar sonoplastia do jogo](https://github.com/limaalan/TCC/issues/104).
- [#48 - Limpar AudioManager para AudioEventData](https://github.com/limaalan/TCC/issues/48) nao bloqueia a licenca nem a release; adiar ou encerrar como `not planned` se o AudioLibrary atual for suficiente.
- Issue: [#123 - Auditar licencas de assets e criar THIRD_PARTY_NOTICES](https://github.com/limaalan/TCC/issues/123).

## Gate 7 - Gerar A Release Candidate

### Trabalho

- Fazer apenas limpeza dirigida por evidencia de uso.
- Atualizar os documentos tecnicos para refletir Highrise, TDM, KOTH, municao, powerups, export e metricas atuais.
- Consolidar arquitetura, funcionalidades, deploy, testes, metricas e licencas.
- Rodar smoke test local e remoto.
- Gerar ZIP portatil do Client Windows.
- Criar pagina no itch.io com screenshots, controles, IP/porta e instrucoes.
- Criar GitHub Release como espelho.
- Testar download, extracao e execucao em outro computador.
- Criar QR code para a pagina de download.

### Criterio De Saida

- Release `v0.9-rc1` publicada e jogavel por um terceiro.
- Link e QR code testados fora da maquina de desenvolvimento.
- Build local de backup preservado.

### GitHub

- Reescrever [#31 - Rodar smoke test em 2 mapas e 2 modos](https://github.com/limaalan/TCC/issues/31) para `Highrise em 2 modos`, evitando manter dois mapas so para cumprir uma issue antiga.
- Atualizar [#65 - Rodar smoke test final](https://github.com/limaalan/TCC/issues/65): powerups ja existem e plataforma movel nao deve bloquear a release.
- Encerrar [#64 - Atualizar prototype map](https://github.com/limaalan/TCC/issues/64) como `not planned` se Highrise for confirmado como mapa final.
- Verificar os criterios e encerrar [#91 - Criar mapa KOTH](https://github.com/limaalan/TCC/issues/91) se o Highrise atual ja os cumprir.
- Issue: [#124 - Publicar Client Windows e pagina de download da apresentacao](https://github.com/limaalan/TCC/issues/124).
- Issue: [#126 - Consolidar documentacao tecnica da release final](https://github.com/limaalan/TCC/issues/126).

## Gate 8 - Executar E Analisar O Experimento

### Protocolo Minimo

- Mesmo commit, mapa, modo e configuracao de servidor em todas as rodadas.
- Cenarios de 2, 4, 6 e 8 jogadores.
- Cenarios de 1, 2, 3 e 4 lobbies, conforme o perfil de dois jogadores por lobby.
- Tres repeticoes por cenario.
- Cinco minutos uteis por repeticao.
- Descartar o primeiro minuto como aquecimento.
- Identificar arquivos com labels como `p2_l1_r1`.
- Registrar regiao, tipo de conexao e observacoes de cada participante.

### Metricas

- mediana e p95 de RTT;
- variacao de RTT;
- perda media e maxima de pacotes;
- KiB/s enviados e recebidos;
- pacotes/s enviados e recebidos;
- tempo de fisica maximo e somado;
- FPS dos clientes;
- CPU e memoria do processo do servidor.

A dashboard ja observa CPU e memoria por `psutil`, mas esses valores precisam ser persistidos ou coletados de outra fonte alinhada ao horario das amostras.

### Resultados Minimos

- Tabela resumida por cenario.
- Grafico jogadores x trafego.
- Grafico jogadores/lobbies x custo de fisica.
- Grafico jogadores x RTT/perda.
- Discussao das limitacoes do teste com amigos em redes diferentes.

### Criterio De Saida

- CSVs de todas as rodadas preservados.
- Script ou planilha de analise reproduzivel.
- Graficos prontos para o relatorio e os slides.
- Conclusao limitada ao comportamento observado ate oito jogadores.

### GitHub

- [#102 - Adicionar coleta de metricas](https://github.com/limaalan/TCC/issues/102) parece implementada; validar e encerrar a issue.
- Issue: [#125 - Executar experimento e analisar metricas com aumento de jogadores e lobbies](https://github.com/limaalan/TCC/issues/125).

## Gate 9 - Escrever O Relatorio Final

### Estrutura Recomendada

1. Introducao e objetivos revisados.
2. Conceitos e produtos similares.
3. Materiais e metodos no passado.
4. Arquitetura cliente/servidor autoritativa.
5. Implementacao das funcionalidades.
6. Processo artistico e audiovisual.
7. Metodo do experimento.
8. Resultados e discussao.
9. Limitacoes e desvios da proposta.
10. Conclusao e trabalhos futuros.

### Desvios Que Devem Ser Explicados

- P2P foi substituido por servidor dedicado autoritativo.
- `MultiplayerSynchronizer` foi substituido por RPCs, snapshots e interpolacao.
- CTF foi substituido por KOTH.
- O conjunto final de armas mudou.
- Algumas plataformas e regras foram retiradas para priorizar rede, estabilidade e deploy.
- Web foi mantido como trabalho futuro por exigir outro transporte de rede.

### Evidencias A Produzir

- diagrama da arquitetura final;
- fluxo Client/Server/lobby;
- screenshots do menu, gameplay e KOTH;
- figura e tabela atualizadas dos controles finais;
- tabela proposta x resultado;
- tabela de testes;
- tabela e graficos das metricas;
- descricao do deploy em VPS;
- lista de licencas e creditos.

### Criterio De Saida

- PDF compila sem referencias ou imagens quebradas.
- Resultados e conclusao se apoiam em evidencias produzidas pela release final.
- O texto nao afirma que funcionalidades cortadas foram implementadas.

### GitHub

- Ampliar e executar [#99 - Escrita do relatorio](https://github.com/limaalan/TCC/issues/99); nao criar issue duplicada.
- Executar [#133 - Atualizar secao de controles do relatorio para a build final](https://github.com/limaalan/TCC/issues/133) como recorte verificavel da #99.

## Gate 10 - Preparar A Apresentacao E Os Planos De Contingencia

### Trabalho

- Gravar video curto de uma partida funcional.
- Manter Server e Client locais prontos como plano B.
- Levar ZIP em pendrive.
- Preparar hotspot/segunda conexao.
- Salvar comando de restart do servidor.
- Deixar dashboard e servidor abertos antes da apresentacao.
- Preaquecer uma partida com jogadores conhecidos.
- Testar o QR code na rede do local.
- Congelar codigo pelo menos 24 horas antes da apresentacao.

### Criterio De Saida

- A demonstracao principal, o download publico e pelo menos dois planos de contingencia foram ensaiados.
- A apresentacao nao depende de fazer deploy ou build ao vivo.

### GitHub

- [#116 - Criar GitHub Actions para deploy do Server](https://github.com/limaalan/TCC/issues/116) e melhoria posterior; nao deve bloquear um deploy manual ja funcional.
- Issue: [#127 - Preparar kit de apresentacao e planos de contingencia](https://github.com/limaalan/TCC/issues/127).

## Cruzamento Completo Com As Issues Abertas

| Issue | Situacao Recomendada | Acao |
| --- | --- | --- |
| [#31](https://github.com/limaalan/TCC/issues/31) Smoke test 2 mapas/2 modos | Escopo antigo | Reescrever para Highrise em TDM e KOTH |
| [#48](https://github.com/limaalan/TCC/issues/48) AudioEventData | Nao bloqueia entrega | Adiar ou encerrar como `not planned` |
| [#61](https://github.com/limaalan/TCC/issues/61) Plataforma movel | Fora do recorte minimo | Adiar ou encerrar como `not planned` |
| [#62](https://github.com/limaalan/TCC/issues/62) Modelos 3D minimos | Parcialmente util | Reduzir a assets realmente usados na release |
| [#63](https://github.com/limaalan/TCC/issues/63) Assets no build | Bloqueador P0 | Executar no Gate 1 |
| [#64](https://github.com/limaalan/TCC/issues/64) Prototype final | Conflita com Highrise final | Encerrar se Highrise for confirmado |
| [#65](https://github.com/limaalan/TCC/issues/65) Smoke final | Bloqueador P0 | Atualizar criterios e executar no Gate 7 |
| [#74](https://github.com/limaalan/TCC/issues/74) Conexao por IP | Bloqueador P0 | Ampliar e executar no Gate 2 |
| [#75](https://github.com/limaalan/TCC/issues/75) Parametros do Server | Desatualizada | Reescrever para Highrise e perfil de demonstracao |
| [#76](https://github.com/limaalan/TCC/issues/76) Estado da conexao | Bloqueador P0 | Executar no Gate 2 |
| [#77](https://github.com/limaalan/TCC/issues/77) Gamepad | Compromisso do TCC | Ampliar UI e executar no Gate 4 |
| [#83](https://github.com/limaalan/TCC/issues/83) Scripts batch | Opcional | Adiar; producao usa Linux |
| [#91](https://github.com/limaalan/TCC/issues/91) Mapa KOTH | Provavelmente implementada | Validar Highrise e encerrar |
| [#92](https://github.com/limaalan/TCC/issues/92) Validador de paths | Automacao nao essencial | Usar checklist manual agora e adiar ferramenta |
| [#99](https://github.com/limaalan/TCC/issues/99) Relatorio | Bloqueador academico | Detalhar e executar no Gate 9 |
| [#100](https://github.com/limaalan/TCC/issues/100) Selecao de modo | Implementada no codigo atual | Validar e encerrar |
| [#102](https://github.com/limaalan/TCC/issues/102) Coleta de metricas | Implementada no codigo atual | Validar coleta e encerrar; criar issue de experimento |
| [#103](https://github.com/limaalan/TCC/issues/103) Menu e pausa | Parte do polimento | Executar depois da paleta |
| [#104](https://github.com/limaalan/TCC/issues/104) Sonoplastia | Bloqueador de licenca | Executar no Gate 6 |
| [#105](https://github.com/limaalan/TCC/issues/105) Cenario Highrise | Implementada em feature branch | Validar, integrar e encerrar; a #130 foi fechada como duplicada |
| [#106](https://github.com/limaalan/TCC/issues/106) Modelo/animacao | Parcialmente implementada | Reescrever para polimento das animacoes finais |
| [#107](https://github.com/limaalan/TCC/issues/107) Importar animacoes | Parcialmente implementada | Validar integracao e encerrar |
| [#108](https://github.com/limaalan/TCC/issues/108) Expressoes faciais | Fora do recorte | Encerrar como `not planned` |
| [#116](https://github.com/limaalan/TCC/issues/116) Actions deploy Server | Melhoria posterior | Adiar ate o deploy manual estar fechado |
| [#132](https://github.com/limaalan/TCC/issues/132) Tela Como jogar | Polimento funcional pequeno | Executar com dois cards e exports vetoriais transparentes |
| [#133](https://github.com/limaalan/TCC/issues/133) Controles no relatorio | Pendencia academica pequena | Executar em paralelo e vincular a #99 |
| [#134](https://github.com/limaalan/TCC/issues/134) Identidade da release | Polimento de apresentacao | Definir nome, icone, splash e versao antes da release publica |

## Issues Criadas Para O Fechamento

As issues abaixo foram criadas no GitHub e vinculadas ao milestone 9, referente ao fechamento e a entrega do TCC.

### [#118 - Finalizar Muzzle FX Especifico Por Arma](https://github.com/limaalan/TCC/issues/118)

**Prioridade:** P0

**Objetivo:** concluir o trabalho em andamento e garantir que cada arma usa seu efeito visual sem alterar gameplay ou rede.

**Criterios:** pistola, SMG e shotgun validadas; nenhuma cena faltando; smoke test do Client aprovado.

### [#119 - Higienizar Artefatos De Build E Reduzir O Pacote Final](https://github.com/limaalan/TCC/issues/119)

**Prioridade:** P0

**Objetivo:** remover executaveis/logs do versionamento, centralizar exports em `build/`, excluir conteudo antigo e reduzir o ZIP.

**Criterios:** Git limpo de artefatos, export reproduzivel e tamanho final documentado.

### [#120 - Criar Perfil De Servidor Para Demonstracao Publica](https://github.com/limaalan/TCC/issues/120)

**Prioridade:** P0

**Objetivo:** configurar quantidade de lobbies, jogadores por lobby e preset principal sem editar codigo no dia.

**Criterios:** perfil inicia por comando conhecido, suporta a capacidade definida e foi testado por 30 minutos.

### [#121 - Definir E Aplicar Paleta De Cores Do Jogo](https://github.com/limaalan/TCC/issues/121)

**Prioridade:** P1

**Objetivo:** criar uma direcao visual unica e aplicar as cores por recursos reutilizaveis em UI, times, pickups, mapa e efeitos.

**Criterios:** guia de paleta versionado e tres screenshots visualmente coerentes.

### [#122 - Repaginar Modelos Da Pistola E SMG](https://github.com/limaalan/TCC/issues/122)

**Prioridade:** P1

**Objetivo:** substituir ou revisar os dois modelos usando a paleta e silhuetas claramente distintas.

**Criterios:** modelos importados, escala/pivo corretos, muzzle alinhado e leitura boa em primeira pessoa.

### [#123 - Auditar Licencas De Assets E Criar THIRD_PARTY_NOTICES](https://github.com/limaalan/TCC/issues/123)

**Prioridade:** P0

**Objetivo:** registrar autoria e licenca de audio, modelos, texturas, fontes e HDRs usados pela release.

**Criterios:** nenhum asset sem origem, creditos incluidos e arquivos incompativeis substituidos.

### [#124 - Publicar Client Windows E Pagina De Download](https://github.com/limaalan/TCC/issues/124)

**Prioridade:** P0

**Objetivo:** disponibilizar um ZIP testado no itch.io e em GitHub Release.

**Criterios:** download por terceiro, instrucoes completas, QR code testado e backup local.

### [#125 - Executar Experimento E Analisar Metricas](https://github.com/limaalan/TCC/issues/125)

**Prioridade:** P0 academico

**Objetivo:** executar rodadas controladas com aumento de jogadores/lobbies e gerar tabela, graficos e discussao.

**Criterios:** dados brutos preservados, analise reproduzivel e resultados inseriveis no TCC.

### [#126 - Consolidar Documentacao Tecnica Da Release Final](https://github.com/limaalan/TCC/issues/126)

**Prioridade:** P1

**Objetivo:** eliminar contradicoes dos documentos antigos e manter arquitetura, features, deploy, testes, metricas e licencas como fontes atuais.

**Criterios:** documentos refletem Highrise, dois modos, servidor autoritativo, municao, powerups e deploy real.

### [#127 - Preparar Kit De Apresentacao E Planos De Contingencia](https://github.com/limaalan/TCC/issues/127)

**Prioridade:** P0 de apresentacao

**Objetivo:** reunir video, ZIP, QR code, comandos, builds locais e alternativas de rede.

**Criterios:** ensaio completo realizado e demonstracao recuperavel sem build/deploy ao vivo.

### [#132 - Adicionar Tela Como Jogar Com Controles E Objetivos](https://github.com/limaalan/TCC/issues/132)

**Prioridade:** P1 pequeno

**Objetivo:** disponibilizar no menu e na pausa dois cards de controles, mais uma explicacao curta de TDM e KOTH.

**Criterios:** imagens transparentes atualizadas, navegacao completa por controle e leitura correta em 720p/1080p.

### [#133 - Atualizar Secao De Controles Do Relatorio](https://github.com/limaalan/TCC/issues/133)

**Prioridade:** P0 academico pequeno

**Objetivo:** atualizar figura e tabela do TCC para os bindings realmente entregues.

**Criterios:** figura, tabela e `Input Map` sem contradicoes; PDF compilando com a nova imagem.

### [#134 - Aplicar Identidade Final Da Release No Client](https://github.com/limaalan/TCC/issues/134)

**Prioridade:** P1 de apresentacao

**Objetivo:** unificar nome, titulo da janela, icone, splash, capa, versao e pagina publica.

**Criterios:** nenhum nome conflitante ou icone generico na build distribuida.

## Ordem Linear Resumida

1. #118 - terminar muzzle FX e congelar features.
2. #63 + #119 - garantir clone limpo e build reproduzivel.
3. #74 + #76 - fechar IP, reconexao e mensagens.
4. #75 revisada + #120 - fechar perfil da demonstracao.
5. #77 + #132 - suporte completo a controle e tela Como jogar.
6. #133 - atualizar cedo as figuras e a tabela de controles do relatorio.
7. #121 + #106/#107 + #122 + #103 + #134 - fechar passe artistico e identidade da release.
8. #104 + #123 - substituir audio e documentar licencas.
9. #65 revisada + #124 + #126 - release candidate e pagina publica.
10. #102 validada + #125 - experimento e analise.
11. #99 - relatorio final.
12. #127 - ensaio, congelamento e apresentacao.

## Definicao Final De Pronto

O projeto esta pronto para entrega quando:

- um clone limpo gera os dois builds;
- um terceiro baixa o Client e conecta ao servidor remoto sem ajuda tecnica;
- TDM e KOTH terminam corretamente em build exportado;
- o jogo pode ser usado por teclado/mouse e controle;
- existe uma tela Como jogar coerente com os bindings e uma secao atualizada no relatorio;
- nome, icone, splash, capa e versao identificam a mesma release;
- arte e audio da release possuem identidade e licencas conhecidas;
- existe uma release publica com QR code;
- o experimento de metricas possui dados, graficos e conclusao;
- o relatorio descreve a implementacao real;
- a apresentacao foi ensaiada com planos de contingencia.
