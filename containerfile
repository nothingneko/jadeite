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
    cp -a /tmp/podman-extract/usr/local/. /usr/ && \
    cp -a /tmp/podman-extract/etc/. /etc/ && \
    sed -i 's|/usr/local/bin/fuse-overlayfs|/usr/bin/fuse-overlayfs|' /etc/containers/storage.conf && \
    rm -rf /tmp/podman-static.tar.gz /tmp/podman-extract

RUN mkdir -p /etc/systemd/system/sockets.target.wants && \
    ln -sf /usr/lib/systemd/system/podman.socket \
        /etc/systemd/system/sockets.target.wants/podman.socket || true

RUN --mount=type=bind,from=kairos-init,src=/kairos-init,dst=/kairos-init \
    /kairos-init -l debug -s install -m "${MODEL}" -t "${TRUSTED_BOOT}" --version "${VERSION}" && \
    /kairos-init -l debug -s init    -m "${MODEL}" -t "${TRUSTED_BOOT}" --version "${VERSION}"

COPY 90_jadeite_binds.yaml /system/oem/90_jadeite_binds.yaml

RUN sed -i 's/set display_name="Kairos"/set display_name="jadeite"/' /etc/cos/grub.cfg


COPY branding/os-release          /etc/os-release
COPY branding/issue               /etc/issue.d/01-KAIROS
COPY branding/motd                /etc/motd
COPY branding/interactive_install /etc/kairos/branding/interactive_install_text
COPY branding/recovery            /etc/kairos/branding/recovery_text
COPY branding/reset               /etc/kairos/branding/reset_text
COPY branding/install             /etc/kairos/branding/install_text

COPY jadeite-autoupdate/jadeite-autoupdate.sh /usr/bin/jadeite-autoupdate
COPY jadeite-autoupdate/jadeite-autoupdate.service /etc/systemd/system/jadeite-autoupdate.service
COPY jadeite-autoupdate/jadeite-autoupdate.timer /etc/systemd/system/jadeite-autoupdate.timer
RUN chmod +x /usr/bin/jadeite-autoupdate && \
    systemctl enable jadeite-autoupdate.timer
