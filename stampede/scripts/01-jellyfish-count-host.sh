#!/bin/bash

# --------------------------------------------------
#
# 01-jellyfish-count-host.sh
#
# Use Jellyfish to index host FASTA
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

export CWD=$PWD
export STEP_SIZE=20
export SOURCE_DIR="$HOST_DIR"
export OUT_DIR=$HOST_JELLYFISH_DIR
export KMERIZE_FILES=0

# --------------------------------------------------

PROG=$(basename "$0" ".sh")
STDOUT_DIR="$CWD/out/$PROG"

init_dirs "$STDOUT_DIR"

export FILES_LIST="$HOME/${PROG}.in"

if [ -e $FILES_LIST ]; then
  rm -f $FILES_LIST
fi

if [ -z $SOURCE_DIR ]; then
  echo No SOURCE_DIR defined
fi

echo Looking for files to index in ...
i=0
for SRC_DIR in $SOURCE_DIR; do
  let i++

  printf "%5d: %s\n" $i $SRC_DIR

  find $SRC_DIR -type f >> $FILES_LIST
done

COUNT=$(lc $FILES_LIST)

if [ $COUNT -lt 1 ]; then
  echo Nothing to do.
  exit 1
fi

PROG=$(basename $0 ".sh")
export PARAMS_FILE="$PARAMS_DIR/${PROG}.params"

if [ -e $PARAMS_FILE ]; then
  echo Removing previous PARAMS_FILE \"$PARAMS_FILE\"
  rm $PARAMS_FILE
fi

while read FILE; do
  echo CONFIG=$CONFIG $BIN/workers/jellyfish-count.sh $FILE >> $PARAMS_FILE
done < $FILES_LIST

SLURM_OUT=$PWD/out/$PROG

init_dirs $SLURM_OUT

NUM_JOBS=$(lc $PARAMS_FILE)

if [ $NUM_JOBS -lt 1 ]; then
  echo No jobs to submit.
  exit 1
fi

echo Submitting \"$NUM_JOBS\" jobs

sbatch -J jf-host-cnt -o "$SLURM_OUT/%j.out" -e "$SLURM_OUT/%j.err" \
  -n ${NUM_JOBS:=1} ${SLURM_EMAIL:=""} \
  $BIN/launcher.sh $PARAMS_FILE
