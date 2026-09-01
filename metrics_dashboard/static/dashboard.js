const state = {
  history: [],
  config: null,
  ws: null,
};
const peerColors = {};

const chartDefinitions = [
  {
    id: "chart-rtt",
    emptyLabel: "Waiting for RTT samples...",
    series: [
      { label: "Avg RTT", color: "#4fd1c5", getValue: (sample) => sample.summary?.avg_rtt_ms },
      { label: "Max RTT", color: "#8ab4ff", getValue: (sample) => sample.summary?.max_rtt_ms },
    ],
  },
  {
    id: "chart-loss",
    emptyLabel: "Waiting for packet loss samples...",
    series: [
      { label: "Avg Loss", color: "#ffb86b", getValue: (sample) => sample.summary?.avg_packet_loss_percent },
      { label: "Max Loss", color: "#ff7d7d", getValue: (sample) => sample.summary?.max_packet_loss_percent },
    ],
  },
  {
    id: "chart-traffic",
    emptyLabel: "Waiting for traffic samples...",
    series: [
      { label: "Sent KiB/s", color: "#4fd1c5", getValue: (sample) => sample.sent_kib_per_sec },
      { label: "Recv KiB/s", color: "#8ab4ff", getValue: (sample) => sample.received_kib_per_sec },
    ],
  },
  {
    id: "chart-packets",
    emptyLabel: "Waiting for packet rate samples...",
    series: [
      { label: "Sent pkt/s", color: "#4fd1c5", getValue: (sample) => sample.sent_packets_per_sec },
      { label: "Recv pkt/s", color: "#ffb86b", getValue: (sample) => sample.received_packets_per_sec },
    ],
  },
  {
    id: "chart-server-physics",
    emptyLabel: "Waiting for server physics samples...",
    series: [
      { label: "Server physics", color: "#8ab4ff", getValue: (sample) => sample.server_physics_process_ms },
    ],
  },
  {
    id: "chart-process",
    emptyLabel: "Waiting for process samples...",
    series: [
      { label: "CPU %", color: "#ffb86b", getValue: (sample) => sample.process_cpu_percent },
      { label: "Memory MB", color: "#4fd1c5", getValue: (sample) => sample.process_memory_rss_mb },
    ],
  },
];

function formatNumber(value, fractionDigits = 1, suffix = "") {
  if (!Number.isFinite(value)) {
    return "-";
  }
  return `${value.toFixed(fractionDigits)}${suffix}`;
}

function latestSample() {
  return state.history.length ? state.history[state.history.length - 1] : null;
}

function colorForPeer(peerId) {
  const key = String(peerId);
  if (!peerColors[key]) {
    const numericPeerId = Number(peerId);
    const hueSeed = Number.isFinite(numericPeerId)
      ? numericPeerId
      : key.split("").reduce((total, character) => total + character.charCodeAt(0), 0);
    peerColors[key] = `hsl(${(hueSeed * 57) % 360}, 70%, 55%)`;
  }
  return peerColors[key];
}

function getKnownFpsPeerIds() {
  const ids = new Set();

  state.history.forEach((sample) => {
    if (!Array.isArray(sample.client_fps)) {
      return;
    }

    sample.client_fps.forEach((entry) => {
      if (entry?.peer_id !== undefined) {
        ids.add(entry.peer_id);
      }
    });
  });

  return Array.from(ids).sort((a, b) => Number(a) - Number(b));
}

function getClientFps(sample, peerId) {
  if (!Array.isArray(sample.client_fps)) {
    return null;
  }

  const entry = sample.client_fps.find((item) => item.peer_id === peerId);
  return entry?.fps ?? null;
}

function buildClientFpsChartDefinition() {
  return {
    id: "chart-client-fps",
    emptyLabel: "Waiting for client FPS samples...",
    series: getKnownFpsPeerIds().map((peerId) => ({
      label: `Client ${peerId}`,
      color: colorForPeer(peerId),
      getValue: (sample) => getClientFps(sample, peerId),
    })),
  };
}

function upsertSample(sample) {
  if (!sample || typeof sample !== "object") {
    return;
  }

  const key = `${sample.timestamp_ms}-${sample.source}-${sample.role}`;
  const existingIndex = state.history.findIndex((item) => `${item.timestamp_ms}-${item.source}-${item.role}` === key);
  if (existingIndex >= 0) {
    state.history[existingIndex] = sample;
  } else {
    state.history.push(sample);
  }

  const limit = state.config?.history_size ?? 300;
  if (state.history.length > limit) {
    state.history = state.history.slice(state.history.length - limit);
  }
}

function setCard(id, value) {
  const element = document.getElementById(id);
  if (element) {
    element.textContent = value;
  }
}

function renderStatus() {
  const statusText = document.getElementById("status-text");
  const statusMeta = document.getElementById("status-meta");
  const sample = latestSample();

  if (!sample) {
    const host = state.config?.udp_host ?? "127.0.0.1";
    const port = state.config?.udp_port ?? 8765;
    statusText.textContent = "Waiting for samples...";
    statusMeta.textContent = `Listening on ${host}:${port}.`;
    return;
  }

  const ageMs = Date.now() - sample.received_at_ms;
  const ageSec = Math.max(ageMs / 1000, 0);
  statusText.textContent = `Receiving from ${sample.source} | PID ${sample.server_pid || "-"}`;
  statusMeta.textContent = `Last sample ${ageSec.toFixed(1)}s ago | ${sample.players_count} players | ${sample.lobbies_count} lobbies`;
}

function renderCards() {
  const sample = latestSample();
  if (!sample) {
    [
      "card-players",
      "card-lobbies",
      "card-rtt-avg",
      "card-rtt-max",
      "card-loss-avg",
      "card-loss-max",
      "card-sent-kib-per-sec",
      "card-recv-kib-per-sec",
      "card-sent-pps",
      "card-recv-pps",
      "card-server-physics",
      "card-client-fps-avg",
      "card-client-fps-min",
      "card-cpu",
      "card-memory",
      "card-pid",
    ].forEach((id) => setCard(id, "-"));
    return;
  }

  setCard("card-players", String(sample.players_count ?? "-"));
  setCard("card-lobbies", String(sample.lobbies_count ?? "-"));
  setCard("card-rtt-avg", formatNumber(sample.summary?.avg_rtt_ms, 1, " ms"));
  setCard("card-rtt-max", formatNumber(sample.summary?.max_rtt_ms, 1, " ms"));
  setCard("card-loss-avg", formatNumber(sample.summary?.avg_packet_loss_percent, 2, "%"));
  setCard("card-loss-max", formatNumber(sample.summary?.max_packet_loss_percent, 2, "%"));
  setCard("card-sent-kib-per-sec", formatNumber(sample.sent_kib_per_sec, 1, " KiB/s"));
  setCard("card-recv-kib-per-sec", formatNumber(sample.received_kib_per_sec, 1, " KiB/s"));
  setCard("card-sent-pps", formatNumber(sample.sent_packets_per_sec, 1));
  setCard("card-recv-pps", formatNumber(sample.received_packets_per_sec, 1));
  setCard("card-server-physics", formatNumber(sample.server_physics_process_ms, 2, " ms"));
  setCard("card-client-fps-avg", formatNumber(sample.client_fps_summary?.avg_fps, 1));
  setCard("card-client-fps-min", formatNumber(sample.client_fps_summary?.min_fps, 1));
  setCard("card-cpu", formatNumber(sample.process_cpu_percent, 1, "%"));
  setCard("card-memory", formatNumber(sample.process_memory_rss_mb, 1, " MB"));
  setCard("card-pid", sample.server_pid ? String(sample.server_pid) : "-");
}

function renderPeers() {
  const body = document.getElementById("peers-body");
  const sample = latestSample();
  if (!body) {
    return;
  }

  if (!sample || !Array.isArray(sample.peers) || sample.peers.length === 0) {
    body.innerHTML = '<tr><td colspan="7" class="empty-row">No connected peers in the latest sample.</td></tr>';
    return;
  }

  body.innerHTML = sample.peers
    .map(
      (peer) => `
        <tr>
          <td>${peer.peer_id ?? "-"}</td>
          <td>${formatNumber(peer.rtt_ms, 1)}</td>
          <td>${formatNumber(peer.last_rtt_ms, 1)}</td>
          <td>${formatNumber(peer.rtt_variance_ms, 1)}</td>
          <td>${formatNumber(peer.packet_loss_percent, 2)}</td>
          <td>${formatNumber(peer.app_ping_ms, 1)}</td>
          <td>${formatNumber(peer.client_fps, 1)}</td>
        </tr>
      `,
    )
    .join("");
}

function formatAxisValue(value) {
  if (!Number.isFinite(value)) {
    return "-";
  }

  const absoluteValue = Math.abs(value);
  const fractionDigits = absoluteValue >= 100 ? 0 : absoluteValue >= 10 ? 1 : absoluteValue >= 1 ? 2 : 3;
  return value.toFixed(fractionDigits);
}

function buildPolylinePoints(history, valueGetter, minValue, maxValue, width, height, chartArea) {
  const usableWidth = chartArea.right - chartArea.left;
  const usableHeight = chartArea.bottom - chartArea.top;
  const range = maxValue - minValue || 1;

  return history
    .map((sample, index) => {
      const value = valueGetter(sample);
      if (!Number.isFinite(value)) {
        return null;
      }

      const x = chartArea.left + (history.length === 1 ? usableWidth / 2 : (index / (history.length - 1)) * usableWidth);
      const normalized = (value - minValue) / range;
      const y = chartArea.bottom - normalized * usableHeight;
      return `${x.toFixed(2)},${y.toFixed(2)}`;
    })
    .filter(Boolean)
    .join(" ");
}

function renderChart(definition) {
  const container = document.getElementById(definition.id);
  if (!container) {
    return;
  }

  const values = state.history.flatMap((sample) =>
    definition.series
      .map((series) => series.getValue(sample))
      .filter((value) => Number.isFinite(value)),
  );

  if (!state.history.length || !values.length) {
    container.className = "chart-body chart-empty";
    container.textContent = definition.emptyLabel;
    return;
  }

  container.className = "chart-body";
  const width = 560;
  const height = 170;
  const chartArea = {
    left: 58,
    right: width - 18,
    top: 16,
    bottom: height - 18,
  };
  const rawMinValue = Math.min(...values);
  const rawMaxValue = Math.max(...values);
  const rawRange = rawMaxValue - rawMinValue;
  const scalePadding = rawRange > 0
    ? rawRange * 0.08
    : Math.max(Math.abs(rawMaxValue) * 0.1, 1);
  const minValue = rawMinValue - scalePadding;
  const maxValue = rawMaxValue + scalePadding;
  const gridLines = [0, 0.25, 0.5, 0.75, 1]
    .map((ratio) => {
      const y = chartArea.top + (chartArea.bottom - chartArea.top) * ratio;
      const tickValue = maxValue - (maxValue - minValue) * ratio;
      return `
        <line class="chart-grid-line" x1="${chartArea.left}" y1="${y}" x2="${chartArea.right}" y2="${y}" />
        <text class="chart-axis-label" x="${chartArea.left - 8}" y="${y + 4}" text-anchor="end">${formatAxisValue(tickValue)}</text>
      `;
    })
    .join("");

  const seriesMarkup = definition.series
    .map((series) => {
      const points = buildPolylinePoints(state.history, series.getValue, minValue, maxValue, width, height, chartArea);
      if (!points) {
        return "";
      }

      return `<polyline class="chart-path" stroke="${series.color}" points="${points}" />`;
    })
    .join("");

  const legendMarkup = definition.series
    .map((series) => {
      const value = series.getValue(latestSample());
      return `
        <span class="legend-item">
          <span class="legend-swatch" style="background:${series.color}"></span>
          <span>${series.label}: ${formatNumber(value, 1)}</span>
        </span>
      `;
    })
    .join("");

  container.innerHTML = `
    <div class="chart-shell">
      <svg class="chart-svg" viewBox="0 0 ${width} ${height}" preserveAspectRatio="none" aria-hidden="true">
        ${gridLines}
        ${seriesMarkup}
      </svg>
      <div class="chart-legend">${legendMarkup}</div>
    </div>
  `;
}

function renderCharts() {
  chartDefinitions.forEach(renderChart);
  renderChart(buildClientFpsChartDefinition());
}

function renderAll() {
  renderStatus();
  renderCards();
  renderPeers();
  renderCharts();
}

async function bootstrap() {
  const response = await fetch("/api/history");
  const payload = await response.json();
  state.config = payload.config ?? {
    udp_host: "127.0.0.1",
    udp_port: 8765,
    history_size: 300,
  };
  state.history = Array.isArray(payload.history) ? payload.history : [];
  renderAll();
}

function connectSocket() {
  const protocol = window.location.protocol === "https:" ? "wss" : "ws";
  const socketUrl = `${protocol}://${window.location.host}/ws`;
  const socket = new WebSocket(socketUrl);
  state.ws = socket;

  socket.onmessage = (event) => {
    const payload = JSON.parse(event.data);
    if (payload.type === "sample" && payload.sample) {
      upsertSample(payload.sample);
      renderAll();
    }

    if (payload.type === "waiting" && payload.payload?.config) {
      state.config = payload.payload.config;
      renderAll();
    }
  };

  socket.onclose = () => {
    window.setTimeout(connectSocket, 1500);
  };
}

window.addEventListener("load", async () => {
  await bootstrap();
  connectSocket();
  window.setInterval(renderStatus, 1000);
});
