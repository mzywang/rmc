FROM debian:bookworm-slim

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

EXPOSE 5882

CMD ["sh", "-c", "zig build && ./scripts/test_e2e.sh"]
