#!/bin/bash

# --------------------------------------------------
#
# 02-screen-host.sh
#
# Run Jellyfish query for every read against every index
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

INPUT_DIR="$FASTA_DIR"

if [[ ! -d "$SCREENED_DIR" ]]; then
  mkdir -p "$SCREENED_DIR"
fi

if [[ ! -d "$REJECTED_DIR" ]]; then
  mkdir -p "$REJECTED_DIR"
fi

if [[ ! -d "$KMER_DIR" ]]; then
  mkdir -p "$KMER_DIR"
fi

#
# Find input FASTA files
#
PROG=$(basename $0 ".sh")
FILES_LIST="${HOME}/${PROG}.in"

#
find $INPUT_DIR -type f > $FILES_LIST
NUM_FILES=$(lc $FILES_LIST)

echo Found \"$NUM_FILES\" FASTA files in \"$INPUT_DIR\"

if [ $NUM_FILES -lt 1 ]; then
  echo Nothing to do.
  exit 1
fi

PARAMS_FILE="$PARAMS_DIR/${PROG}.params"

if [ -e $PARAMS_FILE ]; then
  echo Removing previous PARAMS_FILE \"$PARAMS_FILE\"
  rm $PARAMS_FILE
fi

while read FILE; do
  echo CONFIG=$CONFIG $BIN/workers/screen-host.sh $FILE >> $PARAMS_FILE
done < $FILES_LIST

SLURM_OUT=$PWD/out/$PROG

init_dirs $SLURM_OUT

NUM_JOBS=$(lc $PARAMS_FILE)

if [ $NUM_JOBS -lt 1 ]; then
  echo No jobs to submit.
  exit 1
fi

echo Submitting \"$NUM_JOBS\" jobs

sbatch -J host-scrn -o "$SLURM_OUT/%j.out" -e "$SLURM_OUT/%j.err" \
  -n ${NUM_JOBS:=1} ${SLURM_EMAIL:=""} \
  $BIN/launcher.sh $PARAMS_FILE
