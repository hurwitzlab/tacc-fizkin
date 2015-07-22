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
INPUT_DIR=$FASTA_DIR # or $SCREENED_DIR

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

  while read FILE; do
    if [ -e $FILE ]; then
      echo $FILE >> $FILES_LIST
    else
      echo Error: File \"$FILE\" does not exist.
    fi
  done < $INPUT_FILES_LIST 
else
  echo Taking files from DIR \"$INPUT_DIR\"
  find $INPUT_DIR -type f > $FILES_LIST
fi

NUM_FILES=$(lc $FILES_LIST)

echo Found \"$NUM_FILES\" files

if [ $NUM_FILES -lt 1 ]; then
  echo Nothing to do.
  exit 1
fi

JELLYFISH_FILES=$(mktemp)

while read IDX; do
    find $JELLYFISH_DIR -name $(basename $IDX).jf >> $JELLYFISH_FILES
done < $FILES_LIST

NUM_JF_FILES=$(lc $JELLYFISH_FILES)

echo Found \"$NUM_JF_FILES\" indexes in \"$JELLYFISH_DIR\"

if [ $NUM_JF_FILES -lt 1 ]; then
  echo Nothing to do.
  exit 1
fi

#
# Pair up the FASTA/Jellyfish files
#
if [ $NUM_JF_FILES -ne $NUM_FILES ]; then
  echo Different number of Jellyfish/FASTA files, quitting.
  exit 1
fi

export PARAMS_FILE="$PARAMS_DIR/${PROG}.params"

if [ -e $PARAMS_FILE ]; then
  rm $PARAMS_FILE
fi

while read FASTA_FILE; do
  while read JF_FILE; do
    echo "CONFIG=$CONFIG $WORKER_DIR/pairwise-cmp.sh $FASTA_FILE $JF_FILE" \
      >> $PARAMS_FILE
  done < $JELLYFISH_FILES
done < $FILES_LIST

NUM_JOBS=$(lc $PARAMS_FILE)

if [ $NUM_JOBS -lt 1 ]; then
  echo Could not generate file pairs
  exit 1
fi

echo Submitting \"$NUM_JOBS\" jobs

SLURM_OUT=$PWD/out/$PROG
init_dirs $SLURM_OUT

sbatch -J pair-cmp -o "$SLURM_OUT/%j.out" -e "$SLURM_OUT/%j.err" \
  -n ${NUM_JOBS:=1} ${SLURM_EMAIL:=""} \
  $BIN/launcher.sh $PARAMS_FILE
