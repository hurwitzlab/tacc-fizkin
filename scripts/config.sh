#!/bin/bash

# --------------------------------------------------
#
# config.sh
# 
# Edit this file to match your directory structure
#
# --------------------------------------------------

#
# Some constants
#
export MER_SIZE=20
export MIN_SEQ_LENGTH=50
export QSTAT="/usr/local/bin/qstat_local"
export GUNZIP="/bin/gunzip"

#
# The main checkout
#
PROJECT_DIR="$WORK/pov"

#
# Where we can find the worker scripts
#
export SCRIPT_DIR="$PROJECT_DIR/scripts"
export WORKER_DIR="$SCRIPT_DIR/workers"

#
# Where to put all our generated data
#
export DATA_DIR="$PROJECT_DIR/data"

#
# Places for Launcher bits
#
export PARAMS_DIR="$SCRIPT_DIR/params"
export LAUNCHER_DIR="$SCRIPT_DIR/launcher"

#
# Where to find the host genome for screening
#
export HOST_DIR="/rsgrps/bhurwitz/hurwitzlab/data/reference/mouse_genome/20141111 /rsgrps/bhurwitz/hurwitzlab/data/reference/soybean /rsgrps/bhurwitz/hurwitzlab/data/reference/yeast /rsgrps/bhurwitz/hurwitzlab/data/reference/wheat /rsgrps/bhurwitz/hurwitzlab/data/reference/medicago /rsgrps/bhurwitz/hurwitzlab/data/reference/zea_mays/v3"

#
# Where to put the results of our steps
#
export HOST_JELLYFISH_DIR="$DATA_DIR/jellyfish/host"

export HOST_BOWTIE_DIR="/rsgrps/bhurwitz/hurwitzlab/data/bowtie"

# 
# Where we can find all our custom binaries (e.g., jellyfish)
# 
export BIN_DIR="$WORK/bin"
export JELLYFISH="$BIN_DIR/jellyfish"
export PERL="$BIN_DIR/perl"

#
# Where to put the results of our steps
#
export FASTQ_DIR="$DATA_DIR/fastq"
export FASTA_DIR="$DATA_DIR/fasta"
export BT_ALIGNED_DIR="$DATA_DIR/bowtie-aligned"
export SCREENED_DIR="$DATA_DIR/screened"
export SUFFIX_DIR="$DATA_DIR/suffix"
export KMER_DIR="$DATA_DIR/kmers"
export JELLYFISH_DIR="$DATA_DIR/jellyfish"
export FASTA_SPLIT_DIR="$DATA_DIR/fasta-split"
export COUNT_DIR="$DATA_DIR/counts"
export MODE_DIR="$DATA_DIR/modes"
export MATRIX_DIR="$DATA_DIR/matrix"
export MAX_JELLYFISH_INPUT_SIZE=500 # MB

#
# Some custom functions for our scripts
#
# --------------------------------------------------
function init_dirs {
    for dir in $*; do
        if [ -d "$dir" ]; then
            rm -rf $dir/*
        else
            mkdir -p "$dir"
        fi
    done
}

# --------------------------------------------------
function lc() {
    wc -l $1 | cut -d ' ' -f 1
}
