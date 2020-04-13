# Dockerized IB Trader Workstation (TWS)

## Abstract

This is a docker container for IB TWS that includes the requisite dependencies.

[Trader Workstation](https://www.interactivebrokers.com/en/index.php?f=14099&ns=T#tws-software) (TWS) is [Interactive Brokers](https://www.interactivebrokers.com/) trading platform. The platform is a Java application which IB packages in the form of an [install4j](https://www.ej-technologies.com/products/install4j/overview.html)-based installer made available for download from its website. The installer also deploys a suitable version of the Oracle Java JRE.

The container is based on Ubuntu (xenial) and includes the library dependencies, as well as the Firefox web browser and the [Noto Sans Mono Medium](https://www.google.com/get/noto/#sans-mono) font. Several configuration tweaks are also applied to ensure optimal font rendering and performance.

*Due to licensing restrictions, this container is only made available as a Dockerfile to be built by the end user, and not as a ready-to-run pre-built container.*

## Basic usage

Begin by checking out the Dockerfile and building the container:

```shell
git clone https://github.com/wk/docker-ib-tws.git
sudo docker build -t ib-tws docker-ib-tws
```

Three release trains (stable, latest, beta) of IB TWS are available for two architectures (x86, x64). By default, the container will include a build of the latest train for x64 architecture. This can be modified by setting the _version_ and _arch_ arguments at build time. For example, you can build a container that includes the current beta release instead:

```shell
sudo docker build --build-arg version=beta -t ib-tws docker-ib-tws
```

You will typically want to launch the container locally on a host with a X server. Certain arguments must be passed to the container for X authentication and display to succeed. This has been tested on Ubuntu and Debian hosts:

First, authorize X socket connectivity:

```shell
xhost +local:root
```

Then, launch the container:

```shell
sudo docker run --name=ib-tws --detach=true -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix --device /dev/dri --device /dev/snd --device /dev/vga_arbiter ib-tws
```

After the initial invocation, you can re-start the container as following:

```shell
sudo docker start ib-tws
```

The container will stop when the application terminates.

## Configuration

By default, an empty jts.ini file is injected into the container. This file can be replaced with user-supplied configuration prior to building the container in order to override some defaults prior to first run.

## API connectivity

IB TWS can expose a TCP port on which an API is presented. Since IB TWS 954, two ports are used by default. In live trading mode, the API is presented on port 7496, in paper trading mode, the API is presented on port 7497.

You can expose these ports by initially launching the container as so:

```shell
sudo docker run --name=ib-tws --detach=true --publish=7496:7496 --publish=7497:7497 -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix --device /dev/dri --device /dev/snd --device /dev/vga_arbiter ib-tws
```

## Caveats

* Due to docker's one process per container model, the install4j upgrade functionality will not succeed. Instead, the container should be rebuilt when a new release is available upstream.
* Multimedia features, such as voice alerts and Bloomberg TV may not function on hosts other than Ubuntu due to sound and video device permission mapping differences.

## Disclaimer

This method of deploying IB TWS is not endorsed nor supported by IB.
