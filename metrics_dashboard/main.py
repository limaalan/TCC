from __future__ import annotations

import argparse
import asyncio
from contextlib import asynccontextmanager, suppress
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
import uvicorn

from metrics_store import MetricsStore
from udp_receiver import MetricsUdpReceiver


STATIC_DIR = Path(__file__).resolve().parent / "static"


@dataclass(slots=True)
class DashboardConfig:
    udp_host: str
    udp_port: int
    http_host: str
    http_port: int
    history_size: int


class ConnectionManager:
    def __init__(self) -> None:
        self._connections: set[WebSocket] = set()

    async def connect(self, websocket: WebSocket) -> None:
        await websocket.accept()
        self._connections.add(websocket)

    def disconnect(self, websocket: WebSocket) -> None:
        self._connections.discard(websocket)

    async def broadcast(self, message: dict[str, Any]) -> None:
        stale_connections: list[WebSocket] = []
        for websocket in list(self._connections):
            try:
                await websocket.send_json(message)
            except Exception:
                stale_connections.append(websocket)

        for websocket in stale_connections:
            self.disconnect(websocket)


def create_app(config: DashboardConfig) -> FastAPI:
    store = MetricsStore(max_samples=config.history_size)
    connections = ConnectionManager()

    async def broadcast_sample(sample: dict[str, Any]) -> None:
        await connections.broadcast({"type": "sample", "sample": sample})

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        receiver = MetricsUdpReceiver(
            host=config.udp_host,
            port=config.udp_port,
            store=store,
            on_sample=broadcast_sample,
        )
        receiver_task = asyncio.create_task(receiver.run())

        app.state.config = config
        app.state.store = store
        app.state.connections = connections
        app.state.receiver_task = receiver_task

        try:
            yield
        finally:
            receiver_task.cancel()
            with suppress(asyncio.CancelledError):
                await receiver_task

    app = FastAPI(title="TCC Metrics Dashboard", lifespan=lifespan)
    app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")

    @app.get("/")
    async def index() -> FileResponse:
        return FileResponse(STATIC_DIR / "index.html")

    @app.get("/api/latest")
    async def latest() -> dict[str, Any]:
        sample = store.get_latest()
        if sample is None:
            return store.build_waiting_payload(config.udp_host, config.udp_port)

        return {
            "status": "receiving",
            "sample": sample,
            "config": {
                "udp_host": config.udp_host,
                "udp_port": config.udp_port,
                "history_size": config.history_size,
            },
        }

    @app.get("/api/history")
    async def history() -> dict[str, Any]:
        history_samples = store.get_history()
        latest_sample = history_samples[-1] if history_samples else None

        if latest_sample is None:
            return store.build_waiting_payload(config.udp_host, config.udp_port)

        return {
            "status": "receiving",
            "sample": latest_sample,
            "history": history_samples,
            "config": {
                "udp_host": config.udp_host,
                "udp_port": config.udp_port,
                "history_size": config.history_size,
            },
        }

    @app.websocket("/ws")
    async def websocket_endpoint(websocket: WebSocket) -> None:
        await connections.connect(websocket)
        try:
            initial_sample = store.get_latest()
            if initial_sample is None:
                await websocket.send_json(
                    {
                        "type": "waiting",
                        "payload": store.build_waiting_payload(config.udp_host, config.udp_port),
                    }
                )
            else:
                await websocket.send_json({"type": "sample", "sample": initial_sample})

            while True:
                await websocket.receive_text()
        except WebSocketDisconnect:
            connections.disconnect(websocket)
        except Exception:
            connections.disconnect(websocket)

    return app


def parse_args() -> DashboardConfig:
    parser = argparse.ArgumentParser(description="Realtime local dashboard for Godot metrics.")
    parser.add_argument("--udp-host", default="127.0.0.1")
    parser.add_argument("--udp-port", type=int, default=8765)
    parser.add_argument("--http-host", default="127.0.0.1")
    parser.add_argument("--http-port", type=int, default=8000)
    parser.add_argument("--history-size", type=int, default=300)
    args = parser.parse_args()
    return DashboardConfig(
        udp_host=args.udp_host,
        udp_port=args.udp_port,
        http_host=args.http_host,
        http_port=args.http_port,
        history_size=max(args.history_size, 10),
    )


if __name__ == "__main__":
    config = parse_args()
    uvicorn.run(
        create_app(config),
        host=config.http_host,
        port=config.http_port,
        log_level="info",
    )
