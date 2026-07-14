# build jadeite
#
# usage:
#   just build-amd64 / build-rpi4 / build-rpi3 / build-all   — build images locally, no push
#   just iso-amd64                                            — push amd64, then build an ISO
#   just raw-rpi4 / raw-rpi3                                  — push arm variant, then build a raw disk image
#   just release                                              — all of the above, everything
#
# cross-arch builds need qemu-user-static + binfmt registered once per host:
#   sudo dnf install qemu-user-static
#   sudo podman run --rm --privileged multiarch/qemu-user-static --reset -p yes
# (must be real root — binfmt_misc is global and rootless podman can't register it)

registry_path := env_var_or_default("REGISTRY_PATH", "ghcr.io/nothingneko/jadeite")
version := env_var_or_default("VERSION", trim(`cat VERSION`))
auroraboot_version := "v0.25.2"

default: build-all

build-amd64:
    podman build \
        --platform linux/amd64 \
        --build-arg ARCH=amd64 \
        --build-arg MODEL=generic \
        --build-arg HADRON_IMAGE=ghcr.io/kairos-io/hadron:v0.5.1 \
        --build-arg VERSION={{version}} \
        --build-arg TRUSTED_BOOT=false \
        -t {{registry_path}}:{{version}}-amd64 \
        -f containerfile .

build-rpi4:
    podman build \
        --platform linux/arm64 \
        --build-arg ARCH=arm64 \
        --build-arg MODEL=rpi4 \
        --build-arg HADRON_IMAGE=ghcr.io/kairos-io/hadron:v0.5.1 \
        --build-arg VERSION={{version}} \
        --build-arg TRUSTED_BOOT=false \
        -t {{registry_path}}:{{version}}-rpi4 \
        -f containerfile .

build-rpi3:
    podman build \
        --platform linux/arm64 \
        --build-arg ARCH=arm64 \
        --build-arg MODEL=rpi3 \
        --build-arg HADRON_IMAGE=ghcr.io/kairos-io/hadron:v0.5.1 \
        --build-arg VERSION={{version}} \
        --build-arg TRUSTED_BOOT=false \
        -t {{registry_path}}:{{version}}-rpi3 \
        -f containerfile .

build-all: build-amd64 build-rpi4 build-rpi3

push-amd64: build-amd64
    podman push {{registry_path}}:{{version}}-amd64

push-rpi4: build-rpi4
    podman push {{registry_path}}:{{version}}-rpi4

push-rpi3: build-rpi3
    podman push {{registry_path}}:{{version}}-rpi3

iso-amd64: push-amd64
    mkdir -p build
    podman run --rm --privileged \
        -v "$PWD"/build:/output \
        quay.io/kairos/auroraboot:{{auroraboot_version}} \
        build-iso --output /output/ --arch amd64 --override-name jadeite \
        docker://{{registry_path}}:{{version}}-amd64

raw-rpi4: push-rpi4
    mkdir -p build-rpi4
    podman run --rm --privileged \
        -v "$PWD"/build-rpi4:/aurora \
        quay.io/kairos/auroraboot:{{auroraboot_version}} \
        --debug \
        --set "disable_http_server=true" \
        --set "disable_netboot=true" \
        --set "disk.efi=true" \
        --set "container_image=docker://{{registry_path}}:{{version}}-rpi4" \
        --set "state_dir=/aurora"

raw-rpi3: push-rpi3
    mkdir -p build-rpi3
    podman run --rm --privileged \
        -v "$PWD"/build-rpi3:/aurora \
        quay.io/kairos/auroraboot:{{auroraboot_version}} \
        --debug \
        --set "disable_http_server=true" \
        --set "disable_netboot=true" \
        --set "disk.efi=true" \
        --set "container_image=docker://{{registry_path}}:{{version}}-rpi3" \
        --set "state_dir=/aurora"

release: iso-amd64 raw-rpi4 raw-rpi3
