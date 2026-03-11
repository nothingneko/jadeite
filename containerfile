FROM ghcr.io/ultramarine-linux/gnome-bootc:main

RUN --mount=type=cache,target=/var/cache rpm --import https://downloads.flox.dev/by-env/stable/rpm/flox-archive-keyring.asc

RUN --mount=type=cache,target=/var/cache dnf install https://downloads.flox.dev/by-env/stable/rpm/flox-1.10.0.x86_64-linux.rpm

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
    vicinae \
    btop \
    steam

RUN --mount=type=cache,target=/var/cache dnf do -y \
    --no-best \
    --allowerasing \
    --action=remove \
    firefox

LABEL readymade.prettyname="Jadeite"
