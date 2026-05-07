# Lista De Assets De Arte

## Direção Visual

O alvo visual é um FPS simples, colorido e legível, inspirado por `Lovely Planet`: formas limpas, cores chapadas, silhuetas fortes, materiais pouco realistas e poucos detalhes. As referências em `imgs/art_style/` também apontam para robôs/personagens fofos, armas estilizadas, itens brilhantes e props sci-fi/fazenda simplificados.

Regras práticas para todos os assets:

| Regra | Direção |
| --- | --- |
| Geometria | Low-poly real, flat shaded, poucos bevels grandes, sem microdetalhe |
| Textura | Preferir materiais de cor sólida; usar textura só para ícone, emissivo ou detalhe muito simples |
| Leitura | O jogador deve identificar arma, pickup, time e cobertura em menos de 1 segundo |
| Paleta | Grama verde pastel, céu azul claro, paredes azul/teal, acentos rosa/coral/amarelo/ciano |
| Times | Azul e vermelho/coral aplicados por material override sempre que possível |
| Escala | Modelar em metros, origem no centro/base lógica, pivôs limpos para Godot |
| Reuso | Priorizar peças modulares e variações por material em vez de muitos modelos únicos |
| Export | Preferir `.glb` ou `.gltf`, malha limpa, nomes de materiais claros, sem animação se não for necessária |

Metas de polígonos:

| Tipo | Meta |
| --- | --- |
| Prop pequeno | 100 a 400 triângulos |
| Prop médio | 400 a 900 triângulos |
| Peça modular de mapa | 100 a 800 triângulos |
| Arma em primeira pessoa | 800 a 1800 triângulos |
| Pickup hero | 300 a 900 triângulos |
| Personagem simples | 1200 a 2500 triângulos |
| Prédio simples | 1000 a 3500 triângulos |

Base comum para prompts de RodinAI/Meshy:

```text
Low-poly stylized 3D game asset, Lovely Planet inspired, bright pastel colors, flat shaded, simple readable silhouette, clean geometry, game-ready GLB, no text, no logos, no photorealism, no gritty dirt, minimal materials, optimized for Godot FPS arena.
```

## P0: Assets Essenciais Para O Projeto Básico

| Asset | Uso e reuso | Polys alvo | Prompt base |
| --- | --- | --- | --- |
| Player robot | Personagem padrão para local/remoto/dummy; usar material azul/vermelho para times | 1200-2500 | `Low-poly stylized cute FPS robot character, rounded capsule body, simple arms and legs, small antenna, blank face with two black oval eyes, team color material zones, bright pastel palette, flat shaded, game-ready GLB, simple humanoid proportions for rigging, no text, no logos.` |
| First-person arms | Braços/mãos visíveis segurando armas; podem usar mesma cor de time ou cor neutra | 500-1200 | `Low-poly stylized first person arms and mitten hands for FPS, simple rounded shapes, pastel gloves, clean wrist cuffs, neutral pose for holding weapons, Lovely Planet inspired, flat shaded, game-ready GLB, no weapon included.` |
| Pistol | Arma inicial; também vira ícone 2D renderizado | 800-1400 | `Low-poly stylized sci-fi pistol, compact chunky silhouette, rounded barrel, pastel teal and cream body with coral accent, simple glowing cyan detail, flat shaded, game-ready GLB, no text, no logos, suitable for first person FPS.` |
| SMG | Arma automática; reutilizar materiais da pistol | 1000-1600 | `Low-poly stylized compact SMG for FPS, simple blocky body, short barrel, small magazine, pastel blue gray and cream, cyan glow strip, flat shaded, readable silhouette, game-ready GLB, no text, no logos.` |
| Shotgun | Arma de alto impacto; silhueta mais larga | 1000-1800 | `Low-poly stylized chunky shotgun for FPS, wide barrel, simple pump grip, oversized readable silhouette, pastel cream body with coral and teal accents, flat shaded, game-ready GLB, no text, no logos.` |
| Grenade | Granada arremessável e pickup visual | 400-900 | `Low-poly stylized sci-fi spherical grenade, simple segmented shell, large pull ring, cyan emissive band, pastel white and dark teal materials, flat shaded, readable at small size, game-ready GLB, no warning labels, no text.` |
| Health pickup | Pickup de cura; legível de longe | 300-700 | `Low-poly stylized health pickup object, floating heart inside simple transparent capsule or heart-shaped orb, pastel pink and white, soft cyan glow base, flat shaded, cute Lovely Planet style, game-ready GLB, no text.` |
| Grenade pickup | Pickup de granada separado do item arremessado se precisar | 300-800 | `Low-poly stylized grenade pickup, small floating sci-fi grenade icon object on a circular base, pastel teal shell with yellow pin and cyan glow, flat shaded, game-ready GLB, no text, no logos.` |
| Pickup pad | Base reutilizável para qualquer pickup, com material ready/not ready | 150-400 | `Low-poly stylized circular pickup pad, simple disk platform with beveled edge, glowing cyan ring, pastel gray surface, reusable game arena prop, flat shaded, game-ready GLB, no text.` |
| Spawn pad | Marca spawn de cada time e ajuda leitura do mapa | 200-500 | `Low-poly stylized team spawn pad, circular platform with arrow-like markings made from geometry, blue and coral material variants, soft glow rim, flat shaded, game-ready GLB, no text, no logos.` |
| Container | Modular container asset to easily create map cover, corridors, walls and vertical stacks | 500-1200 | `Low-poly stylized modular shipping container, clean rectangular shape, chunky beveled corners, simple panel grooves, pastel teal body with cream trim, optional blue and coral variants, flat shaded, game-ready GLB, no text, no logos.` |
| Crate | Pequena cobertura e decoração; empilhável | 150-500 | `Low-poly stylized square crate for FPS arena cover, simple wooden or plastic panels, chunky beveled edges, pastel tan and teal, flat shaded, stackable, game-ready GLB, no text.` |
| Half wall cover | Cobertura principal para combate | 100-300 | `Low-poly stylized modular half wall cover block, rounded bevels, pastel blue gray concrete, simple top trim, readable collision shape, flat shaded, game-ready GLB, no text, no logos.` |
| Full wall panel | Parede modular para layout | 100-400 | `Low-poly stylized modular wall panel for arena map, simple rectangular slab, pastel teal surface, cream border, optional coral accent stripe, flat shaded, tileable, game-ready GLB, no text.` |
| Floor tile | Piso modular para prototipar arenas | 50-200 | `Low-poly stylized modular square floor tile, pastel green or light gray, subtle beveled edge, clean flat shaded surface, seamless grid-friendly game asset, game-ready GLB, no text.` |
| Ramp | Acesso vertical simples | 100-300 | `Low-poly stylized modular ramp for FPS arena, simple sloped platform with thick sides, pastel gray and teal, flat shaded, clean collision-friendly shape, game-ready GLB, no text.` |
| Stair block | Alternativa ao ramp para verticalidade | 150-400 | `Low-poly stylized modular stair block, wide chunky steps, pastel gray body with teal side trim, flat shaded, grid-friendly, game-ready GLB, no text.` |
| Platform slab | Plataforma elevada reutilizável para mapa, respawn, objetivos e testes | 100-350 | `Low-poly stylized floating platform slab, simple rectangular arena platform with rounded bevels, pastel cream top and teal sides, flat shaded, game-ready GLB, no text.` |
| Fence/railing | Delimitação e leitura de bordas sem bloquear totalmente visão | 150-600 | `Low-poly stylized modular railing fence, simple posts and horizontal bars, pastel yellow or teal, chunky rounded shapes, flat shaded, tileable, game-ready GLB, no text.` |
| Boundary wall | Parede externa do mapa, estilo Lovely Planet | 200-700 | `Low-poly stylized tall boundary wall for colorful FPS arena, flat teal blue surface with jagged decorative top edge, simple chunky geometry, pastel color, flat shaded, game-ready GLB, no text.` |
| Simple cloud | Prop de céu e atmosfera | 80-250 | `Low-poly stylized puffy cloud made of simple rounded blobs, off-white pastel color, flat shaded, very simple Lovely Planet style, game-ready GLB, no text.` |

## P1: Assets Para Melhorar O Mapa Farm/Sci-Fi Atual

| Asset | Uso e reuso | Polys alvo | Prompt base |
| --- | --- | --- | --- |
| Barn small | Cobertura e marco visual; variações por escala | 1000-2200 | `Low-poly stylized small futuristic barn, simple rounded roof, pastel red/coral walls, teal roof trim, oversized clean shapes, flat shaded, game-ready GLB, no text, no logos.` |
| Barn large | Landmark principal do mapa | 1800-3500 | `Low-poly stylized large barn arena building, simple broad roof, large open doorway, pastel coral and cream walls, teal accents, readable FPS cover shapes, flat shaded, game-ready GLB, no text.` |
| Silo | Landmark vertical e cobertura circular | 800-1600 | `Low-poly stylized farm silo, simple cylinder with rounded cap, pastel cream metal, teal bands, chunky base, flat shaded, game-ready GLB, no text, no logos.` |
| Water tower | Landmark vertical, pode virar plataforma alta | 1200-2500 | `Low-poly stylized water tower, simple round tank on chunky legs, pastel blue gray tank, yellow ladder accents, flat shaded, clean readable silhouette, game-ready GLB, no text.` |
| Windmill | Elemento visual de fazenda; pode ser simplificado sem animação | 1000-2200 | `Low-poly stylized small windmill prop, simple tower, four chunky blades, pastel cream and teal body with coral accents, flat shaded, game-ready GLB, no text, no logos.` |
| Futuristic hut | Casa/abrigo pequeno inspirado nas referências sci-fi fofas | 1200-2500 | `Low-poly stylized cute futuristic hut, rounded dome roof, glowing cyan door, pastel gray and purple trims, simple antenna, cozy sci-fi farm style, flat shaded, game-ready GLB, no text.` |
| Pipe straight | Modular industrial/farm sci-fi pipe | 100-300 | `Low-poly stylized modular straight pipe segment, chunky cylinder, pastel dark teal or rust orange, simple connector rings, flat shaded, game-ready GLB, no text.` |
| Pipe elbow | Variação para rotas e decoração | 150-350 | `Low-poly stylized modular elbow pipe, 90 degree bend, chunky connector rings, pastel dark teal with yellow accents, flat shaded, game-ready GLB, no text.` |
| Gas tank | Cobertura pequena e prop de risco visual | 300-700 | `Low-poly stylized small gas tank prop, rounded cylinder on simple feet, pastel cream body with coral cap, chunky readable silhouette, flat shaded, game-ready GLB, no text, no warning labels.` |
| Trash container | Cobertura média; variação do container | 400-900 | `Low-poly stylized trash container dumpster, simple box shape with rounded lid, pastel teal and gray, chunky handles, flat shaded, game-ready GLB, no text, no logos.` |
| Cardboard boxes | Decoração e micro cobertura | 100-400 | `Low-poly stylized stack of cardboard boxes, simple cubes with tape strips modeled as geometry, pastel tan and cream, flat shaded, game-ready GLB, no text.` |
| Sandbag trench | Cobertura orgânica simples | 400-900 | `Low-poly stylized sandbag trench segment, rounded pillow-like bags, pastel tan, simple modular curve, flat shaded, game-ready GLB, no text.` |
| Traffic cone | Decoração e navegação visual | 80-180 | `Low-poly stylized traffic cone, chunky simple cone, pastel coral orange with cream band, flat shaded, game-ready GLB, no text.` |
| Log | Prop natural/cobertura baixa | 150-400 | `Low-poly stylized fallen log prop, simple cylinder with cut ends, pastel brown with minimal ring shapes, flat shaded, game-ready GLB, no text.` |
| Tree round | Natureza simples e repetível por MultiMesh | 150-500 | `Low-poly stylized round tree, simple trunk and spherical leafy crown, pastel green foliage, flat shaded, clean silhouette, game-ready GLB, no text.` |
| Tree cone | Variação de árvore para evitar repetição | 150-500 | `Low-poly stylized cone tree, simple brown trunk and stacked conical pastel green foliage, flat shaded, game-ready GLB, no text.` |
| Grass tuft | Multimesh para chão | 20-80 | `Low-poly stylized grass tuft, three to seven simple blade shapes, pastel green, flat shaded, very low poly, game-ready GLB, no text.` |
| Wheat tuft | Variante farm, barata para espalhar | 30-100 | `Low-poly stylized wheat tuft, simple golden stems and seed heads, flat shaded, pastel yellow, very low poly, game-ready GLB, no text.` |
| Rock set | Cobertura/decor sem textura | 100-400 cada | `Low-poly stylized rock cluster set, three simple angular rocks, pastel blue gray and purple shadows, flat shaded, game-ready GLB, no text.` |

## P1: Assets Para Mecânicas Planejadas

| Asset | Uso e reuso | Polys alvo | Prompt base |
| --- | --- | --- | --- |
| Jump pad | Plataforma que impulsiona jogador; precisa ser muito legível | 300-800 | `Low-poly stylized jump pad platform, circular spring-like pad with upward arrow shape made from geometry, bright cyan glow, pastel yellow rim, flat shaded, game-ready GLB, no text.` |
| Moving platform | Base visual para plataforma móvel | 200-600 | `Low-poly stylized moving platform, rectangular hover platform with simple cyan thrusters underneath, pastel gray top and teal sides, flat shaded, clean collision shape, game-ready GLB, no text.` |
| Breakable platform intact | Plataforma quebrável antes de romper | 250-700 | `Low-poly stylized breakable platform intact state, square slab with visible large crack lines modeled as shallow grooves, pastel cream top and coral warning corners, flat shaded, game-ready GLB, no text.` |
| Breakable platform broken chunks | Partes quebradas para troca visual ou FX | 300-900 total | `Low-poly stylized broken platform chunks, several simple cracked slab pieces, pastel cream and gray, chunky readable fragments, flat shaded, game-ready GLB, no text.` |
| King of the Hill capture ring | Área de objetivo; pode ser usada também em spawn e powerup | 200-600 | `Low-poly stylized capture zone ring for FPS objective, large circular floor ring, cyan emissive segments, pastel yellow and teal trim, flat shaded, game-ready GLB, no text.` |
| Hill beacon | Centro do objetivo Rei do Pedaço | 400-900 | `Low-poly stylized objective beacon, cute sci-fi pillar with floating orb, cyan glow, pastel cream body with blue and coral team lights, flat shaded, game-ready GLB, no text.` |
| Flag | CTF futuro; reutilizar base com cor de time | 300-800 | `Low-poly stylized team flag, simple pole and wavy geometric flag shape, blue and coral material variants, chunky base, flat shaded, game-ready GLB, no text, no logos.` |
| Flag base | Base de captura/retorno para CTF | 250-700 | `Low-poly stylized flag base platform, circular pedestal with team color ring, simple socket for flag pole, pastel gray and cyan glow, flat shaded, game-ready GLB, no text.` |
| Ammo pickup | Pickup de munição para armas futuras | 250-700 | `Low-poly stylized ammo pickup, floating capsule magazine or small ammo battery, pastel yellow and teal, cyan glow, simple readable FPS item, flat shaded, game-ready GLB, no text.` |
| Weapon pickup stand | Suporte para arma coletável | 300-800 | `Low-poly stylized weapon pickup stand, small pedestal with floating weapon bracket, cyan glow ring, pastel gray and yellow, flat shaded, reusable game prop, game-ready GLB, no text.` |
| Damage powerup | Powerup temporário de dano | 300-800 | `Low-poly stylized damage powerup pickup, floating red coral crystal inside simple ring, bright glow, chunky faceted shape, Lovely Planet inspired, flat shaded, game-ready GLB, no text.` |
| Speed powerup | Powerup de velocidade | 300-800 | `Low-poly stylized speed powerup pickup, floating green lightning bolt or winged capsule, cyan glow base, pastel green and yellow, flat shaded, readable silhouette, game-ready GLB, no text.` |

## P2: Armas Futuras Simples

| Asset | Uso e reuso | Polys alvo | Prompt base |
| --- | --- | --- | --- |
| Rocket launcher | Arma futura de projétil/explosão | 1200-2000 | `Low-poly stylized rocket launcher, chunky tube silhouette, pastel cream body, coral nose accents, cyan glowing sight, playful FPS weapon, flat shaded, game-ready GLB, no text, no logos.` |
| Rocket projectile | Projétil visível do rocket launcher | 200-500 | `Low-poly stylized small rocket projectile, simple capsule body with fins, pastel white body, coral nose, cyan exhaust glow, flat shaded, game-ready GLB, no text.` |
| Laser rifle | Arma de precisão/beam | 1200-2000 | `Low-poly stylized laser rifle, sleek simple sci-fi silhouette, long barrel, cyan energy core, pastel teal and cream body, flat shaded, game-ready GLB, no text, no logos.` |
| Energy orb projectile | Projétil genérico para armas sci-fi | 100-300 | `Low-poly stylized energy orb projectile, simple faceted sphere with small ring, bright cyan material, pastel glow style, flat shaded, game-ready GLB, no text.` |
| Melee wand/rod | Referência Lovely Planet, pode ser item visual ou arma experimental | 600-1200 | `Low-poly stylized magical sci-fi wand weapon, long simple rod with star-shaped pink tip, pastel red handle, cute FPS first-person weapon, flat shaded, game-ready GLB, no text.` |

## P2: VFX Meshes E Objetos Renderizáveis Como Ícones

| Asset | Uso e reuso | Polys alvo | Prompt base |
| --- | --- | --- | --- |
| Muzzle flash mesh | Pode ser usado em partículas ou mesh rápido | 50-150 | `Low-poly stylized muzzle flash starburst mesh, simple faceted yellow and orange burst, flat shaded, transparent-friendly, game-ready GLB, no text.` |
| Bullet impact chip | Pequeno FX de impacto em ambiente | 50-200 | `Low-poly stylized bullet impact chip cluster, small angular fragments and tiny dust puff shapes, pastel gray, flat shaded, game-ready GLB, no text.` |
| Explosion burst | Granada/foguete, pode virar mesh de partícula | 150-400 | `Low-poly stylized explosion burst, simple layered starburst cloud, coral orange center with yellow outer spikes, playful non-realistic style, flat shaded, game-ready GLB, no text.` |
| Smoke puff | Granada/explosão sem realismo | 80-250 | `Low-poly stylized smoke puff, cluster of rounded cloud blobs, pastel gray and lavender, flat shaded, simple VFX mesh, game-ready GLB, no text.` |
| Heart icon 3D | Pode renderizar UI de vida e pickup | 80-200 | `Low-poly stylized heart icon as 3D model, simple puffy heart shape, pastel pink, flat shaded, centered origin, game-ready GLB, no text.` |
| Skull/KO icon 3D | Kills/deaths ou eliminação | 150-350 | `Low-poly stylized cute skull icon 3D model, simple rounded shape, black oval eyes, pastel cream, friendly non-horror style, flat shaded, game-ready GLB, no text.` |
| Timer/hourglass icon 3D | UI de tempo e objetivos | 150-400 | `Low-poly stylized hourglass icon 3D model, simple chunky frame, pastel yellow and cyan glass, flat shaded, game-ready GLB, no text.` |
| Team badge 3D | UI, spawn, placar e bandeiras | 150-400 | `Low-poly stylized team badge emblem, simple shield shape with blank center, blue and coral material variants, flat shaded, game-ready GLB, no text, no logo.` |

## P2: Props De Cenário Para Variedade

| Asset | Uso e reuso | Polys alvo | Prompt base |
| --- | --- | --- | --- |
| Simple bridge | Conectar plataformas e criar linhas de tiro | 300-900 | `Low-poly stylized modular bridge, simple flat walkway with chunky side rails, pastel gray and yellow, grid-friendly, flat shaded, game-ready GLB, no text.` |
| Arch doorway | Moldura para entradas e corredores | 300-800 | `Low-poly stylized modular arch doorway, chunky rounded rectangular arch, pastel teal and cream, flat shaded, clean collision-friendly shape, game-ready GLB, no text.` |
| Small tower | Ponto alto simples | 1200-2500 | `Low-poly stylized small lookout tower, chunky legs, simple platform, ladder shape, pastel teal and yellow, flat shaded, readable FPS landmark, game-ready GLB, no text.` |
| Canopy/awning | Cobertura visual sem bloquear mapa | 300-800 | `Low-poly stylized colorful canopy awning, simple stretched fabric shape, pastel coral, teal and yellow stripes, chunky supports, flat shaded, game-ready GLB, no text.` |
| Giant flower | Prop decorativo inspirado em Lovely Planet | 200-600 | `Low-poly stylized giant cute flower prop, simple round center and large petal shapes, pastel pink and yellow, bright green stem, flat shaded, game-ready GLB, no text.` |
| Heart flower patch | Decoração de chão e navegação visual | 100-400 | `Low-poly stylized small heart-shaped flower patch, simple green stems and pink heart petals, Lovely Planet inspired, flat shaded, game-ready GLB, no text.` |
| Sign blank | Placa sem texto para set dressing | 150-400 | `Low-poly stylized blank sign board, simple wooden or metal post and rectangular blank panel, pastel cream and teal, flat shaded, game-ready GLB, no text, no symbols.` |
| Rocket landmark | Landmark inspirado nas referências de foguete | 1200-2800 | `Low-poly stylized cartoon rocket landmark, simple vertical rocket with rounded nose cone, pastel white body, coral fins, teal window, flat shaded, game-ready GLB, no text, no logos.` |

## Estratégia De Reuso

| Estratégia | Aplicação |
| --- | --- |
| Materiais por time | Mesmo player, spawn pad, flag e detalhes podem trocar azul/coral |
| Props modulares | Container, wall, ramp, floor, platform e fence constroem vários mapas |
| Assets renderizados como ícones | Armas, coração, granada, badge e ampulheta podem gerar UI 2D |
| MultiMesh | Grass, wheat, trees e flowers devem ser instanciados em massa |
| Variação por escala/rotação | Crates, rocks, boxes, pipes e cones podem parecer diferentes sem novos modelos |
| Mesma base para pickups | Pickup pad + item flutuante cobre health, grenade, ammo, weapon e powerups |
| Mesma base para objetivos | Capture ring + beacon cobre Rei do Pedaço, spawn especial e powerups de área |

## Ordem Recomendada De Produção

| Ordem | Pacote | Assets |
| --- | --- | --- |
| 1 | Gameplay mínimo | Player robot, arms, pistol, SMG, shotgun, grenade, health pickup, pickup pad |
| 2 | Mapa modular | Floor tile, wall panel, half wall, ramp, stairs, platform slab, container, crate, railing |
| 3 | Identidade visual | Spawn pad, boundary wall, clouds, heart flowers, team badge, weapon icons renderizados |
| 4 | Farm/sci-fi set | Barns, silo, water tower, windmill, pipes, trees, grass, wheat, rocks |
| 5 | Features futuras | Jump pad, moving platform, breakable platform, capture ring, beacon, flag, ammo/powerups |
| 6 | Polimento | VFX meshes, extra props, rocket landmark, icons finais |

## Critérios De Aceite Por Asset

| Critério | Esperado |
| --- | --- |
| Importa no Godot sem erro | `.glb`/`.gltf` abre e gera mesh/material corretamente |
| Escala correta | Asset fica em metros e não exige scale extremo na cena |
| Silhueta clara | Identificável em distância de combate |
| Poucos materiais | Idealmente 1 a 4 materiais por asset simples |
| Sem texto/logos | Evita problemas de geração, legibilidade e licenciamento |
| Colisão simples | Forma permite collision box/capsule/convex simples no Godot |
| Reuso fácil | Pivô e orientação permitem duplicar, alinhar e rotacionar no grid |

## Observações Sobre O Projeto Atual

- O Client já possui `assets/meshes/buildings`, `assets/meshes/props`, `assets/meshes/nature`, `assets/meshes/items`, áudio e texturas.
- O mapa atual referencia farm assets como barns, silo, water tower, fences, pipes, crates, barriers, trees, grass e wheat.
- Como `initial_project/Client/assets` está ignorado pelo Git, tratar esses assets como dependência de build até decidir se serão versionados ou empacotados separadamente.
- Para o estilo desejado, os novos assets devem ser mais simples, mais coloridos e menos realistas que boa parte dos props industriais atuais.
- O melhor caminho é substituir aos poucos por um kit modular próprio, começando por P0 e mapa modular.
