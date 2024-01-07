#!/bin/bash


apt install firewalld -y

firewall-cmd --add-port=6443/tcp --permanent
firewall-cmd --add-port=2379-2380/tcp --permanent
firewall-cmd --add-port=10250/tcp --permanent
firewall-cmd --add-port=10259/tcp --permanent
firewall-cmd --add-port=10257/tcp --permanent

firewall-cmd --reload