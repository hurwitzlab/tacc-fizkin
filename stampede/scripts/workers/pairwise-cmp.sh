#!/bin/bash

set -u

if [ -z "$CONFIG" ]; then
  echo No CONFIG defined
  exit
fi

source $CONFIG

FILE1=$1
FILE2=$2
BIN="$( readlink -f -- "${0%/*}" )"
COMMON_SH="$BIN/common.sh"

if [ -e $COMMON_SH ]; then
  source "$COMMON_SH"
else
  echo Missing common \"$COMMON_SH\"
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

JELLYFISH_FILE="$JELLYFISH_DIR/$FILE1.jf"
if [[ ! -e $JELLYFISH_FILE ]]; then
  echo Cannot find Jellyfish file \"$JELLYFISH_FILE\"
  exit
fi

KMER_FILE="$KMER_DIR/$FILE2.kmers"
LOC_FILE="$KMER_DIR/$FILE2.loc"
if [[ ! -e $KMER_FILE ]]; then
  echo Cannot find k-mer file \"$KMER_FILE\"
  exit
fi

if [[ ! -e $LOC_FILE ]]; then
    echo Cannot find expected k-mer location file \"$LOC_FILE\"
    exit 1
fi

printf "Processing \"%s\" => \"%s\"\n" $FILE1 $FILE2

MODE_OUT_DIR="$MODE_DIR/$FILE1"
OUT_FILE="$MODE_OUT_DIR/$FILE2"

if [[ ! -e $OUT_FILE ]]; then
  $JELLYFISH query -i "$JELLYFISH_FILE" < "$KMER_FILE" | \
    $PERL $BIN/jellyfish-reduce.pl -l "$LOC_FILE" -o "$OUT_FILE" --mode-min 1
fi
