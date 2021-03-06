#!/bin/bash

# --------------------------------------------------
#
# 03-jellyfish-count-screened.sh
#
# Index host-screened FASTA for pairwise analysis
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

export SOURCE_DIR="$FASTA_DIR"
export OUT_DIR="$JELLYFISH_DIR"
export STEP_SIZE=100
export CWD="$PWD"

# --------------------------------------------------

PROG=$(basename "$0" ".sh")

if [[  ! -d $KMER_DIR ]]; then
  echo Making KMER_DIR \"$KMER_DIR\"
  mkdir -p $KMER_DIR
fi

if [[  ! -d $OUT_DIR ]]; then
  echo Making OUT_DIR \"$OUT_DIR\"
  mkdir -p $OUT_DIR
fi

if [[  ! -d $PARAMS_DIR ]]; then
  echo Making PARAMS_DIR \"$PARAMS_DIR\"
  mkdir -p $PARAMS_DIR
fi

export FILES_LIST=$(mktemp)
echo FILES_LIST \"$FILES_LIST\"

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
  echo Taking files from DIR \"$SOURCE_DIR\"
  find $SOURCE_DIR -name \*.fa > $FILES_LIST
fi

NUM_FILES=$(lc $FILES_LIST)

echo Found \"$NUM_FILES\" files

if [ $NUM_FILES -lt 1 ]; then
  echo Nothing to do.
  exit 1
fi

export PARAMS_FILE="$PARAMS_DIR/${PROG}.params"

if [ -e $PARAMS_FILE ]; then
  echo Removing previous PARAMS_FILE \"$PARAMS_FILE\"
  rm $PARAMS_FILE
fi

while read FILE; do
  echo CONFIG=$CONFIG $BIN/workers/jellyfish-count.sh $FILE >> $PARAMS_FILE
done < $FILES_LIST

NUM_JOBS=$(lc $PARAMS_FILE)

if [ $NUM_JOBS -lt 1 ]; then
  echo No jobs to submit.
  exit 1
fi

echo Submitting \"$NUM_JOBS\" jobs

SLURM_OUT=$PWD/out/$PROG
init_dirs $SLURM_OUT

sbatch -J jf-cnt -o "$SLURM_OUT/%j.out" -e "$SLURM_OUT/%j.out" \
  -n ${NUM_JOBS:=1} ${SLURM_EMAIL:=""} \
  $BIN/launcher.sh $PARAMS_FILE
