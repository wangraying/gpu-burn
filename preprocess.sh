#!/bin/bash

mkdir -p arch
SMS=$(nvcc --help | sed -n -e '/gpu-architecture <arch>/,/gpu-code <code>/ p' | sed -n -e '/Allowed values/,/gpu-code <code>/ p' | grep -i sm_ | grep -Eo 'sm_[0-9]+' | sed -e s/sm_//g | sort -g -u | tr '\n' ' ')
for SM in $SMS; do
    cp compare.cu arch/compare_${SM}.cu
done
