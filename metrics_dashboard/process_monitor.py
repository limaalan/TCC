from __future__ import annotations

from typing import Any

import psutil


class ProcessMonitor:
    def __init__(self) -> None:
        self._current_pid: int | None = None
        self._process: psutil.Process | None = None

    def update_pid(self, pid: int | None) -> None:
        if pid is None or pid <= 0:
            return

        if pid == self._current_pid and self._process is not None:
            return

        try:
            process = psutil.Process(pid)
            process.cpu_percent(interval=None)
        except psutil.Error:
            self._current_pid = None
            self._process = None
            return

        self._current_pid = pid
        self._process = process

    def collect(self) -> dict[str, Any]:
        if self._process is None:
            return {
                "process_cpu_percent": None,
                "process_memory_rss_mb": None,
            }

        try:
            memory = self._process.memory_info()
            return {
                "process_cpu_percent": self._process.cpu_percent(interval=None),
                "process_memory_rss_mb": memory.rss / 1024 / 1024,
            }
        except psutil.Error:
            self._current_pid = None
            self._process = None
            return {
                "process_cpu_percent": None,
                "process_memory_rss_mb": None,
            }
