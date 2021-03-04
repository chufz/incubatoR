#!/bin/bash

module load Anaconda3
conda create --name  incubatoR -c conda-forge -c biopython r-essentials r-base genform r-yaml bioconductor-xcms bioconductor-camera bioconductor-mspurity
