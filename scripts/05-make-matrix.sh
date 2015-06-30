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

if [[ ! -d $MODE_DIR ]]; then
  echo Cannot find MODE_DIR \"$MODE_DIR\"
  exit
fi

if [[ ! -d $MATRIX_DIR ]]; then
  mkdir -p $MATRIX_DIR
fi

CWD=$PWD
PROG=$(basename $0 ".sh")
export PARAMS_FILE="$PARAMS_DIR/${PROG}.params"
SLURM_OUT=$PWD/out/$PROG
init_dirs $SLURM_OUT

echo "$PERL $WORKER_DIR/make-matrix.pl -d $MODE_DIR > $MATRIX_DIR/matrix.tab" > $PARAMS_FILE

sbatch -J matrix -o "$SLURM_OUT/%j" $BIN/launcher.sh $PARAMS_FILE
