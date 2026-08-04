#!/bin/sh

# default-route interface; trunk0 is the OpenBSD box's usual answer
if=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')

$HOME/.local/bin/tstat "${if:-trunk0}"
