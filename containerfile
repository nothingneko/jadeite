ARG ARCH=amd64
ARG HADRON_IMAGE=ghcr.io/kairos-io/hadron:v0.5.1

# runs on the build host's native arch
FROM --platform=$BUILDPLATFORM curlimages/curl:latest AS podman-static-fetch
ARG ARCH
USER root
RUN curl -fsSL -o /tmp/podman-static.tar.gz \
      "https://github.com/mgoltzsche/podman-static/releases/latest/download/podman-linux-${ARCH}.tar.gz"

FROM quay.io/kairos/kairos-init:latest AS kairos-init

FROM --platform=linux/${ARCH} ${HADRON_IMAGE} AS base

ARG VERSION=0.1.0
ARG MODEL=generic
ARG TRUSTED_BOOT=false

COPY --from=podman-static-fetch /tmp/podman-static.tar.gz /tmp/podman-static.tar.gz
RUN mkdir -p /tmp/podman-extract && \
    tar -xzf /tmp/podman-static.tar.gz -C /tmp/podman-extract --strip-components=1 && \
    cp -a /tmp/podman-extract/usr/. /usr/ && \
    cp -a /tmp/podman-extract/etc/. /etc/ && \
    rm -rf /tmp/podman-static.tar.gz /tmp/podman-extract && \
    for b in podman crun conmon netavark aardvark-dns catatonit fuse-overlayfs pasta; do \
      if [ -x "/usr/local/bin/$b" ] && [ ! -e "/usr/bin/$b" ]; then \
        ln -s "/usr/local/bin/$b" "/usr/bin/$b"; \
      fi; \
    done

RUN mkdir -p /etc/systemd/system/sockets.target.wants && \
    ln -sf /usr/lib/systemd/system/podman.socket \
        /etc/systemd/system/sockets.target.wants/podman.socket || true

RUN --mount=type=bind,from=kairos-init,src=/kairos-init,dst=/kairos-init \
    /kairos-init -l debug -s install -m "${MODEL}" -t "${TRUSTED_BOOT}" --version "${VERSION}" && \
    /kairos-init -l debug -s init    -m "${MODEL}" -t "${TRUSTED_BOOT}" --version "${VERSION}"

RUN sed -i 's/set display_name="Kairos"/set display_name="jadeite"/' /etc/cos/grub.cfg && \
    printf '\n  __ _  __| |  ___  (_) |_ ___ \n / _` |/ _` | / _ \\ | | __/ _ \\\n| (_| | (_| ||  __/ | | ||  __/\n \\__,_|\\__,_| \\___| |_|\\__\\___|\n\n' > /etc/issue.d/01-KAIROS && \
    printf 'welcome to jadeite!\n\npodman host for embedded devices\n\nbuilt with love in minneapolis (by catgirls! :3)\n₍^. .^₎⟆' > /etc/motd && \
    mkdir -p /etc/kairos/branding && \
    printf 'jadeite installer.\n' > /etc/kairos/branding/interactive_install_text && \
    printf 'jadeite recovery mode\n' > /etc/kairos/branding/recovery_text && \
    printf 'welcome to jadeite!\nnode will automatically reset in a seccy.\n\npress any key to cancel. to do it now run '"'"'kairos reset'"'"'.\n\resetting in 60 seconds...\n' > /etc/kairos/branding/reset_text && \
    printf 'welcome to jadeite!\nenrollment is starting.\n' > /etc/kairos/branding/install_text
