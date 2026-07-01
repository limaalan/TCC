from __future__ import annotations

import asyncio
import json
import socket
from typing import Any, Awaitable, Callable

from metrics_store import MetricsStore


class MetricsUdpReceiver:
    def __init__(
        self,
        host: str,
        port: int,
        store: MetricsStore,
        on_sample: Callable[[dict[str, Any]], Awaitable[None]] | None = None,
    ) -> None:
        self.host = host
        self.port = port
        self.store = store
        self.on_sample = on_sample

    async def run(self) -> None:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.bind((self.host, self.port))
        sock.setblocking(False)
        loop = asyncio.get_running_loop()

        try:
            while True:
                data, _address = await loop.sock_recvfrom(sock, 65535)
                try:
                    payload = json.loads(data.decode("utf-8"))
                except (UnicodeDecodeError, json.JSONDecodeError):
                    continue

                if not isinstance(payload, dict):
                    continue

                normalized_sample = self.store.add_sample(payload)
                if self.on_sample is not None:
                    await self.on_sample(normalized_sample)
        finally:
            sock.close()
