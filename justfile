image := "localhost/jadeite:latest"
output := "output"
type := "qcow2"

build:
    sudo podman build -t {{ image }} .

disk: build
    mkdir -p {{ output }}
    sudo podman run \
        --rm -it --privileged \
        --pull=newer \
        --security-opt label=type:unconfined_t \
        -v ./image-builder.config.toml:/config.toml:ro \
        -v ./{{ output }}:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        quay.io/centos-bootc/bootc-image-builder:latest \
        --type {{ type }} \
        --rootfs ext4 \
        --config /config.toml \
        {{ image }}

vm: disk
    qemu-system-x86_64 \
        -enable-kvm \
        -m 4096 \
        -cpu host \
        -smp 2 \
        -drive file={{ output }}/qcow2/disk.qcow2,format=qcow2 \
        -nic user,model=virtio \
        -vga virtio \
        -display gtk

iso:
    mkdir -p {{ output }}
    sudo podman run \
        --rm -it --privileged \
        --pull=newer \
        --security-opt label=type:unconfined_t \
        -v ./image-builder.config.toml:/config.toml:ro \
        -v ./{{ output }}:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        quay.io/centos-bootc/bootc-image-builder:latest \
        --type anaconda-iso \
        --rootfs xfs \
        --config /config.toml \
        {{ image }}
