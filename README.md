# bash-tools

## Overview

This is a project containing simple bash tools for general use.

## Current tools

1. `gitversion`: a version retrieval tool that uses git depth for the PATCH version
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

See the help message of each script for more info, e.g.:

```bash
gitversion help
```

## Sample dockerfile

A sample dockerfile is included in the `lib/vim-devc` folder. This dockerfile is used to overlay the
image built by `vim-devc` from the base image set in your project's `devcontainer.json` file.
