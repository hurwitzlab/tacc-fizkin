#!/bin/bash

#
# Runs QC on a set of paired-end Illumina FASTQ files
#

# --------------------------------------------------
# R is needed by the SolexaQA++ program
module load R
# --------------------------------------------------

set -u

INPUT_FILE=${1:-''}

if [[ ! -f $INPUT_FILE ]]; then
  echo Bad input file \"$INPUT_FILE\"
  exit 1
fi

if [ -z ${CONFIG:=''} ]; then
  echo No CONFIG defined
  exit 1
fi

source $CONFIG

BIN="$( readlink -f -- "${0%/*}" )"
COMMON_SH="$BIN/common.sh"
if [ -e $COMMON_SH ]; then
  source "$COMMON_SH"
else
  echo Missing common \"$COMMON_SH\"
  exit 1
fi

BASENAME=$(basename $INPUT_FILE)

for RM in $FASTQ_DIR/${BASENAME}[._]*; do
  echo rm $RM
  rm -f $RM
done

TRIMMED_FILE=$FASTQ_DIR/${BASENAME}.trimmed

#if [[ ! -e $TRIMMED_FILE ]]; then
  for ACTION in analysis dynamictrim; do
    $BIN_DIR/SolexaQA++ $ACTION -d $FASTQ_DIR $INPUT_FILE
  done
#fi

if [[ ! -e $TRIMMED_FILE ]]; then
  echo Failed to create trimmed file \"$TRIMMED_FILE\"
  exit
fi

CLIPPED_FILE=${TRIMMED_FILE}.clipped

# cf. https://www.biostars.org/p/13606/ for "-Q33"
$BIN_DIR/fastx_clipper -v -l ${MIN_SEQ_LENGTH:=52} -Q33 \
  -i $TRIMMED_FILE -o $CLIPPED_FILE

if [[ ! -e $CLIPPED_FILE ]]; then
  echo Failed to create clipped file \"$CLIPPED_FILE\"
  exit
fi

if [[ ! -s $CLIPPED_FILE ]]; then
  echo Created zero-length clipped file \"$CLIPPED_FILE\"
  exit
fi

FASTA="$FASTA_DIR/$(basename $BASENAME '.fastq').fa"
$BIN/fastq2fasta.awk $CLIPPED_FILE > $FASTA

echo Created FASTA \"$FASTA\"

echo Done
