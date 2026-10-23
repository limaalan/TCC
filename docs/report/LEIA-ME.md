# Fontes LaTeX do relatório de TCC2

Esta pasta contém a prévia do TCC2 em LaTeX, baseada em `docs/tcc2/relatorio_tcc2.md` e no modelo utilizado pelo autor no TCC1. O texto foi distribuído em seis capítulos, com referências externas em BibTeX, tabelas, figuras e apêndices de apoio à revisão.

O projeto faz parte do repositório TCC. O arquivo principal é `main.tex`. Os arquivos LaTeX desta pasta são a versão de trabalho para as próximas revisões; o Markdown permanece como registro da prévia que originou esta conversão.

## Organização

- `main.tex`: reúne os capítulos e elementos do documento.
- `utfpr.cls`, `configuracoes.tex` e `configuracoes-tcc2.tex`: apresentação e compatibilidade do modelo.
- `variaveis.tex`: identificação, ano, dados da defesa e palavras-chave.
- `main.xmpdata`: metadados utilizados pelo pacote `pdfx`.
- `main.bib` e `abntex2-alf.bst`: bibliografia externa e estilo bibliográfico.
- `capitulos/`: os seis capítulos incluídos pelo arquivo principal.
- `PreTexto/resumo.tex` e `PreTexto/abstract.tex`: resumo e tradução da prévia.
- `PosTexto/apendicea.tex`: evidências pendentes.
- `PosTexto/apendiceb.tex`: índice das fontes técnicas do repositório, referenciadas pelos marcadores entre colchetes.
- `figuras/tcc2/`: imagens e diagramas utilizados pelo TCC2; coloque as novas imagens aqui.
- `readme.md`: documentação original do template.

Arquivos de exemplo e arquivos antigos que não aparecem nos comandos de inclusão de `main.tex` não participam da compilação. O projeto original do TCC1 na Área de Trabalho foi preservado.

## Compilação

Depois de clonar o repositório, abra `docs/report` como projeto LaTeX e use `main.tex` como documento principal. A configuração contém ajustes para Tectonic/XeTeX, mantendo o caminho original de pdfLaTeX.

Para importar no Overleaf, compacte o conteúdo de `docs/report` em ZIP, importe-o como projeto e selecione `main.tex` como documento principal. O projeto não lê arquivos de fora desta pasta para compilar. A compilação no Overleaf ainda precisa ser verificada nesse ambiente.

Os pacotes LaTeX são fornecidos pelo ambiente. A bibliografia depende de BibTeX e de passagens adicionais para resolver citações, sumário e referências cruzadas. Os diagramas TikZ são compilados diretamente, sem Mermaid ou comandos externos.

## Imagens

Use `figuras/tcc2/` para novas imagens. Prefira PNG para capturas de tela e PDF para diagramas vetoriais, com nomes descritivos sem espaços ou acentos. Veja `figuras/tcc2/LEIA-ME.md` para um exemplo de inclusão. PDFs de recursos em subpastas permanecem versionáveis.

## Pendências da prévia

O ano foi atualizado para 2026 e a disciplina para TCC2. A data da defesa e a composição da banca permanecem como “a definir”; os nomes da banca do TCC1 foram mantidos apenas em comentários de `variaveis.tex`.

As notas de evidência pendente foram preservadas. Não representam testes executados ou resultados experimentais. As datas de acesso das referências foram preservadas da prévia, sem substituir datas históricas pelo ano atual.

O `.gitignore` local exclui `main.pdf`, `exemploPDF.pdf` e arquivos intermediários. Os fontes, imagens, estilos e perfis de cor permanecem versionáveis. Uma compilação bem-sucedida não substitui a revisão visual, a conferência bibliográfica ou a validação final de PDF/A.
