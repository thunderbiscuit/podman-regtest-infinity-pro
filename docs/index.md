# A Full Regtest Setup Available on Command

This isn't just your run-of-the-mill, typical Podman Regtest Infinity setup... _**it's the Podman Regtest Infinity Pro**_!

The goal of this project is to provide bitcoin software developers a simple and powerful regtest setup always at the ready and easy to power up and down in just a few seconds. For a quick overview of how the setup works once its enabled, [check out this YouTube video](https://www.youtube.com/watch?v=zofo5k9Cwcg).

Once up, the [Podman container](https://podman.io/) offers:

- A full bitcoin core node in daemon mode
- An Electrum server ready to connect to
- An Esplora server ready to connect to
- A simple block explorer
- The node has compact block filter enabled
- Awesome `just` commands to get stuff done

<br>

Here are examples of what you can do from your command line once the container is up and running:

```shell
# Send coins
just sendto <address>

# Mine any number of blocks
just mine 21

# See logs for different services
just bitcoindlogs
```
