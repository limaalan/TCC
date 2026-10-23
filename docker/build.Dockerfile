FROM python:3.12-slim-bookworm@sha256:6a0e06f5ba0b373d051aabd3fffb9b873f27f9a2a3a14bcbe37dee6f0e3bbc70

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git libfontconfig1 libx11-6 libxcursor1 libxinerama1 \
    libxi6 libxrandr2 libgl1 libasound2 libpulse0 \
    && rm -rf /var/lib/apt/lists/*
COPY docker/install_godot.py /opt/install_godot.py
RUN python3 /opt/install_godot.py && godot --headless --version
ENV GODOT_SILENCE_ROOT_WARNING=1 PYTHONDONTWRITEBYTECODE=1 \
    HOME=/tmp/builder-home \
    XDG_DATA_HOME=/tmp/builder-home/.local/share \
    XDG_CONFIG_HOME=/tmp/builder-home/.config
WORKDIR /source
ENTRYPOINT ["bash", "/source/scripts/build-container.sh"]
