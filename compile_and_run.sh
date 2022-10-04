#!/bin/bash

assemblerFile=narcissist.asm
projectFileDir=.

utilities_path="/Users/christian/projects/code/c64/c64-utilities"

# Get absolute path for supplied project path (no relative path)
cd $projectFileDir
projectFileDir=$(pwd)
cd -

"$utilities_path/compile_and_debug.sh" "$assemblerFile"