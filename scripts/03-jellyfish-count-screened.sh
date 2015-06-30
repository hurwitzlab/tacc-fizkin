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

if [[  ! -d $LAUNCHER_DIR ]]; then
  echo Missing LAUNCHER_DIR \"$LAUNCHER_DIR\"
  exit
fi

export FILES_LIST=$(mktemp)
echo FILES_LIST \"$FILES_LIST\"

INPUT_FILES_LIST=${1:-''}
if [ -n "$INPUT_FILES_LIST" ] && [ -e "$INPUT_FILES_LIST" ]; then
  echo Taking files from FILE \"$INPUT_FILES_LIST\"
  cp $INPUT_FILES_LIST $FILES_LIST
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
  echo CONFIG=$CONFIG $WORKER_DIR/jellyfish-count.sh $FILE >> $PARAMS_FILE
done < $FILES_LIST

SLURM_OUT=$PWD/out/$PROG
init_dirs $SLURM_OUT
sbatch -J count -o "$SLURM_OUT/%j" $LAUNCHER_DIR/launcher.sh $PARAMS_FILE
