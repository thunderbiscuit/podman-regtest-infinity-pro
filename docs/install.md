# Install

!!! info
    The [Using Podman Containers for Regtest Bitcoin Development blog post](https://thunderbiscuit.com/posts/podman-bitcoin/) has all the details on Podman, machines, images, and containers.

First, make sure you have [Podman](https://podman.io/) and [just](https://just.systems/) installed on your computer.

Then create a directory called `podman` somewhere on your machine and clone the repo:

```shell
mkdir ~/podman/
git clone https://github.com/thunderbiscuit/podman-regtest-infinity-pro.git
```

Make sure you have a podman machine enabled with sufficient resources. 

```shell
# Create a machine called regtest
podman machine init --cpus 4 --memory 4096 --disk-size 20 regtest
```

Get into the container's directory and build the container. Note that you must specify a `BITCOIN_VERSION` and `TARGET_ARCH` to use the bitcoin core version you need using the `--build-arg` argument on the `podman` command.

```shell
cd regtest-in-a-pod/
podman machine start regtest
podman --connection regtest build --build-arg BITCOIN_VERSION=28.1 --build-arg TARGET_ARCH=x86_64-linux-gnu --tag localhost/regtest:v1.0.0 --file ./Containerfile
podman --connection regtest create --name RegtestBitcoinEnv --publish 18443:18443 --publish 18444:18444 --publish 3002:3002 --publish 3003:3003 --publish 60401:60401 localhost/regtest:v1.1.0
```

You're now ready to start using the container! See the [Usage](./usage.md) page for all the details.
