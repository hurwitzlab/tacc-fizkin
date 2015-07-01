#!/bin/bash

#SBATCH -p development
#SBATCH -t 48:00:00
#SBATCH -n 16
#SBATCH -A iPlant-Collabs
#SBATCH -J fizkin
#SBATCH -o fizkin.o%j

tar -xf bin.tgz

export PATH=$PATH:"$PWD/bin"

jellyfish --version

module load irods

DATA_DIR=$WORK/pov/data
FASTA_DIR=$DATA_DIR/fasta
JF_DIR=$DATA_DIR/jellyfish
KMER_DIR=$DATA_DIR/kmers
MODE_DIR=$DATA_DIR/modes
MER_SIZE=20

if [[ ! -d $JF_DIR ]]; then
    mkdir -p $JF_DIR
fi

if [[ ! -d $KMER_DIR ]]; then
    mkdir -p $KMER_DIR
fi

if [[ ! -d $MODE_DIR ]]; then
    mkdir -p $MODE_DIR
fi

FILES=$(mktemp)
JF_FILES=$(mktemp)
KMER_FILES=$(mktemp)

find $FASTA_DIR -type f > $FILES

echo Pre-processing files

i=0
while read FILE; do
    BASENAME=$(basename $FILE)
    let i++
    printf "%5d: %s\n" $i $BASENAME

    JF_FILE=$JF_DIR/$BASENAME.jf 
    echo $JF_FILE >> $JF_FILES
    if [[ ! -e $JF_FILE ]]; then
        jellyfish count -m 20 -s 100M -t 4 -o $JF_FILE $FILE
    fi

    KMER_FILE=$KMER_DIR/$BASENAME.kmers 
    echo $KMER_FILE >> $KMER_FILES
    if [[ ! -e $KMER_FILE ]]; then
        kmerizer.pl -k $MER_SIZE -i $FILE -o $KMER_FILE \
          -l $KMER_DIR/$BASENAME.loc
    fi
done < $FILES

echo
echo Pairwise Comparison

i=0
while read JF_FILE; do
    JF_BASENAME=$(basename $JF_FILE '.jf')
    OUT_DIR=$MODE_DIR/$JF_BASENAME

    if [[ ! -d $OUT_DIR ]]; then
        mkdir -p $OUT_DIR
    fi

    while read KMER_FILE; do
        KMER_BASENAME=$(basename $KMER_FILE '.kmers')

        let i++
        printf "%5d: %20s => %-20s\n" $i $JF_BASENAME $KMER_BASENAME

        OUT_FILE=$OUT_DIR/$KMER_BASENAME 

        if [[ ! -e $OUT_FILE ]]; then
            jellyfish query -i $JF_FILE < $KMER_FILE | \
              jellyfish-reduce.pl -l ${KMER_FILE%.kmers}.loc \
              -o $OUT_FILE --mode-min 1
        fi
    done < $KMER_FILES
done < $JF_FILES

rm -rf bin

rm $FILES $JF_FILES $KMER_FILES

echo Done
