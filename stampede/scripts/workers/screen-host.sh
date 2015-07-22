#!/bin/bash

set -u

INPUT=${1:-''}
BIN="$( readlink -f -- "${0%/*}" )"
COMMON_SH="$BIN/common.sh"

if [ -z $INPUT ]; then
  echo No input file
  exit 1
fi

if [ -z $CONFIG ]; then 
  echo No CONFIG defined
  exit 1
fi

if [[ ! -e $CONFIG ]]; then
  echo CONFIG \"$CONFIG\" does not exist.
  exit 1
fi

source $CONFIG

if [ -e $COMMON_SH ]; then
  source "$COMMON_SH"
else
  echo Missing common \"$COMMON_SH\"
  exit 1
fi

echo Processing \"$INPUT\" 

SUFFIX_LIST=$(mktemp)

find $HOST_JELLYFISH_DIR -name \*.jf > $SUFFIX_LIST

NUM_SUFFIXES=$(wc -l $SUFFIX_LIST | cut -d ' ' -f 1)

echo Found \"$NUM_SUFFIXES\" suffixes in \"$HOST_JELLYFISH_DIR\"

if [ $NUM_SUFFIXES -lt 1 ]; then
  echo Cannot find any Jellyfish indexes!
  exit 1
fi

#
# Find our target Jellyfish files
#
FASTA_BASE=$(basename $INPUT)
KMER_FILE="$KMER_DIR/${FASTA_BASE}.kmers"
LOC_FILE="$KMER_DIR/${FASTA_BASE}.loc"

if [[ ! -e $KMER_FILE ]]; then
  echo Kmerizing \"$FASTA_BASE\"
  $BIN/kmerizer.pl -q -i "$INPUT" -o "$KMER_FILE" \
    -l "$LOC_FILE" -k "$MER_SIZE"
fi

if [[ ! -e $KMER_FILE ]]; then
  echo Cannot find K-mer file \"$KMER_FILE\"
  exit 1
fi

#
# The "host" file is what will be created in the querying
# and will be passed to the "screen-host.pl" script
#
PROG=$(basename $0 ".sh")
TMPDIR="$DATA_DIR/tmp"
if [[ ! -d $TMPDIR ]]; then
  mkdir -p $TMPDIR
fi

HOST=$(mktemp --tmpdir="$TMPDIR" "${PROG}.XXXXXXX")
touch $HOST

i=0
while read SUFFIX; do
  let i++
  printf "%5d: Processing %s\n" $i $(basename $SUFFIX)

  #
  # Note: no "-o" output file as we only care about the $HOST file
  #
  $PERL $JELLYFISH query -i "$SUFFIX" < "$KMER_FILE" | \
    $BIN/jellyfish-reduce.pl -l "$LOC_FILE" -u $HOST --mode-min 2
done < "$SUFFIX_LIST"

echo Done querying/reducing to \"$i\" suffix files

echo Screening with \"$HOST\"

$PERL $BIN/screen-host.pl -h "$HOST" -o "$SCREENED_DIR" -r "$REJECTED_DIR/$FASTA_BASE" $INPUT

echo Removing temp files
rm "$HOST"
rm "$SUFFIX_LIST"
echo Done.
