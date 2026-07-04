from __future__ import annotations

from collections import deque
from copy import deepcopy
import time
from typing import Any

from process_monitor import ProcessMonitor


class MetricsStore:
    def __init__(self, max_samples: int = 300) -> None:
        self._history: deque[dict[str, Any]] = deque(maxlen=max_samples)
        self._latest: dict[str, Any] | None = None
        self._process_monitor = ProcessMonitor()
        self.max_samples = max_samples

    def add_sample(self, sample: dict[str, Any]) -> dict[str, Any]:
        normalized = self._normalize(sample)
        self._latest = normalized
        self._history.append(normalized)
        return deepcopy(normalized)

    def get_latest(self) -> dict[str, Any] | None:
        if self._latest is None:
            return None
        return deepcopy(self._latest)

    def get_history(self) -> list[dict[str, Any]]:
        return [deepcopy(sample) for sample in self._history]

    def build_waiting_payload(self, udp_host: str, udp_port: int) -> dict[str, Any]:
        return {
            "status": "waiting",
            "message": f"Waiting for Godot metrics on {udp_host}:{udp_port}.",
            "history": [],
            "sample": None,
            "config": {
                "udp_host": udp_host,
                "udp_port": udp_port,
                "history_size": self.max_samples,
            },
        }

    def _normalize(self, sample: dict[str, Any]) -> dict[str, Any]:
        normalized = dict(sample)
        normalized["source"] = str(sample.get("source", "godot_server"))
        normalized["role"] = str(sample.get("role", "server"))
        normalized["timestamp_ms"] = self._as_int(sample.get("timestamp_ms"), int(time.time() * 1000))
        normalized["received_at_ms"] = int(time.time() * 1000)
        normalized["players_count"] = self._as_int(sample.get("players_count"), 0)
        normalized["lobbies_count"] = self._as_int(sample.get("lobbies_count"), 0)
        normalized["server_physics_process_ms"] = self._as_float(
            sample.get("server_physics_process_ms", sample.get("server_tick_ms"))
        )
        normalized["sent_kib_per_sec"] = self._as_float(
            sample.get("sent_kib_per_sec", sample.get("sent_kbps"))
        )
        normalized["received_kib_per_sec"] = self._as_float(
            sample.get("received_kib_per_sec", sample.get("received_kbps"))
        )
        normalized["sent_packets_per_sec"] = self._as_float(sample.get("sent_packets_per_sec"))
        normalized["received_packets_per_sec"] = self._as_float(sample.get("received_packets_per_sec"))
        normalized["server_pid"] = self._as_int(sample.get("server_pid"), 0)
        normalized["peers"] = self._normalize_peers(sample.get("peers", []))
        normalized["summary"] = self._build_summary(normalized["peers"])

        self._process_monitor.update_pid(normalized["server_pid"])
        normalized.update(self._process_monitor.collect())
        return normalized

    def _normalize_peers(self, peers: Any) -> list[dict[str, Any]]:
        if not isinstance(peers, list):
            return []

        normalized_peers: list[dict[str, Any]] = []
        for peer in peers:
            if not isinstance(peer, dict):
                continue

            normalized_peers.append(
                {
                    "peer_id": self._as_int(peer.get("peer_id"), 0),
                    "rtt_ms": self._as_float(peer.get("rtt_ms")),
                    "last_rtt_ms": self._as_float(peer.get("last_rtt_ms")),
                    "rtt_variance_ms": self._as_float(peer.get("rtt_variance_ms")),
                    "packet_loss_percent": self._as_float(peer.get("packet_loss_percent")),
                    "app_ping_ms": self._as_float(peer.get("app_ping_ms")),
                }
            )

        normalized_peers.sort(key=lambda peer: peer["peer_id"])
        return normalized_peers

    def _build_summary(self, peers: list[dict[str, Any]]) -> dict[str, Any]:
        rtt_values = [value for value in (peer.get("rtt_ms") for peer in peers) if isinstance(value, (int, float))]
        loss_values = [value for value in (peer.get("packet_loss_percent") for peer in peers) if isinstance(value, (int, float))]
        ping_values = [value for value in (peer.get("app_ping_ms") for peer in peers) if isinstance(value, (int, float))]

        return {
            "avg_rtt_ms": self._average(rtt_values),
            "max_rtt_ms": max(rtt_values) if rtt_values else None,
            "avg_packet_loss_percent": self._average(loss_values),
            "max_packet_loss_percent": max(loss_values) if loss_values else None,
            "avg_app_ping_ms": self._average(ping_values),
            "max_app_ping_ms": max(ping_values) if ping_values else None,
        }

    def _average(self, values: list[float]) -> float | None:
        if not values:
            return None
        return sum(values) / len(values)

    def _as_int(self, value: Any, fallback: int) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return fallback

    def _as_float(self, value: Any) -> float | None:
        if value is None:
            return None

        try:
            return float(value)
        except (TypeError, ValueError):
            return None
