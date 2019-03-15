#!/bin/sh -x
# 
# Simple script to use curl to test an app node prior to switching over
#
export http_proxy
http_proxy=
export https_proxy
https_proxy=

sleep 10

bats tests
