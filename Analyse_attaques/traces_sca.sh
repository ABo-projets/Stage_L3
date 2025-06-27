#!/usr/bin/env nix-shell
#!nix-shell ../default.nix -i bash

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
python3 $SCRIPTPATH/traces_sca.py