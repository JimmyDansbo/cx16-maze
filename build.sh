#!/bin/bash
rm -rf MAZES.BIN X16MAZE.PRG
acme -f cbm -o MAZES.BIN mazes.asm
acme -f cbm -o X16MAZE.PRG x16maze.asm

