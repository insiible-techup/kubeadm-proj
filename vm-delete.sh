#!/usr/bin/env zsh


num=(1 2 3)

for i in "${num[@]}"
    multipass delete worker${i} && multipass delete controller${i}
    multipass purge

