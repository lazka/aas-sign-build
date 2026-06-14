FROM ubuntu:24.04 AS build

# https://github.com/skeeto/aas-sign/releases
ARG AAS_SIGN_VERSION=v1.1.0
ARG AAS_SIGN_SHA256=33797c3866c0f61ddde1ec60951b43c77da6edd1376c0969fcb8f18a11bc2a87

# https://github.com/nlohmann/json/releases
ARG JSON_VERSION=v3.12.0
ARG JSON_SHA256=42f6e95cad6ec532fd372391373363b62a14af6d771056dbfc86160e6dfff7aa

# https://github.com/Mbed-TLS/mbedtls/releases
ARG MBEDTLS_VERSION=mbedtls-3.6.6
ARG MBEDTLS_SHA256=8fb65fae8dcae5840f793c0a334860a411f884cc537ea290ce1c52bb64ca007a

ARG SOURCE_DATE_EPOCH=1777817234

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C
ENV TZ=UTC
ENV SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH}
ENV CFLAGS="-O2 -DNDEBUG -ffile-prefix-map=/work=."
ENV CXXFLAGS="-O2 -DNDEBUG -ffile-prefix-map=/work=."

WORKDIR /work

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bzip2 \
      build-essential \
      ca-certificates \
      cmake \
      curl \
      ninja-build \
      xz-utils \
 && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    curl -L --fail --silent --show-error \
      "https://github.com/skeeto/aas-sign/archive/refs/tags/${AAS_SIGN_VERSION}.tar.gz" \
      -o aas-sign.tar.gz; \
    echo "${AAS_SIGN_SHA256}  aas-sign.tar.gz" | sha256sum -c -; \
    mkdir src; \
    tar -xf aas-sign.tar.gz --strip-components=1 -C src; \
    curl -L --fail --silent --show-error \
      "https://github.com/nlohmann/json/releases/download/${JSON_VERSION}/json.tar.xz" \
      -o json.tar.xz; \
    echo "${JSON_SHA256}  json.tar.xz" | sha256sum -c -; \
    mkdir -p src/deps/json; \
    tar -xf json.tar.xz --strip-components=1 -C src/deps/json; \
    curl -L --fail --silent --show-error \
      "https://github.com/Mbed-TLS/mbedtls/releases/download/${MBEDTLS_VERSION}/${MBEDTLS_VERSION}.tar.bz2" \
      -o mbedtls.tar.bz2; \
    echo "${MBEDTLS_SHA256}  mbedtls.tar.bz2" | sha256sum -c -; \
    mkdir -p src/deps/mbedtls; \
    tar -xf mbedtls.tar.bz2 --strip-components=1 -C src/deps/mbedtls

RUN cmake -S src -B build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DDEPS=FETCH \
      -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
      -DCMAKE_EXE_LINKER_FLAGS="-static-libstdc++ -static-libgcc" \
 && cmake --build build -j"$(nproc)" \
 && strip build/aas-sign \
 && install -D -m 0755 build/aas-sign /out/aas-sign

FROM scratch AS artifact

COPY --from=build /out/ /
