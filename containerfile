FROM ghcr.io/ultramarine-linux/gnome-bootc:main

RUN --mount=type=cache,target=/var/cache rpm --import https://downloads.flox.dev/by-env/stable/rpm/flox-archive-keyring.asc

RUN --mount=type=cache,target=/var/cache dnf install --assumeyes https://downloads.flox.dev/by-env/stable/rpm/flox-1.10.0.x86_64-linux.rpm

RUN ln -s /nix /var/nix

RUN echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://downloads.1password.com/linux/keys/1password.asc" \
    > /etc/yum.repos.d/1password.repo

RUN --mount=type=cache,target=/var/cache dnf do -y \
    --setopt protected_packages= \
    --allowerasing \
    --action=install \
    zed \
    ghostty \
    helium-browser-bin \
    anda \
    anda-srpm-macros \
    vicinae \
    steam \
    1password

RUN --mount=type=cache,target=/var/cache dnf do -y \
    --no-best \
    --allowerasing \
    --action=remove \
    firefox

LABEL readymade.prettyname="Jadeite"
