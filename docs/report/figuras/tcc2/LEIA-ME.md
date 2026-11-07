# Imagens do TCC2

Esta pasta reúne as capturas de tela, diagramas e gráficos do relatório.

Use nomes descritivos em minúsculas, como `menu-principal.png`, `hud-tdm.png` e `mapa-highrise.png`.

PNG é adequado para capturas de tela; JPG pode ser usado para fotografias; PDF pode ser usado para diagramas vetoriais. PDFs nesta subpasta não são ignorados pelo Git. Evite EPS para a compilação no editor integrado, pois Tectonic não o suporta.

Os diagramas de interpolação e compensação de latência são exportados de `diagramas-rede.drawio`. Os arquivos `.tex` contêm diagramas em TikZ compilados com o relatório.

Exemplo de inclusão a partir dos capítulos, com compilação por `main.tex`:

```latex
\begin{figure}[htbp]
  \centering
  \caption{Interface da partida em Team Deathmatch}
  \label{fig:hud-tdm}
  \includegraphics[width=\linewidth]{figuras/tcc2/hud-tdm.png}
  \fonte{Autoria própria (2026)}
\end{figure}
```
