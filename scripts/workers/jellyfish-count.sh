#!/bin/bash

set -u

INPUT=$1
BIN="$( readlink -f -- "${0%/*}" )"
COMMON_SH="$BIN/common.sh"
JF_THREADS=4
JF_HASH_SIZE="100M"

#echo CONFIG \"$CONFIG\"
#echo INPUT \"$INPUT\"
#echo BIN \"$BIN\"
#echo COMMON_SH \"$COMMON_SH\"

source $CONFIG

if [ -e $COMMON_SH ]; then
  source "$COMMON_SH"
else
  echo Missing common \"$COMMON_SH\"
  exit 1
fi

#echo Started $(date)

#echo Host $(hostname)

KMERIZER="$BIN/kmerizer.pl"
if [[ ! -e $KMERIZER ]]; then
  echo Cannot find kmerizer \"$KMERIZER\"
  exit 1
fi

#
# Need to make sure none of these files are too large
#
TMP_CHECKED=$(mktemp)
MAX_MB=${MAX_JELLYFISH_INPUT_SIZE:-100}
SIZE=$(du -m "$INPUT" | cut -f 1)
echo INPUT FILE SIZE \"$SIZE\" max is $MAX_MB

if [ $SIZE -ge $MAX_MB ]; then
  echo Splitting $(basename $INPUT)
  $PERL $BIN/fasta-split.pl -m $MAX_MB -f $INPUT -o $FASTA_SPLIT_DIR

  BASENAME=$(basename $INPUT)
  BASENAME=${BASENAME%.*}
  find $FASTA_SPLIT_DIR -name $BASENAME\* -type f >> $TMP_CHECKED
else
  echo $INPUT >> $TMP_CHECKED
fi

NUM_FILES=$(lc $TMP_CHECKED)

echo After checking to split, we have \"$NUM_FILES\" files

i=0
while read FILE; do
  BASENAME=$(basename $FILE)
  JF_FILE="$JELLYFISH_DIR/${BASENAME}.jf"

  let i++
  printf "%5d: %s\n" $i $BASENAME

  if [[ ! -e "$JF_FILE" ]]; then
    $JELLYFISH count -m $MER_SIZE -s $JF_HASH_SIZE -t $JF_THREADS -o $JF_FILE $FILE
  fi

  KMER_FILE="$KMER_DIR/${BASENAME}.kmers"
  LOC_FILE="$KMER_DIR/${BASENAME}.loc"

  if [[ ! -e "$KMER_FILE" ]]; then
    $PERL $KMERIZER -q -i "$FILE" -o "$KMER_FILE" -l "$LOC_FILE" -k "$MER_SIZE"
  fi
done < $TMP_CHECKED

echo Finished $(date)
