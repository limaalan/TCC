FROM debian:bookworm-slim@sha256:7ff6ba31527b9e336162fa061746c366c4b2032f4d2cff2078bea43f78efe3f8

RUN apt-get update && apt-get install -y --no-install-recommends libfontconfig1 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 10001 game
ARG RELEASE_DIR=build/releases/local
COPY --chown=game:game ${RELEASE_DIR}/server-linux/ /app/
RUN chmod 755 /app/jumpnshoot-server.x86_64
USER game
WORKDIR /app
EXPOSE 7777/udp
ENTRYPOINT ["stdbuf", "-oL", "-eL", "/app/jumpnshoot-server.x86_64", "--headless", "--"]
CMD ["--port=7777"]
