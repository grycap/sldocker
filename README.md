# sldocker

We can create Docker images, strip layers from them and join to create a new image made from the files created during independent stages from a Dockerfile.

`sldocker` automates the process strip layers from one image, add to other image and create a new different one.

A working example is included:

```
#!/bin/bash
docker build builds -f builds/Dockerfile.vim -t sldocker:vim
docker build builds -f builds/Dockerfile.nfs -t sldocker:nfs
docker build builds -f builds/Dockerfile.cowsay -t sldocker:cowsay
docker build builds -f builds/Dockerfile.all -t sldocker:all
./sldocker ubuntu:latest sldocker:nfs sldocker:composed -r
./sldocker sldocker:composed sldocker:cowsay sldocker:composed -r
./sldocker sldocker:composed sldocker:vim sldocker:composed -r
docker images sldocker
````

Usage:

```
usage:
    sldocker [ -n <num> ] [ -r ] <src1> <src2> <dst>

    Gets <num> layers from docker image src2 and adds them to src1. The 
      resulting docker image is registered as <dst>

	-n <num> 	- number of last layers to add from docker image src2 
                  to docker image src1. Default: 1
	-r          - remove <dst> docker image if exists
```

SLDocker stands for Strip Layers from Docker images.

## The technique behind sldocker

We can obtain the content of a Docker image by issuing a command like this:

````
$ docker save ubuntu:latest -o ubuntu.tar
```

If we extract the files into a folder

```
$ mkdir ubuntu
$ tar xf ubuntu.tar -C ubuntu
$ cd ubuntu
````

We can see all those files. In particular, we’ll pay attention to manifest.json. That file contains the description of the image:

```
$ cat manifest.json | json_pp
[
 {
 “Layers” : [
 “c9adcff797cd2265d1371a...e7378527a75/layer.tar”,
 “d69dfec63ea3b06516553e...d9f843d49ba/layer.tar”,
 “06c32c985d45dd7d91c0ee...a093b68c269/layer.tar”,
 “f7d431ec58e467db749850...d5e3d0d8a41/layer.tar”
 ],
 “RepoTags” : [
 “ubuntu:latest”
 ],
 “Config” : “ea4c82dcd15a33e3e9c4c3...c4e98387e39.json”
 }
]
```

## How each layer is created
When creating a Docker image, we need to create a Dockerfile in which we state what happens. It is like “installing the things inside the container”. An example follows…
Consider the next file called Dockerfile.vim

```dockerfile
FROM ubuntu:latest
RUN apt update && apt -y dist-upgrade
RUN apt install -y vim — no-install-recommends
```

Now we can create a docker image by issuing the next command:

```
docker build . -f Dockerfile.vim -t sldocker:vim
```

If we save that Docker image and check its manifest file, we’ll see the next things:

```
$ docker save sldocker:vim -o vim.tar
$ mkdir vim
$ tar xf vim.tar -C vim/
$ cat vim/manifest.json | json_pp
[
 {
 “RepoTags” : [
 “sldocker:vim”
 ],
 “Layers” : [
  “c9adcff797cd2265d1371a...e7378527a75/layer.tar”,
  “d69dfec63ea3b06516553e...d9f843d49ba/layer.tar”,
  “06c32c985d45dd7d91c0ee...a093b68c269/layer.tar”,
  “36691ebe02d53adf02bc6b...23acf265885/layer.tar”,
  “f30e5425e2e22ae1cbc56f...8c9bdab8ec8/layer.tar”,
  “81752c417c9aa667d48049...23c4e9ae167/layer.tar”
 ],
 “Config” :
  “237dc6ec07959488c5a3ae...a0191aafed1.json”
 }
]
```

There are new layers. And each layer corresponds to the files added during a running step of the “Dockerfile.vim”.

```
$ tar tf vim/f30e5425e2e22ae1cbc56f...8c9bdab8ec8/layer.tar
bin/
bin/bash
bin/bunzip2
bin/bzcat
bin/bzcmp
(...)
var/log/apt/
var/log/apt/eipp.log.xz
var/log/apt/history.log
var/log/apt/term.log
var/log/dpkg.log
````

And f30.. correspond to “apt update && apt dist-upgrade”, while 817... correspond to “apt -y install vim”.

