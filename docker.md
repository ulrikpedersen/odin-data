Basic docker commands:


Development
===========

To build the development image with the basic dependencies installed and the odin-data cloned and built
on a named branch (optional using --build-arg, default is master)

```docker build --target build --build-arg BRANCH=docker -t odin-dev .```

The image can be run either with the built-in clone of odin-data - or overridden by a local clone on the
host-machine, like this: (remove the -v option-arg to use image built-in clone)

Run the development image with a local clone of Odin-data in cwd:
```docker run --rm -it -v `pwd`:/src/odin-data/ odin-dev``` 

Runtime
=======

Build the small run-time image 'odin-run' with this docker invocation (the --build-arg BRANCH is optional):

```docker build --build-arg BRANCH=docker -t odin-run .```

Then run the image interactively with:

```docker run --rm -it odin-run```

Read on for more complex combinations of FR and FP images, with SHM IPC etc...

Getting the containers to share IPC SHM is trivial, using the 'run --ipc' option:

```
docker run -d --rm --name odinfr odinfr odin-run frameReceiver -t DummyUDP --path /usr/local/lib/ --sharedbuf FrameReceiverBuffer1
docker run --rm -it --name odinfp --ipc container:odinfr odin-run frameProcessor -d Dummy 
```

Getting hostnames visible across containers is a bit more tricky. Don't use the --link option -its deprecated.
Instead create a user-defined (bridge) network (odin-net):

docker network create odin-net
docker run -d --rm --name odinfr --network odin-net --network-alias odinfr odin-run frameReceiver -t DummyUDP --path /usr/local/lib/ --sharedbuf FrameReceiverBuffer1
docker run --rm -it --name odinfp --network odin-net --ipc container:odinfr odin-run frameProcessor -d Dummy

Note that containers have to be joined to the network (--network odin-net) and use --network-alias to define 
a hostname that can be seen across containers.


ISSUE:
-------
 the hostname/network mapping - or maybe my understanding of how FR+FP connect the zmq channels isn't quite working:

When starting the docker-compose.yml:

```
[ulrik@macpro odin]$ docker-compose -f odin-data/docker-compose.yml up
Creating network "odindata_odin-net" with the default driver
Creating odin-fr ... done
Creating odin-fp ... done
Attaching to odin-fr, odin-fp
odin-fr   | 1 [0x7f2e7036c780] INFO FR.App null - Running frame receiver
odin-fp   | 1 [0x7fc727242700] DEBUG FP.FrameProcessorController null - Running IPC thread service
odin-fr   | 3 [0x7f2e7036c780] INFO FR.Controller null - Loading decoder plugin DummyUDPFrameDecoder from /usr/local/lib/libDummyUDPFrameDecoder.so
odin-fr   | 4 [0x7f2e7036c780] INFO FR.Controller null - Created DummyUDPFrameDecoder frame decoder instance
odin-fp   | 4 [0x7fc72da41780] DEBUG FP.FrameProcessorController null - Constructing FrameProcessorController
odin-fp   | 4 [0x7fc72da41780] DEBUG FP.FrameProcessorController null - Connecting meta RX channel to endpoint: inproc://meta_rx
odin-fp   | 4 [0x7fc72da41780] DEBUG FP.FrameProcessorController null - Configuration submitted: {"params":{"ctrl_endpoint":"tcp://odinfr:5000"},"msg_type":"illegal","msg_val":"illegal","id":0,"timestamp":"2018-04-01T15:28:29.888271"}
odin-fp   | 4 [0x7fc72da41780] DEBUG FP.FrameProcessorController null - Connecting control channel to endpoint: tcp://odinfr:5000
odin-fp   | 6 [0x7fc72da41780] ERROR FP.App null - No such device
odin-fp exited with code 0

^CGracefully stopping... (press Ctrl+C again to force)
Stopping odin-fr ... done
[ulrik@macpro odin]$ 
[ulrik@macpro odin]$ docker-compose -f odin-data/docker-compose.yml down
Removing odin-fp ... done
Removing odin-fr ... done
Removing network odindata_odin-net
```