# Build local de Client e Server

O mesmo processo pode ser chamado localmente e futuramente pelo GitHub Actions.
Nesta etapa não há workflow, publicação, assinatura ou acesso à VPS.

## Pré-requisitos

- Ubuntu/WSL2 com Docker Engine e `docker compose` funcionando.
- Docker Linux x86_64. No Windows, Python 3.11+ para testar os executáveis Windows.
- Execute os comandos Docker **dentro do terminal WSL**, na raiz do repositório.
- Mantenha esse terminal WSL aberto durante os testes com executáveis Windows.
- Não precisa de Godot ou Blender instalados no host para gerar as builds.

O builder fixa Godot **4.5.1 standard**, templates oficiais com SHA-256 e imagens-base
por digest. Na primeira construção baixa aproximadamente 1,4 GB de templates;
só os templates Windows/Linux release necessários ficam na imagem. Pacotes do
sistema vêm dos repositórios Debian: não se promete identidade byte a byte.

## Gerar as quatro builds

```bash
docker compose --profile tools build build
docker compose --profile tools run --rm build
```

Saída: `build/releases/local/`, com `client-windows`, `client-linux`,
`server-windows`, `server-linux`, quatro ZIP/tar.gz, `BUILD.json` e `SHA256SUMS`.
Cada pacote inclui instruções e todos os arquivos produzidos pelo preset.

O script único é `scripts/build_release.py`, chamado por `scripts/build.sh`.
Ele copia os projetos para workspace temporário sem `.godot`, materializa
`initial_project/shared` em cada projeto e importa cada projeto separadamente.
Mantém os `.blend`, mas ambos os projetos desabilitam sua importação. Os presets
Server usam `dedicated_server` e `Strip Visuals`; a build Linux confirma que uma
textura virou `PlaceholderTexture2D` antes de publicar o diretório de release.

Erros de importação/exportação falham a build mesmo se o Godot retornar código zero.
O manifesto registra commit, alterações locais, versão da engine e alvos. Os logs
ficam em `build/releases/local.logs/`, inclusive quando a build falha.

Releases existentes **não são sobrescritas**. Para repetir em saída limpa:

```bash
export BUILD_VERSION=local-2
docker compose --profile tools run --rm build
```

Mantenha `BUILD_VERSION` definido nos comandos seguintes para usar a mesma versão.
Para diagnóstico, selecione alvos sem criar um processo de exportação paralelo:

```bash
docker compose --profile tools run --rm build \
  --source /source --output /output --version client-check --targets client-windows
```

## Subir o servidor Linux no Docker

```bash
docker compose build server
docker compose up -d server
docker compose logs --tail 30 server
docker compose --profile tools run --rm smoke
```

Por padrão publica somente `127.0.0.1:7777/udp` no host Linux. O runtime copia
o executável da release selecionada, sem exportar de novo. Roda como usuário sem
privilégios, filesystem somente leitura e áreas temporárias para dados/cache.
Os logs são descarregados imediatamente para stdout.

O smoke tem timeout e faz handshake ENet: não considera apenas processo/porta abertos.
O builder precisa existir antes de rodar `smoke` e `test`.

## Conectar um cliente Windows ao Docker no WSL

Se `localhost` não funcionar para UDP entre Windows e WSL em modo NAT, use a
interface privada do WSL. No **terminal WSL**:

```bash
export SERVER_BIND_ADDRESS="$(hostname -I | awk '{print $1}')"
export SERVER_PORT=17777
docker compose up -d server
echo "$SERVER_BIND_ADDRESS"
```

Use o endereço exibido e a porta 17777 nas configurações do cliente Windows.
O endereço pode mudar após reiniciar o WSL. Isso não coloca IP no código nem
exige publicar em `0.0.0.0`. Não desative o firewall para executar os testes.

Para acompanhar o serviço e manter uma sessão Linux ativa, deixe outro terminal
WSL com `docker compose logs -f server` ou execute `docker compose up server`
em primeiro plano. Serviços systemd sozinhos não mantêm o WSL ativo:
[documentação Microsoft](https://learn.microsoft.com/en-us/windows/wsl/systemd).

## Testes automáticos com as builds reais

Clientes Linux contra o serviço Docker:

```bash
docker compose --profile tools run --rm test
MATCH_PRESET=koth_highrise docker compose --profile tools run --rm test
```

No **PowerShell**, na raiz do repositório, substitua `<IP-PRIVADO-WSL>` pelo endereço
exibido acima e use a versão gerada:

```powershell
python scripts/test_exports.py --release build/releases/local --platform windows --host <IP-PRIVADO-WSL> --port 17777 --preset tdm_highrise --logs build/smoke/windows-tdm
python scripts/test_exports.py --release build/releases/local --platform windows --host <IP-PRIVADO-WSL> --port 17777 --preset koth_highrise --logs build/smoke/windows-koth
```

Para testar também o Server Windows nativo, sem Docker:

```powershell
python scripts/test_exports.py --release build/releases/local --platform windows --local-server --port 17778 --logs build/smoke/windows-native
```

O teste abre dois clientes **headless**, carrega o jogo exportado, conecta, entra
no lobby, carrega Highrise, seleciona arma e exige dois jogadores e snapshots
da partida. No servidor nativo, verifica feature dedicada e placeholder de textura.
Usa perfis temporários sem alterar `user://settings.cfg` real e encerra somente
os processos que criou. Logs ficam em `build/smoke/`.

Mensagens conhecidas de recursos em uso ao encerrar são exibidas separadamente.
No Server nativo, um aviso ENet de envio durante desconexão só é classificado como
encerramento após conferir o log sem erros com os clientes ainda conectados.
Outros erros falham o teste.

Teste negativo, dentro do WSL, usando porta sem servidor:

```bash
docker compose --profile tools run --rm smoke 127.0.0.1 39777 1
```

Esse comando deve retornar erro. Testes de comportamento dos scripts (WSL):

```bash
python3 -m unittest discover -s scripts/tests -v
```

## Conferência manual

Abra `build/releases/local/client-windows/shrooter-client.exe` duas vezes e
configure o servidor local. Confira imagem, áudio, entrada, movimento/colisões,
tiro/dano, morte/respawn, pickups, granadas e final da partida em TDM/KOTH.
Os testes headless não comprovam esses aspectos visuais e de jogabilidade.

Para parar o serviço de teste:

```bash
docker compose stop server
```

O `.gitignore` mantém executáveis, pacotes, logs e perfis fora do Git.
Veja o [registro de verificação](local-build-verification.md).
