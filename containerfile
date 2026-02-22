FROM ghcr.io/ultramarine-linux/gnome-bootc:main

RUN rpm -e --nodeps sudo

RUN --mount=type=cache,target=/var/cache dnf do -y \
    --setopt protected_packages= \
    --allowerasing \
    --action=install \
    zed \
    helium-browser-bin \

RUN --mount=type=cache,target=/var/cache dnf do -y \
    --no-best \
    --allowerasing \
    --action=remove \
    firefox \

LABEL readymade.prettyname="Jadeite"
