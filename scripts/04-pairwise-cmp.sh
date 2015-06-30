#!/bin/bash

# --------------------------------------------------
#
# 04-pairwise-cmp.sh
#
# Use Jellyfish to run a pairwise comparison of all screened samples
#
# --------------------------------------------------

set -u
export BIN="$( readlink -f -- "${0%/*}" )"
if [ -f $BIN ]; then
  BIN=$(dirname $BIN)
fi
export CONFIG=$BIN/config.sh

if [[ ! -e $CONFIG ]]; then
  echo Cannot find \"$CONFIG\"
  exit
fi

source $CONFIG
export SUFFIX_DIR="$JELLYFISH_DIR"
export STEP_SIZE=90

# --------------------------------------------------

CWD=$PWD
PROG=$(basename $0 ".sh")

if [[ ! -d "$MODE_DIR" ]]; then
  mkdir -p "$MODE_DIR"
fi

#
# Find all the input files
#
FILES_LIST=$(mktemp)

INPUT_FILES_LIST=${1:-''}
if [ -n "$INPUT_FILES_LIST" ] && [ -e "$INPUT_FILES_LIST" ]; then
  echo Taking files from FILE \"$INPUT_FILES_LIST\"
  cp $INPUT_FILES_LIST $FILES_LIST
else
  echo Taking files from DIR \"$FASTA_DIR\"
  find $FASTA_DIR -type f > $FILES_LIST
fi

NUM_FILES=$(lc $FILES_LIST)

echo Found \"$NUM_FILES\" files

if [ $NUM_FILES -lt 1 ]; then
  echo Nothing to do.
  exit 1
fi

export PARAMS_FILE="$PARAMS_DIR/${PROG}.params"

if [ -e $PARAMS_FILE ]; then
  rm $PARAMS_FILE
fi

while read F1; do
  F1=$(basename $F1)
  while read F2; do
    F2=$(basename $F2)
    echo "CONFIG=$CONFIG $WORKER_DIR/pairwise-cmp.sh $F1 $F2" >> $PARAMS_FILE
  done < $FILES_LIST
done < $FILES_LIST

NUM_PAIRS=$(lc $PARAMS_FILE)

echo There are \"$NUM_PAIRS\" pairs to process 

if [ $NUM_PAIRS -lt 1 ]; then
  echo Could not generate file pairs
  exit 1
fi

SLURM_OUT=$PWD/out/$PROG
init_dirs $SLURM_OUT
sbatch -J pair-cmp -o "$SLURM_OUT/%j" $BIN/launcher.sh $PARAMS_FILE
