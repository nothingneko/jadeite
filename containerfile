FROM ghcr.io/ultramarine-linux/gnome-bootc:main

RUN --mount=type=cache,target=/var/cache dnf do -y \
    --setopt protected_packages= \
    --allowerasing \
    --action=install \
    zed \
    helium-browser-bin \
    anda \
    anda-srpm-macros \
    katsu \
    cargo \
    go \
    gcc \
    vicinae

RUN --mount=type=cache,target=/var/cache dnf do -y \
    --no-best \
    --allowerasing \
    --action=remove \
    firefox

LABEL readymade.prettyname="Jadeite"
