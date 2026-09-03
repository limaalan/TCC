# Smoke test de release

## Objetivo

Validar rapidamente uma build antes de distribuí-la ou executá-la em outro ambiente.

## Checklist

- O Server inicia com `--headless -- --port=7777`.
- O Client abre sem recursos ausentes.
- Dois jogadores conseguem conectar e iniciar uma partida.
- TDM e KOTH iniciam em Highrise.
- Spawn, equipe, HUD, dano, morte, respawn e placar funcionam.
- Munição, pickups, granadas e power-ups sincronizam entre os dois jogadores.
- A tela final exibe o vencedor e **Voltar ao menu** retorna ao menu principal.
- Quando habilitadas, as métricas chegam ao CSV ou à dashboard.

Registre a versão exportada, plataforma, data e resultado do teste junto da release.
