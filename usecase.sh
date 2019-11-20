#!/bin/bash
docker build builds -f builds/Dockerfile.vim -t sldocker:vim
docker build builds -f builds/Dockerfile.nfs -t sldocker:nfs
docker build builds -f builds/Dockerfile.cowsay -t sldocker:cowsay
docker build builds -f builds/Dockerfile.all -t sldocker:all
./sldocker ubuntu:latest sldocker:nfs sldocker:composed -r
./sldocker sldocker:composed sldocker:cowsay sldocker:composed -r
./sldocker sldocker:composed sldocker:vim sldocker:composed -r
docker images sldocker