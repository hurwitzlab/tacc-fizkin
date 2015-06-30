#!/bin/bash

#SBATCH -J pp-fasta         # Job name
#SBATCH -N 1                # Total number of nodes (16 cores/node)
#SBATCH -n 16               # Total number of tasks
#SBATCH -p normal           # Queue name
#SBATCH -o pp-fasta.o%j     # Name of stdout output file (%j expands to jobid)
#SBATCH -t 02:00:00         # Run time (hh:mm:ss)

module load launcher

CONTROL_FILE=$1
EXECUTABLE=$TACC_LAUNCHER_DIR/init_launcher 
WORKDIR=$PWD

#----------------
# Error Checking
#----------------

if [[ ! -e $WORKDIR ]]; then
    echo " "
    echo "Error: unable to change to working directory."
    echo "       $WORKDIR"
    echo " "
    echo "Job not submitted."
    exit
fi

if [[ ! -f $EXECUTABLE ]]; then
    echo " "
    echo "Error: unable to find launcher executable $EXECUTABLE."
    echo " "
    echo "Job not submitted."
    exit
fi

if [[ ! -f $CONTROL_FILE ]]; then
    echo " "
    echo "Error: unable to find input control file $CONTROL_FILE."
    echo " "
    echo "Job not submitted."
    exit
fi


#----------------
# Job Submission
#----------------

cd $WORKDIR/
echo " WORKING DIR:   $WORKDIR/"

$TACC_LAUNCHER_DIR/paramrun $EXECUTABLE $CONTROL_FILE

echo " "
echo " Parameteric Job Complete"
echo " "
