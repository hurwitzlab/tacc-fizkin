#!/bin/bash

#SBATCH -N 1                # Total number of nodes (16 cores/node)
#SBATCH -n 16               # Total number of tasks
#SBATCH -p normal           # Queue name
#SBATCH -t 48:00:00         # Run time (hh:mm:ss)
#SBATCH --mail-type END,FAIL
#SBATCH --mail-user kyclark@email.arizona.edu

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
