#!/bin/bash

# Right now the app has to be exported from the IDE.
#

mkdir -p releases
mkdir -p releases/linux
mkdir -p releases/windows
mkdir -p releases/mac

mv application.linux* releases/linux/
mv application.windows* releases/windows/
mv application.macosx releases/mac/