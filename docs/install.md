# Install

!!! info
    The [Using Podman Containers for Regtest Bitcoin Development blog post](https://thunderbiscuit.com/posts/podman-bitcoin/) has all the details on Podman, machines, images, and containers.

First, make sure you have [Podman](https://podman.io/), [just](https://just.systems/), and [jq](https://jqlang.github.io/jq/) installed on your computer. Optionally, install [qrencode](https://github.com/fukuchi/libqrencode) (`brew install qrencode`) to get a scannable QR code from the `just services` command.

Then create a directory called `podman` somewhere on your machine and clone the repo:

```shell
mkdir ~/podman/
cd ~/podman/
git clone https://github.com/thunderbiscuit/podman-regtest-infinity-pro.git
```

Make sure you have a podman machine enabled with sufficient resources.

!!! warning "Minimum Machine Requirements"
    Building this container requires compiling two Rust projects (electrs and fbbe) from source, which generates several gigabytes of build artifacts. The minimum recommended machine configuration is:

    - **CPUs**: 4
    - **Memory**: 4096 MB (4 GB)
    - **Disk Size**: 20 GB minimum

    The build process includes cleanup steps to remove intermediate build artifacts and keep disk usage under 20GB. If you experience "no space left on device" errors during the build, try increasing the disk size to 50GB or cleaning up old images with `podman system prune -a`.

```shell
# Create a machine called regtest
podman machine init --cpus 4 --memory 4096 --disk-size 20 regtest
```

Get into the container's directory and build the container. Note that you must specify a `BITCOIN_VERSION` and `TARGET_ARCH` to use the bitcoin core version you need using the `--build-arg` argument on the `podman` command.

```shell
cd podman-regtest-infinity-pro/
podman machine start regtest
podman --connection regtest build --build-arg BITCOIN_VERSION=29.2 --build-arg TARGET_ARCH=x86_64-linux-gnu --tag localhost/regtest-infinity-pro:0.3.0 --file ./Containerfile
podman --connection regtest create --name RegtestInfinityPro --publish 0.0.0.0:18443:18443 --publish 0.0.0.0:18444:18444 --publish 0.0.0.0:3002:3002 --publish 0.0.0.0:3003:3003 --publish 0.0.0.0:60401:60401 localhost/regtest-infinity-pro:0.3.0

# Delete all intermediate images not required by the machine anymore
podman --connection regtest image prune -a
```

!!! tip "Local network exposure"
    Publishing the ports on `0.0.0.0` makes the services reachable from other devices on your local network (see [Local Network Access](./usage.md#local-network-access)) — this is also what `--publish 18443:18443` without an explicit IP does. If you'd rather keep a port accessible only from your own machine, publish it on the loopback interface instead, e.g. `--publish 127.0.0.1:18443:18443`. The RPC port (`18443`) is a good candidate for this hardening: it uses well-known credentials and gives full control of the node, and none of the phone-facing services need it.

You're now ready to start using the container! See the [Usage](./usage.md) page for all the details.
