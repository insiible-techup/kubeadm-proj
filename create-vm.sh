#!/usr/bin/env zsh 

instances=(worker1 worker2 worker3 controller1 controller2 controller3)

for instance in "${instances[@]}"
    multipass launch -n $instance -c 2 -d 10G -m 10G
