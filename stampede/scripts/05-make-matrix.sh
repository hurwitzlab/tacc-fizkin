#!/bin/sh

# --------------------------------------------------
#
# 05-make-matrix.sh
#
# Reduce the "modes" into a matrix needed for 
# analysis in R
#
# --------------------------------------------------

set -u
BIN="$( readlink -f -- "${0%/*}" )"
if [ -f $BIN ]; then
  BIN=$(dirname $BIN)
fi

CONFIG=$BIN/config.sh

if [[ ! -e $CONFIG ]]; then
  echo Cannot find \"$CONFIG\"
  exit
fi

source $CONFIG

if [[ ! -d $MODE_DIR ]]; then
  echo Cannot find MODE_DIR \"$MODE_DIR\"
  exit
fi

if [[ ! -d $MATRIX_DIR ]]; then
  mkdir -p $MATRIX_DIR
fi

CWD=$PWD
PROG=$(basename $0 ".sh")
PARAMS_FILE="$PARAMS_DIR/${PROG}.params"

echo "$PERL $WORKER_DIR/make-matrix.pl -d $MODE_DIR > $MATRIX_DIR/matrix.tab" > $PARAMS_FILE

echo Submitting matrix

SLURM_OUT=$PWD/out/$PROG
init_dirs $SLURM_OUT

sbatch -J matrix -o "$SLURM_OUT/%j.out" -e "$SLURM_OUT/%j.err" \
  -n ${NUM_JOBS:=1} ${SLURM_EMAIL:=""} \
  $BIN/launcher.sh $PARAMS_FILE
