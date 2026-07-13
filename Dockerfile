FROM debian:bookworm-slim AS builder

ARG ZIG_VERSION=0.16.0
ARG ZIG_ARCH=aarch64

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        jq \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fL -o /tmp/zig.tar.xz "https://ziglang.org/download/${ZIG_VERSION}/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}.tar.xz" \
    && tar -xf /tmp/zig.tar.xz -C /usr/local \
    && rm /tmp/zig.tar.xz \
    && mv "/usr/local/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}" /usr/local/zig
ENV PATH="/usr/local/zig:${PATH}"

WORKDIR /app
COPY . .

RUN zig build

# `docker build --target test` - has the full toolchain (jq, git, curl),
# needed to run tests/*.sh.
FROM builder AS test
CMD ["./scripts/test_e2e.sh"]

# `docker build` (default, last stage) - just the compiled binary and
# config, no Zig/jq/git/curl. This is what actually runs the server.
FROM debian:bookworm-slim AS runtime
WORKDIR /app
COPY --from=builder /app/zig-out/bin/rmc ./zig-out/bin/rmc
COPY --from=builder /app/config.yaml ./config.yaml
EXPOSE 5882
CMD ["./zig-out/bin/rmc"]
