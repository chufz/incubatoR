#!/bin/bash

module load Anaconda3
conda create --name  incubatoR
source activate incubatoR
conda install r-essentials r-base
conda config --add channels bioconda
conda install -c bioconda genform 
conda install -c bioconda r-yaml

Rscript install_dependencies.R
