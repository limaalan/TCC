# Plano De Testes E Deploy Via Godot CLI

## Objetivo

Este documento define os próximos passos para testar e publicar o jogo usando Godot pela linha de comando, com foco em hospedar o servidor em qualquer máquina Linux/VPS e conectar clientes externos.

O objetivo prático é chegar em um fluxo onde o servidor rode sem editor, sem janela e sem interação manual, por exemplo:

```bash
./shrooter-server.x86_64 --headless -- --port 7777 --players-per-lobby 2
```

E o cliente consiga escolher o IP do servidor, por exemplo:

```bash
./shrooter-client.x86_64 -- --server-address 203.0.113.10 --server-port 7777
```

## Estado Atual Relevante

| Área | Estado atual | Impacto para teste/deploy |
| --- | --- | --- |
| Projetos Godot | Existem dois projetos separados: `initial_project/Server` e `initial_project/Client` | Exportar e rodar cada um separadamente |
| Server startup | `Server/server/server.gd` inicia `ENetMultiplayerPeer` no `_ready()` | Deve funcionar em CLI/headless desde que Godot esteja instalado |
| Porta | `PORT := 7777` hardcoded no Server e no Client | Precisa virar argumento/env para hosting real |
| Endereço do cliente | `Client/server/server.gd` usa `ADDRESS := "127.0.0.1"` | Hoje o cliente só conecta localmente |
| Lobby | `MAX_LOBBIES := 1`, `MAX_PLAYERS_PER_LOBBY := 2` | Bom para teste básico, limitado para deploy público |
| Matchmaking | Quick play com status, cancelamento e bloqueio quando completa 2 jogadores | Fluxo já é testável com dois clientes |
| Gameplay | Team deathmatch, weapon selection, pistol/SMG/shotgun, tiros server-authoritative, lag compensation, pickups, granadas, placar, timer e tela final | Checklist manual precisa cobrir o ciclo inteiro da partida |
| Client assets | `initial_project/Client/assets` existe localmente, mas é ignorado pelo `.gitignore` | Builds em outra máquina podem falhar se os assets não forem empacotados/fornecidos |
| Export presets | Não há `export_presets.cfg` em Client nem Server | Não dá para exportar via CLI ainda sem criar presets |
| Godot no PATH | `godot --version` não funcionou neste shell | Antes de automatizar, instalar Godot 4.5 CLI/headless e export templates |

## Pré-Requisitos Para CLI

| Item | Por que precisa | Como validar |
| --- | --- | --- |
| Godot 4.5 instalado | Os projetos usam Godot 4.5 | `godot --version` deve retornar `4.5...` |
| Godot no `PATH` | Scripts de build/test precisam chamar `godot` diretamente | Rodar `godot --help` em um terminal novo |
| Export templates instalados | Necessário para `--export-release` | No editor: Editor > Manage Export Templates |
| Presets de exportação | CLI precisa de nomes de presets | Criar `export_presets.cfg` em Client e Server |
| Porta UDP aberta | ENet usa UDP | Liberar UDP `7777` no firewall e no provedor cloud |
| Assets do Client disponíveis | O mapa referencia meshes, materiais, texturas e áudio em `Client/assets` | Confirmar que export client inclui esses arquivos |

## Primeiro Teste Local Via CLI

Com Godot disponível no `PATH`, o teste local mínimo deve ser:

```bash
godot --headless --path initial_project/Server
```

Em outro terminal:

```bash
godot --path initial_project/Client --user-data-dir .tmp/client_1
```

Em outro terminal:

```bash
godot --path initial_project/Client --user-data-dir .tmp/client_2
```

Observações:

- O server deve imprimir `Servidor iniciado.`.
- Cada client deve imprimir `conectou-se ao servidor` ao conectar.
- `--user-data-dir` evita conflito no `user://settings.cfg` entre duas instâncias locais.
- O cliente ainda usa `127.0.0.1`, então este teste só cobre servidor local até o endereço ser configurável.

## Checklist Manual De Smoke Test

Rodar este checklist em toda build candidata.

| Passo | Ação | Resultado esperado |
| --- | --- | --- |
| 1 | Iniciar Server via CLI/headless | Server inicia sem erro e fica rodando |
| 2 | Iniciar Client 1 | Client conecta ao server e menu aparece |
| 3 | Iniciar Client 2 | Client conecta ao server e menu aparece |
| 4 | Escolher nomes diferentes | Nome é salvo em `profile/player_name` no `user://settings.cfg` de cada user dir |
| 5 | Client 1 clica Play | Quick play mostra busca `1/2` |
| 6 | Client 2 clica Play | Lobby fica locked e inicia carregamento |
| 7 | Ambos carregam mapa | Client troca para o mapa farm e toca música de batalha |
| 8 | Ambos escolhem arma | Pistol, SMG e shotgun instanciam corretamente |
| 9 | Match começa | Jogadores descongelam e HUD mostra placar/timer |
| 10 | Movimentar, pular e sprintar | Movimento local responde e remoto interpola sem travar |
| 11 | Atirar em parede/chão | SFX, muzzle flash e hit FX aparecem |
| 12 | Atirar no inimigo | Dano replica, health bar atualiza e camera shake local acontece |
| 13 | Usar pickup de vida | Cura apenas se faltando vida, pickup entra em cooldown e volta |
| 14 | Usar pickup de granada | Granada aumenta no HUD, SFX toca e cooldown replica |
| 15 | Jogar granada | Contador diminui, granada aparece nos dois clients e explode |
| 16 | Matar jogador | Morte remove player, texto de eliminação aparece e score atualiza |
| 17 | Respawn após cooldown | Weapon selection reaparece para o jogador morto |
| 18 | Chegar no score limite | Tela final abre com nomes, kills, deaths e times |
| 19 | Client sai pelo pause | Server remove player e encerra/lida com lobby vazio sem crash |
| 20 | Server fica rodando após match | Processo não fecha inesperadamente e aceita novo lobby se configurado |

## Próximos Passos Obrigatórios Para Hosting Real

### 1. Tornar Rede Configurável

Hoje a rede está hardcoded:

- Server: `initial_project/Server/server/server.gd` usa `PORT := 7777`.
- Client: `initial_project/Client/server/server.gd` usa `ADDRESS := "127.0.0.1"` e `PORT := 7777`.

Criar um `NetworkConfig.gd` nos dois projetos, ou em `shared_src` se a sincronização de scripts compartilhados for criada.

Campos mínimos:

```gdscript
class_name NetworkConfig
extends RefCounted

const DEFAULT_PORT := 7777
const DEFAULT_ADDRESS := "127.0.0.1"

static func get_arg_value(name: String, default_value: String) -> String:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == name and i + 1 < args.size():
			return args[i + 1]
	return default_value
```

Uso esperado no Client:

```gdscript
var address := NetworkConfig.get_arg_value("--server-address", NetworkConfig.DEFAULT_ADDRESS)
var port := NetworkConfig.get_arg_value("--server-port", str(NetworkConfig.DEFAULT_PORT)).to_int()
peer.create_client(address, port)
```

Uso esperado no Server:

```gdscript
var port := NetworkConfig.get_arg_value("--port", str(NetworkConfig.DEFAULT_PORT)).to_int()
peer.create_server(port, max_clients)
```

Com isso, os comandos passam a ser:

```bash
godot --headless --path initial_project/Server -- --port 7777
```

```bash
godot --path initial_project/Client -- --server-address 127.0.0.1 --server-port 7777
```

### 2. Criar Presets De Exportação

Criar `export_presets.cfg` nos dois projetos pelo editor Godot.

Presets recomendados:

| Projeto | Preset | Plataforma | Observação |
| --- | --- | --- | --- |
| Server | `Linux Server` | Linux x86_64 | Exportar para VPS; rodar com `--headless` |
| Client | `Windows Client` | Windows x86_64 | Build principal para teste local |
| Client | `Linux Client` | Linux x86_64 | Útil para testar client no mesmo ambiente do server |

Evitar Web neste momento: o multiplayer atual usa ENet/UDP, e export web normalmente exigiria outra camada como WebSocket/WebRTC.

CLI esperado depois dos presets:

```bash
godot --headless --path initial_project/Server --export-release "Linux Server" build/server/shrooter-server.x86_64
```

```bash
godot --headless --path initial_project/Client --export-release "Windows Client" build/client/windows/ShrooterClient.exe
```

```bash
godot --headless --path initial_project/Client --export-release "Linux Client" build/client/linux/shrooter-client.x86_64
```

### 3. Garantir Que Assets Entram No Build

O diretório `initial_project/Client/assets` é ignorado pelo `.gitignore`. Isso é perigoso para deploy em outra máquina.

Escolher uma das opções:

| Opção | Quando usar | Ação |
| --- | --- | --- |
| Versionar assets finais | Melhor para TCC e builds reproduzíveis | Remover ou ajustar a regra que ignora `initial_project/Client/assets` |
| Pacote externo de assets | Se os assets forem muito pesados/licenciados | Documentar download e checksum antes do export |
| Asset pack privado | Se não puder publicar os arquivos | Criar etapa manual antes do build |

Critério de pronto:

- Um clone limpo do repositório consegue abrir o Client sem recursos faltando.
- O export do Client contém meshes, texturas, materiais, áudio e ícones usados por `map_farm.tscn`.

### 4. Adicionar Logs E Exit Codes

Para hospedagem real, o server precisa ser fácil de diagnosticar sem editor.

Adicionar logs para:

- Porta e configuração inicial usada.
- Cliente conectado/desconectado.
- Lobby criado, atualizado, locked, iniciado e deletado.
- Erro ao criar servidor ENet.
- Match iniciado/finalizado.

Critério de pronto:

- Se `peer.create_server()` falhar, o processo deve chamar `get_tree().quit(1)`.
- Em boot bem-sucedido, logar `Server listening on UDP port 7777`.
- Logs devem ser estáveis o suficiente para `journalctl`, Docker logs ou arquivo texto.

### 5. Adicionar Modo De Smoke Test Automatizado

Hoje o teste completo exige dois clients humanos. Para deploy contínuo, adicionar um modo mínimo de teste automatizado.

Opções práticas:

| Opção | Benefício | Complexidade |
| --- | --- | --- |
| `--smoke-test-server` no Server | Valida boot, mapa e lobby sem cliente | Baixa |
| Client bot headless | Testa conexão, lobby e RPCs básicos | Média |
| Dois bot clients headless | Testa ciclo completo até início da partida | Média/alta |
| Teste Godot com script externo | Bom para CI | Média |

Primeira meta recomendada:

```bash
godot --headless --path initial_project/Server -- --smoke-test-server
```

Esse modo deve:

1. Iniciar ENet.
2. Instanciar o mapa server-side.
3. Validar que existem `SpawnPoints` e `Pickups`.
4. Fechar com exit code `0` se tudo estiver válido.
5. Fechar com exit code `1` se faltar cena, spawn, pickup ou porta.

## Deploy Em VPS Linux

Fluxo recomendado depois de exportar o servidor:

```bash
mkdir -p /opt/shrooter/server
cp shrooter-server.x86_64 /opt/shrooter/server/
chmod +x /opt/shrooter/server/shrooter-server.x86_64
sudo ufw allow 7777/udp
```

Teste manual no VPS:

```bash
/opt/shrooter/server/shrooter-server.x86_64 --headless -- --port 7777
```

Depois, rodar como serviço systemd.

Exemplo de unit file:

```ini
[Unit]
Description=Shrooter Godot Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/shrooter/server
ExecStart=/opt/shrooter/server/shrooter-server.x86_64 --headless -- --port 7777 --players-per-lobby 2
Restart=on-failure
RestartSec=3
User=shrooter
Group=shrooter

[Install]
WantedBy=multi-user.target
```

Comandos:

```bash
sudo systemctl daemon-reload
sudo systemctl enable shrooter-server
sudo systemctl start shrooter-server
sudo journalctl -u shrooter-server -f
```

## Deploy Em Docker

Docker é opcional. Para TCC e VPS simples, systemd é mais direto. Docker passa a valer se quiser CI/CD ou múltiplas instâncias.

Dockerfile mínimo esperado depois de exportar:

```dockerfile
FROM debian:bookworm-slim
WORKDIR /app
COPY shrooter-server.x86_64 /app/shrooter-server.x86_64
RUN chmod +x /app/shrooter-server.x86_64
EXPOSE 7777/udp
CMD ["/app/shrooter-server.x86_64", "--headless", "--", "--port", "7777"]
```

Build/run:

```bash
docker build -t shrooter-server .
docker run --rm -p 7777:7777/udp shrooter-server
```

## Checklist De Release

| Item | Status esperado |
| --- | --- |
| Godot 4.5 CLI instalado em máquina de build | Obrigatório |
| Export templates instalados | Obrigatório |
| `export_presets.cfg` criado para Client e Server | Obrigatório |
| Server aceita `--port` | Obrigatório |
| Client aceita `--server-address` e `--server-port` | Obrigatório |
| Assets do Client são reproduzíveis em clone limpo | Obrigatório |
| Server roda com `--headless` por 30 minutos sem crash | Obrigatório |
| Dois clients externos conectam no VPS | Obrigatório |
| UDP 7777 aberto no firewall local e cloud | Obrigatório |
| Logs do server são legíveis via terminal/service logs | Obrigatório |
| Match completo testado: lobby, mapa, arma, kill, respawn, final | Obrigatório |
| Client mostra mensagem clara se não conectar | Recomendado |
| Build versionado com data/commit hash no log | Recomendado |

## Matriz De Teste Recomendada

| Ambiente | Server | Client 1 | Client 2 | Objetivo |
| --- | --- | --- | --- | --- |
| Local dev | Editor ou CLI local | Editor | Editor | Debug rápido |
| Local CLI | `godot --headless --path Server` | `godot --path Client` | `godot --path Client` | Validar CLI sem export |
| Local export | Executável server local | Executável client | Executável client | Validar presets/export |
| VPS LAN/WAN | Executável server no VPS | Client local | Client local | Validar IP público e firewall |
| VPS mixed OS | Linux server | Windows client | Linux/Windows client | Validar release real |

## Riscos Que Ainda Precisam Ser Controlados

| Risco | Sintoma | Mitigação |
| --- | --- | --- |
| Client continua hardcoded em `127.0.0.1` | Ninguém conecta ao VPS | Implementar `--server-address` e campo de IP no menu |
| Export sem assets | Mapa abre com recursos faltando | Versionar assets ou criar etapa de sync antes do export |
| Porta bloqueada | Client falha ao conectar | Liberar UDP no firewall do OS e no provedor cloud |
| Server crasha sem tela | Processo morre silenciosamente | Logs, exit codes e systemd restart |
| Dois players obrigatórios | Um usuário sozinho fica preso no quick play | Manter claro no menu ou criar modo debug com bot |
| Uma sala apenas | Terceiro/quarto jogador não entra | Expor `MAX_LOBBIES` e `MAX_PLAYERS_PER_LOBBY` por config |
| Payloads sem validação | Client modificado pode quebrar server | Priorizar refactors P0 do `05_plano_de_refatoracao.md` |

## Ordem Recomendada Dos Próximos Commits

1. Adicionar parsing de argumentos de CLI para Server e Client.
2. Adicionar logs e exit code no boot do Server.
3. Criar export presets para Linux Server, Windows Client e Linux Client.
4. Decidir e corrigir a estratégia de versionamento de `Client/assets`.
5. Validar `godot --headless --path initial_project/Server` localmente.
6. Exportar Server e Client via CLI.
7. Rodar server exportado localmente e conectar dois clients exportados.
8. Subir server exportado em VPS com UDP 7777 aberto.
9. Conectar dois clients externos usando `--server-address`.
10. Criar smoke test automatizado mínimo para boot/mapa/lobby.

## Resultado Esperado

Quando estes passos estiverem completos, o projeto terá um caminho repetível para:

1. Rodar server local por CLI.
2. Rodar server headless em VPS.
3. Exportar builds sem abrir o editor.
4. Testar uma partida completa com dois clients.
5. Diagnosticar problemas por logs em vez de depender do editor.
