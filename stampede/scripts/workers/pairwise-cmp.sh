#!/bin/bash

set -u

#
# Check args/env
#
if [ -z "$CONFIG" ]; then
  echo No CONFIG defined
  exit
fi

if [[ ! -e $CONFIG ]]; then
  echo CONFIG \"$CONFIG\" does not exist
  exit 1
fi

source $CONFIG

FASTA_FILE=${1:-''}
JF_FILE=${2:-''}

if [ -z $FASTA_FILE ]; then
  echo Missing FASTA_FILE argument
  exit 1
fi

if [[ ! -e $FASTA_FILE ]]; then
  echo FASTA_FILE \"$FASTA_FILE\" does not exist
  exit 1
fi

if [ -z $JF_FILE ]; then
  echo Missing JF_FILE argument
  exit 1
fi

if [[ ! -e $JF_FILE ]]; then
  echo JF_FILE \"$JF_FILE\" does not exist
  exit 1
fi

if [ -z "$MODE_DIR" ]; then
  echo No MODE_DIR defined
  exit 1
fi

if [ -z "$KMER_DIR" ]; then
  echo No KMER_DIR defined
  exit 1
fi

if [[ ! -x "$JELLYFISH" ]]; then
  echo Cannot find executable jellyfish
  exit 1
fi

# 
# Find where we live and bring in common stuff
# 
BIN="$( readlink -f -- "${0%/*}" )"
COMMON_SH="$BIN/common.sh"

#if [ -e $COMMON_SH ]; then
#  source "$COMMON_SH"
#else
#  echo Missing common \"$COMMON_SH\"
#  exit 1
#fi

FASTA_BASE=$(basename $FASTA_FILE) 
JF_BASE=$(basename $JF_FILE '.jf')
KMER_FILE="$KMER_DIR/$FASTA_BASE.kmers"
LOC_FILE="$KMER_DIR/$FASTA_BASE.loc"

if [[ ! -e $KMER_FILE ]]; then
  echo Cannot find k-mer file \"$KMER_FILE\"
  exit 1
fi

if [[ ! -e $LOC_FILE ]]; then
  echo Cannot find expected k-mer location file \"$LOC_FILE\"
  exit 1
fi

printf "Processing '%s' => '%s'\n" $FASTA_BASE $JF_BASE

MODE_OUT_DIR="$MODE_DIR/$JF_BASE"
OUT_FILE="$MODE_OUT_DIR/$FASTA_BASE"

if [[ ! -d $MODE_OUT_DIR ]]; then
  mkdir -p $MODE_OUT_DIR
fi

READ_FILE_ARG=""
if [[ ! -z $READ_MODE_DIR ]]; then
  READ_MODE_DIR_OUT="$READ_MODE_DIR/$JF_BASE"

  if [[ ! -d $READ_MODE_DIR_OUT ]]; then
    mkdir -p $READ_MODE_DIR_OUT
  fi

  READ_FILE_ARG="-r $READ_MODE_DIR_OUT/$FASTA_BASE"
fi

if [[ ! -e $OUT_FILE ]]; then
  $JELLYFISH query -i "$JF_FILE" < "$KMER_FILE" | \
  $PERL $BIN/jellyfish-reduce.pl -l "$LOC_FILE" -o "$OUT_FILE" \
  $READ_FILE_ARG --mode-min 1
fi
