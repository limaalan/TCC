# Recursos de terceiros — jumpnshoot

**Registro parcial, atualizado em 29/10/2026.** Este arquivo identifica os ícones cuja correspondência foi conferida com os originais oficiais e registra a procedência declarada do áudio e as fontes oficiais das marcas. As pendências abaixo ainda precisam ser resolvidas; este documento não confirma a inclusão dos avisos nos executáveis ou pacotes de distribuição.

## Ícones de Game-icons.net

Os desenhos listados a seguir foram disponibilizados pelos respectivos autores no [Game-icons.net](https://game-icons.net/about.html), sob [Creative Commons Attribution 3.0 Unported — CC BY 3.0](https://creativecommons.org/licenses/by/3.0/). Os títulos apontam para as páginas originais de autoria e licença.

| Autor | Desenhos utilizados ou mantidos no repositório |
| --- | --- |
| **Lorc** | [Cog](https://game-icons.net/1x1/lorc/cog.html), [Radar sweep](https://game-icons.net/1x1/lorc/radar-sweep.html), [Reticule](https://game-icons.net/1x1/lorc/reticule.html), [Mine explosion](https://game-icons.net/1x1/lorc/mine-explosion.html), [Supersonic bullet](https://game-icons.net/1x1/lorc/supersonic-bullet.html), [Fast arrow](https://game-icons.net/1x1/lorc/fast-arrow.html). |
| **Delapouite** | [Character](https://game-icons.net/1x1/delapouite/character.html), [Exit door](https://game-icons.net/1x1/delapouite/exit-door.html), [Hill conquest](https://game-icons.net/1x1/delapouite/hill-conquest.html), [Round star](https://game-icons.net/1x1/delapouite/round-star.html), [Save](https://game-icons.net/1x1/delapouite/save.html), [Speaker](https://game-icons.net/1x1/delapouite/speaker.html), [Graduate cap](https://game-icons.net/1x1/delapouite/graduate-cap.html), [Crosshair](https://game-icons.net/1x1/delapouite/crosshair.html), [Sawed-off shotgun](https://game-icons.net/1x1/delapouite/sawed-off-shotgun.html), [Server rack](https://game-icons.net/1x1/delapouite/server-rack.html), [Tomato](https://game-icons.net/1x1/delapouite/tomato.html). |
| **Skoll** | [Console controller](https://game-icons.net/1x1/skoll/console-controller.html), [MP5](https://game-icons.net/1x1/skoll/mp5.html). |
| **sbed** | [Death skull](https://game-icons.net/1x1/sbed/death-skull.html), [Select](https://game-icons.net/1x1/sbed/select.html). |
| **John Colburn** | [Pistol gun](https://game-icons.net/1x1/john-colburn/pistol-gun.html). |

Os arquivos de referência estão em `imgs/icons/`, com os slugs dos títulos em nomes de arquivo. Há cópias em `initial_project/Client/ui/shared/icons/`, `ui/hud/icons/` e `ui/credits_screen/images/`.

Adaptações locais observadas: exportação dos desenhos para PNG, uso de transparência e ajustes de tamanho/canvas. As versões reduzidas de 63×63 utilizadas no jogo têm as seguintes origens:

| Arquivo em `initial_project/Client/assets/textures/` | Desenho de origem |
| --- | --- |
| `icon_smg.png` | MP5 — Skoll |
| `icon_pistol.png` | Pistol gun — John Colburn |
| `icon_shotgun.png` | Sawed-off shotgun — Delapouite |
| `kills_icon.png` | Crosshair — Delapouite |
| `deaths_icon.png` | Death skull — sbed |
| `grenade_icon.png` | Tomato — Delapouite |

Os nomes locais descrevem o uso no jogo e podem diferir do título original. A atribuição refere-se aos desenhos; não sugere endosso dos autores ao projeto.

## Engine e template do relatório

O projeto utiliza Godot Engine, disponibilizada sob licença MIT. A licença está em [godotengine.org/license](https://godotengine.org/license/). Os avisos dos componentes incorporados devem corresponder à versão da engine efetivamente distribuída; sua preservação nos pacotes ainda precisa ser verificada, conforme a [orientação oficial da Godot](https://docs.godotengine.org/en/4.5/about/complying_with_licenses.html).

Os fontes do template LaTeX em `docs/report/` conservam seus avisos autorais e a indicação de LaTeX Project Public License 1.3 ou posterior. Esses avisos pertencem ao template e devem ser preservados. Não definem a licença do texto autoral nem do jogo.

## Procedência declarada do áudio

Alan Lima Marques informou que **todos os áudios do projeto foram gerados por ele com Stable Audio Open, executado localmente**. A declaração cobre os 14 arquivos versionados em `initial_project/Client/assets/audio/`, incluindo músicas e efeitos; a relação está no relatório de revisão. A referência informal ao local de download sugere Hugging Face, mas o repositório exato não foi confirmado pelo autor.

O nome exato do modelo, sua revisão e a época da geração não foram informados. Não há pendência de plano ou assinatura do serviço web: o caminho confirmado é execução local. Foram consultados os arquivos oficiais de licença atuais do [Stable Audio Open 1.0](https://huggingface.co/stabilityai/stable-audio-open-1.0/blob/main/LICENSE.md) e do [Stable Audio Open Small](https://huggingface.co/stabilityai/stable-audio-open-small/blob/main/LICENSE); ambos apresentam a Community License de 05/07/2024.

Esses textos distinguem os áudios gerados dos modelos: excluem outputs da definição de Derivative Works e reconhecem ao usuário, na relação com Stability AI e nos limites da lei aplicável, a titularidade dos outputs. Portanto, este registro **não transfere automaticamente aos WAV/OGG as obrigações de redistribuição dos pesos**. O crédito de procedência acima é documental; não declara uma obrigação automática de registro comercial ou de atribuição da licença dos pesos somente por incorporar os sons ao jogo. A revisão/época aceita pelo autor permanece um limite da verificação; os textos atuais não comprovam retroativamente qual contrato foi aceito.

## Logos e marcas

**GitHub / Invertocat:** a [orientação oficial de uso](https://brand.github.com/foundations/logo) permite o logo como botão para ligar a perfil ou projeto no GitHub, com condições como destaque secundário e ausência de sugestão de endosso. No projeto, o recurso é o ícone do botão do repositório na tela de créditos. Preservar os elementos da marca e observar a política; ele não integra a licença CC BY dos ícones acima.

**UTFPR:** a marca identifica a instituição vinculada ao trabalho acadêmico. Os arquivos oficiais estão na [página Marca da UTFPR](https://www.utfpr.edu.br/comunicacao/design/marca-da-utfpr), acompanhados do [Manual de uso da marca](https://www.utfpr.edu.br/comunicacao/design/manual-de-uso-da-identidade-visual-da-utfpr/identidade-visual-utfpr-2016-a4-1.pdf). O manual orienta proporções, alinhamento, versões, cores e legibilidade. Não foi identificada nessas fontes uma autorização genérica para qualquer uso acadêmico; esta atribuição não substitui a conferência da aplicação concreta da marca.

## Pendências deste registro

- Identificar o desenho, autor e licença de `imgs/icons/go-back-arrow.png` e sua cópia em `initial_project/Client/ui/shared/icons/`. O autor indicou provável origem Game-icons.net; a busca ampliada ainda não confirmou a correspondência e o desenho continua fora das atribuições acima.
- Registrar, quando recuperáveis, o identificador/revisão do Stable Audio Open utilizado e a época da geração. A procedência local está confirmada; não é necessário perguntar novamente sobre plano ou assinatura. Os termos dos pesos não foram impostos automaticamente aos arquivos de saída.
- Conferir os arquivos/variantes e a aplicação visual dos logos UTFPR e GitHub perante as fontes oficiais acima; as políticas foram localizadas, mas a tela final e a procedência de cada PNG ainda não foram validadas integralmente.
- Completar os avisos aplicáveis à versão Godot e aos componentes efetivamente distribuídos; conferir eventuais dependências empacotadas com a dashboard.
- Incluir os avisos necessários nos créditos e nos pacotes finais. Esta fase não alterou configurações, cenas ou scripts de empacotamento.

As demais artes foram declaradas próprias pelo autor do projeto. Este registro não escolhe uma licença para essas artes, para o código autoral ou para o texto do TCC.
