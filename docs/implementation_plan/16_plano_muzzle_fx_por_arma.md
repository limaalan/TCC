# Muzzle FX Por Arma

## Objetivo

Permitir que cada arma escolha um comportamento visual de disparo próprio sem alterar `Weapon`, o código de rede ou o gameplay autoritativo do servidor.

O muzzle FX não é tratado apenas como uma textura. Ele é uma `PackedScene` que pode conter qualquer combinação de nós, scripts, shaders, partículas ou objetos temporários.

## Arquitetura Implementada

### Contrato comum

`WeaponMuzzleFx` é um `Node3D` com uma única operação pública:

```gdscript
class_name WeaponMuzzleFx
extends Node3D

func play() -> void:
	pass
```

Cada comportamento concreto herda essa classe e implementa `play()`.

### Configuração por arma

`WeaponPresentationData` possui:

```gdscript
@export var muzzle_fx_scene: PackedScene
```

Cada resource de apresentação aponta para sua própria cena:

| Arma | Resource de apresentação | Cena de efeito |
| --- | --- | --- |
| Pistol | `pistol_presentation.tres` | `pistol_muzzle_fx.tscn` |
| SMG | `smg_presentation.tres` | `smg_muzzle_fx.tscn` |
| Shotgun | `shotgun_presentation.tres` | `shotgun_muzzle_fx.tscn` |

### Execução

Quando a arma entra na árvore:

1. `Weapon` lê `data.muzzle_fx_scene`.
2. Instancia a cena como filha do nó `Muzzle`.
3. Valida que a raiz herda `WeaponMuzzleFx`.
4. Ao disparar, chama `muzzle_fx.play()`.

Áudio, recoil e camera shake continuam independentes. A ausência ou falha de um muzzle FX não deve impedir o restante do feedback do disparo.

## Centralização Espacial

O nó `Muzzle` da cena da arma continua sendo a fonte de verdade para a posição física da boca do cano.

- O efeito é instanciado como filho direto de `Muzzle`.
- A raiz das cenas atuais permanece com posição e rotação locais zeradas.
- O sprite permanece centralizado em sua textura.
- Diferenças geométricas entre modelos são resolvidas movendo `Muzzle` na cena da arma.
- A configuração visual não duplica um offset de posição em outro resource.

Na shotgun, o antigo deslocamento do `ShootParticles` foi incorporado ao próprio `Muzzle`, preservando a posição visual anterior.

## Implementação Visual Atual

As três cenas específicas herdam `muzzle_flash_confetti.tscn`, que usa:

- um `GPUParticles3D`;
- uma única partícula;
- `QuadMesh` com billboard;
- material `unshaded` e alpha scissor;
- sombras e física desativadas;
- rotação aleatória de `-180°` a `180°`;
- uma curva curta de escala;
- o sprite `muzzle_flash_confetti.png`.

Configuração inicial:

| Arma | Escala da cena | Duração |
| --- | --- | --- |
| Pistol | `0.26` | `0.06 s` |
| SMG | `0.30` | `0.05 s` |
| Shotgun | `0.46` | `0.09 s` |

Embora o comportamento atual seja compartilhado por herança, cada arma já referencia uma cena distinta e pode divergir sem modificar `Weapon`.

## Como Criar Um Novo Comportamento

1. Criar uma cena cuja raiz seja `Node3D`.
2. Anexar um script que herde `WeaponMuzzleFx`.
3. Implementar `play()`.
4. Atribuir a cena a `muzzle_fx_scene` no `.tres` da arma.

Exemplo conceitual:

```gdscript
extends WeaponMuzzleFx

func play() -> void:
	# Tocar animação, reiniciar partículas, acionar shader etc.
	pass
```

## Evolução Futura: Confetes Físicos

Uma futura `ShotgunConfettiMuzzleFx` poderá substituir apenas `shotgun_muzzle_fx.tscn` e implementar `play()` para:

- tocar o clarão billboard imediato;
- instanciar poucos confetes físicos;
- aplicar impulsos locais;
- limitar quantidade e tempo de vida;
- remover os confetes após alguns segundos;
- usar pooling caso o profiling mostre necessidade.

Esse comportamento deve permanecer client-side e puramente visual. Os confetes não participam de dano, colisão autoritativa ou sincronização de tiro.

## Cuidados Para Efeitos Arbitrários

- A cena deve limpar timers, tweens e objetos temporários que criar.
- Objetos persistentes precisam de limite de quantidade e tempo de vida.
- O nó deve tolerar `play()` repetido antes do efeito anterior terminar.
- Partículas físicas futuras não devem usar RPC por fragmento.
- Shaders e materiais alterados em runtime devem ser locais por instância.
- A cena não deve assumir que pertence à shotgun; a associação vem do resource.

## Checklist De Teste

- Cada `.tres` aponta para sua própria cena de muzzle FX.
- Pistola, SMG e shotgun reproduzem o efeito ao disparar.
- A SMG não perde efeitos em tiros consecutivos.
- O efeito permanece centralizado no cano em visão local e remota.
- Trocar a cena no resource de uma arma não muda as demais.
- Uma cena que não herda `WeaponMuzzleFx` gera erro claro e não quebra áudio/recoil.
- Dano, munição, raycasts e RPCs permanecem inalterados.

## Critério De Pronto Do Primeiro Passo

- `Weapon` não conhece `GPUParticles3D`, textura, shader ou tipo concreto do efeito.
- Cada arma escolhe uma `PackedScene` pelo `WeaponPresentationData`.
- O único contrato entre arma e efeito é `WeaponMuzzleFx.play()`.
- O efeito atual continua barato e visualmente equivalente.
- Um comportamento futuro pode ser adicionado criando uma nova cena e trocando a referência no resource.
