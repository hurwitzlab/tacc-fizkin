#!/bin/bash

# --------------------------------------------------
# 00-qc-fastq.sh
# 
# This script runs illumina QC on a directory
# of fastq files, runs the paired read analysis,
# then creates fasta/qual files from the paired
# fastq files
#
# For example:
# paired reads are in separate files:
# RNA_1_ACAGTG_L008_R1_001.fastq
# RNA_1_ACAGTG_L008_R2_001.fastq
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

SOURCE_DIR=${RAW_DIR:-''}

echo SOURCE_DIR \"$SOURCE_DIR\"

if [[ ! -d $SOURCE_DIR ]]; then
  echo Bad SOURCE_DIR 
  exit 0
fi

if [[ ! -d $FASTQ_DIR ]]; then
  echo Making FASTQ dir
  mkdir -p $FASTQ_DIR
fi

if [[ ! -d $FASTA_DIR ]]; then
  echo Making FASTA dir
  mkdir -p $FASTA_DIR
fi

if [[ ! -d $PARAMS_DIR ]]; then
  echo Making PARAMS dir
  mkdir -p $PARAMS_DIR
fi

export FILES_LIST=$(mktemp)

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
  find $SOURCE_DIR -type f > $FILES_LIST
fi

NUM_FILES=$(lc $FILES_LIST)

echo Found \"$NUM_FILES\" files

if [ $NUM_FILES -lt 1 ]; then
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
  echo CONFIG=$CONFIG $BIN/workers/qc_fastq.sh $FILE >> $PARAMS_FILE
done < $FILES_LIST

SLURM_OUT=$PWD/out/$PROG

init_dirs $SLURM_OUT

NUM_JOBS=$(lc $PARAMS_FILE)

if [ $NUM_JOBS -lt 1 ]; then
  echo No jobs to submit.
  exit 1
fi

echo Submitting \"$NUM_JOBS\" jobs

sbatch -J raw-qc -o "$SLURM_OUT/%j.out" -e "$SLURM_OUT/%j.err" \
  -n ${NUM_JOBS:=1} ${SLURM_EMAIL:=""} \
  $BIN/launcher.sh $PARAMS_FILE
