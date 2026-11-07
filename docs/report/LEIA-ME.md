# Relatório do TCC

O relatório de Jump'n'Shoot está em LaTeX. Compile `main.tex` a partir desta pasta.

## Organização

- `capitulos/`: introdução, conceitos, produtos similares, metodologia, desenvolvimento/resultados e conclusão.
- `PreTexto/`: resumo e abstract.
- `PosTexto/apendiceb.tex`: documentação técnica complementar incluída no relatório.
- `main.bib`: referências bibliográficas.
- `variaveis.tex` e `main.xmpdata`: identificação, dados da defesa e metadados.
- `figuras/tcc2/` e `imgs/`: imagens; diagramas em `.tex` são compilados pelo LaTeX.
- `utfpr.cls` e arquivos de configuração: modelo e apresentação. O [README original](readme.md) conserva os créditos e instruções do template.

## Compilação

Abra esta pasta em um ambiente LaTeX e compile `main.tex`, incluindo BibTeX e as passagens necessárias para resolver bibliografia, sumário e referências cruzadas. O projeto possui ajustes para Tectonic/XeTeX e mantém a configuração original para pdfLaTeX.

Para abrir o projeto no Overleaf, importe um ZIP com o conteúdo desta pasta e selecione `main.tex`. A compilação local foi verificada com Tectonic 0.17.0.

As imagens novas devem ficar em `figuras/tcc2/`, com nomes descritivos sem espaços ou acentos. Prefira PNG para capturas e PDF para diagramas vetoriais. Confira visualmente o documento após compilar.

PDFs de saída e arquivos intermediários são ignorados pelo Git. Para depósito acadêmico, valide o PDF gerado conforme o perfil PDF/A exigido.
