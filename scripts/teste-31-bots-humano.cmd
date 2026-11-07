@echo off
setlocal
pushd "%~dp0.."
echo jumpnshoot - demonstracao local com 31 bots e 1 jogador
echo Highrise / KOTH - 30 segundos de aquecimento e 5 minutos de coleta
echo Municao inicial: 10000. Pontuacao experimental: 10000.
echo.
echo Prepare a gravacao antes de continuar.
echo Na janela do jogo, escolha uma arma para nascer e mantenha o foco nela.
echo O teste comeca depois que todos os participantes estiverem prontos.
echo A pasta de CSVs e logs sera exibida neste terminal.
echo.
pause
python scripts/run_loadtest.py --players 32 --human --preset koth_highrise --ammo 10000 --duration 300 --warmup 30
set "pilotExitCode=%ERRORLEVEL%"
echo.
echo Execucao encerrada com codigo %pilotExitCode%. Consulte os logs da rodada.
echo Os resultados foram preservados em build\loadtest, em uma pasta nova.
popd
pause
exit /b %pilotExitCode%
