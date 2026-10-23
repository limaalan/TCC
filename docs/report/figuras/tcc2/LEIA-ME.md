# Imagens do TCC2

Coloque nesta pasta as novas capturas de tela, diagramas e gráficos do relatório. Ela faz parte do projeto LaTeX e será incluída ao importar a pasta `docs/report` no Overleaf.

Use nomes descritivos, preferencialmente em minúsculas, sem espaços e sem acentos. Exemplos: `menu-principal.png`, `hud-tdm.png`, `hud-koth.png`, `mapa-highrise.png`, `dashboard-metricas.png`.

PNG é adequado para capturas de tela; JPG pode ser usado para fotografias; PDF pode ser usado para diagramas vetoriais. PDFs nesta subpasta não são ignorados pelo Git. Evite EPS para a compilação no editor integrado, pois Tectonic não o suporta.

As figuras `interpolacao-snapshots.png` e `compensacao-latencia-disparos.png` são as exportações em PNG (1280 × 900 pixels) dos novos diagramas e já estão incluídas no capítulo 5. O arquivo editável `diagramas-rede.drawio` contém as duas páginas de origem; os tempos apresentados são ilustrativos. Ao exportar novas versões, mantenha os nomes dos PNGs para atualizar o relatório sem alterar os caminhos no LaTeX. Os arquivos `.tex` desta pasta contêm os três diagramas convertidos de Mermaid para TikZ.

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

Ao enviar as imagens, informe o que cada uma mostra e a seção em que deve aparecer. As notas de evidência pendente no texto indicam os locais que ainda precisam de material.
