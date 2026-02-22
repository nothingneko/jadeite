FROM ghcr.io/ultramarine-linux/plasma-bootc:main

RUN rpm -e --nodeps sudo

RUN --mount=type=cache,target=/var/cache dnf do -y \
    --setopt protected_packages= \
    --allowerasing \
    --action=install \
    run0-sudo-shim
