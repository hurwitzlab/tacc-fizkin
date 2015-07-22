#!/bin/bash

# --------------------------------------------------
#
# config.sh
# 
# Edit this file to match your directory structure
#
# --------------------------------------------------

# 
# Who, when to write about jobs
# 
SLURM_EMAIL="--mail-type=BEGIN,END --mail-user=kyclark@email.arizona.edu"

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
export PROJECT_DIR="$WORK/tacc-fizkin/stampede"
export BIN_DIR="$PROJECT_DIR/bin"
export SCRIPT_DIR="$PROJECT_DIR/scripts"
export WORKER_DIR="$SCRIPT_DIR/workers"

#
# Where to put all our generated data
#
export DATA_DIR=$WORK/data/mouse
#export DATA_DIR=$WORK/data/pov
export RAW_DIR=$DATA_DIR/raw

#
# Places for Launcher bits
#
export PARAMS_DIR="$SCRIPT_DIR/params"

#
# Where to find the host genome for screening
#
export REF_DIR=$WORK/data/reference
export HOST_DIR="$REF_DIR/glycine_max $REF_DIR/human $REF_DIR/medicago_truncatula $REF_DIR/mouse $REF_DIR/wheat $REF_DIR/yeast $REF_DIR/zea_mays"

#
# Where to put the results of our steps
#
export HOST_JELLYFISH_DIR="$REF_DIR/jellyfish"

export HOST_BOWTIE_DIR="/rsgrps/bhurwitz/hurwitzlab/data/bowtie"

# 
# Where we can find all our custom binaries (e.g., jellyfish)
# 
export JELLYFISH="$BIN_DIR/jellyfish"
export PERL="$WORK/bin/perl"

#
# Where to put the results of our steps
#
export FASTQ_DIR="$DATA_DIR/fastq"
export FASTA_DIR="$DATA_DIR/fasta"
export BT_ALIGNED_DIR="$DATA_DIR/bowtie-aligned"
export SCREENED_DIR="$DATA_DIR/screened"
export SUFFIX_DIR="$DATA_DIR/suffix"
export KMER_DIR="$DATA_DIR/kmers"
export REJECTED_DIR="$DATA_DIR/rejected"
export JELLYFISH_DIR="$DATA_DIR/jellyfish"
export FASTA_SPLIT_DIR="$DATA_DIR/fasta-split"
export COUNT_DIR="$DATA_DIR/counts"
export MODE_DIR="$DATA_DIR/modes"
export READ_MODE_DIR="$DATA_DIR/read-modes"
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
