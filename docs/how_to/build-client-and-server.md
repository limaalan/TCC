# Gerar builds de Client e Server

## Objetivo

Exportar executáveis reproduzíveis a partir dos dois projetos Godot.

## Antes de exportar

- Execute `initial_project/setup_shared_links.ps1`.
- Confirme que os assets necessários estão presentes e versionados ou são produzidos pelo pipeline documentado.
- Abra Client e Server no Godot para detectar imports ou referências quebradas.
- Não versione a pasta `build/`; ela é saída de exportação.

## Exportar pelo editor

1. Abra `initial_project/Client` ou `initial_project/Server` no Godot.
2. Abra **Project > Export**.
3. Escolha o preset desejado e exporte para `build/client/` ou `build/server/`.
4. Execute o binário recém-gerado antes de distribuí-lo.

Os presets Linux atuais usam PCK embutido no executável. No Windows, o export também deve ser tratado como o conjunto de arquivos gerado pelo preset; não presuma que um artefato manualmente renomeado mantém todas as dependências se o preset mudar.

## Verificar

No PowerShell:

```powershell
Get-ChildItem .\build\server | Select-Object Name, Length, LastWriteTime
Get-ChildItem .\build\client | Select-Object Name, Length, LastWriteTime
```

Para o Server Linux, execute localmente ou em ambiente Linux com `--headless -- --port=7777` antes do deploy.
