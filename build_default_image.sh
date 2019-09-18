#!/bin/bash

lxc image list | grep x86_64 | egrep -v 'default-|ubuntu-' | awk '{print $3}' | xargs -n 1 -I % bash -cx 'lxc image delete %'

RV="16 18"
#RV="18"

for VER in $RV
do
  ORIGIN_IMAGE=ubuntu-"$VER".04
  DEFAULT_IMAGE=default-"$VER".04
  CONTAINER=default"$VER"04

  if lxc list | grep $CONTAINER # if there is the template container
  then
    lxc start $CONTAINER
  else
    if ! lxc image list | grep $DEFAULT_IMAGE # if there is no default image made before
    then
      lxc image --verbose copy ubuntu:"$VER".04 local: --alias $ORIGIN_IMAGE --public --auto-update
    fi
    lxc launch $ORIGIN_IMAGE $CONTAINER
  fi

  sleep 20
  ssh $CONTAINER sudo apt update
  ssh $CONTAINER sudo apt full-upgrade -y
  ssh $CONTAINER sudo apt install -y bridge-utils
  ssh $CONTAINER sudo apt autoremove -y
  ssh $CONTAINER
  # https://github.com/itisnotdone/mydotfile

  lxc stop $CONTAINER

  lxc publish --verbose $CONTAINER local: --alias $DEFAULT_IMAGE
done

lxc image list
