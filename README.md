# bash-tools

## Overview

This is a project containing simple bash tools for general use.

## Current tools

1. `gitversion`: a version retrieval tool that uses git depth for the PATCH version
1. `helpsh`: a script for printing help information from text prefixed with a triple hash (i.e. `###`)
1. `vim-devc`: a script for setting up a devcontainer with the `vim` configs on the host machine
    using the `devcontainer.json` of any given local workspace
1. `stowsh`: a dotfiles managing tool

## Installing

```bash
curl \
  --location \
  https://github.com/cjvirtucio87/bash-tools/releases/download/bash-tools-<MAJOR>.<MINOR>.<PATCH>/cjvirtucio87-bash-tools-<MAJOR>.<MINOR>.<PATCH>.tar.gz
  | tar \
      --extract \
      --gunzip \
      --directory /usr/local/
```

## Usage

Documentation is maintained on the code itself for maintainability reasons. Run `helpsh`
on any of these scripts to see their usage information, e.g.:

```bash
# assuming these scripts are in your $PATH
helpsh vim-devc
```

