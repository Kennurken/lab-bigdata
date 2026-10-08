#!/bin/zsh
# Usage: ./run_lab.sh lab05-dplyr
set -e
export PATH="/opt/homebrew/bin:$PATH"
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
cd "$(dirname "$0")/$1"
script=$(ls lab*.R | head -1)
Rscript -e "options(width = 100, warn = 1); source('$script', echo = TRUE, max.deparse.length = Inf, keep.source = TRUE, prompt.echo = '> ', spaced = FALSE)" > output.txt 2>&1
echo "$1: OK ($(wc -l < output.txt) lines)"
