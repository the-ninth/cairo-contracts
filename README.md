[![License](https://img.shields.io/github/license/para-space/paraspace-core?color=green)](https://github.com/para-space/paraspace-core/blob/main/LICENSE)

[![Twitter URL](https://img.shields.io/twitter/follow/the_ninth?style=social)](https://twitter.com/ninth_gg)
[![Telegram](https://img.shields.io/badge/Telegram-gray?logo=telegram)](https://t.me/TheNinthOfficial)
[![Medium](https://img.shields.io/badge/Medium-gray?logo=medium)](https://medium.com/@the_ninth)
[![Discord](https://img.shields.io/badge/Discord-gray?logo=discord)](https://discord.gg/8aehWQPFyE)

# The Ninth

[Website](https://ninth.gg/)

This repository contains the smart contracts source code, written in Cairo, for The Ninth. The repository uses python as development enviroment for compilation, testing and deployment tasks.

## What is The Ninth?

In year 2032, archaeologist Al has discovered a mysterious space relic called the Noah's Ark near the Himalayas. The space relic can open a gate to a different world which contains civilizations that are lost in myths and animals that are extinct in our world. After that, scientists and archaeologists have discovered 8 more gates to the new world all across the globe. They named this new world The Ninth...

## Dev

Create a virtual environment (with python 3.9):

    python3.9 -m venv ~/cairo_venv
    source ~/cairo_venv/bin/activate

Nile:

    pip install cairo-nile
    https://github.com/OpenZeppelin/nile

Directly:

    pip install cairo-lang

## Test

pytest:

    pytest tests/xxx.py
