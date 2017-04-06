#!/bin/bash

## This script will make a separate bsub script for each 
## sample in a directory. These scripts can then be 
## submitted with a for loop to the priority queue
## for super quick pstacks analyses. See below for 
## arguments required:

wd=/scratch/beegfs/monthly/cmatthey/data/mapped/aln-4-19-100 ## the directory containing the fastq files
ID=1 ## the stacks ID to start from




mkdir -p bsub_scripts
mkdir -p pstacks


for i in $(ls *fq.gz)
do 
    echo "Sample= $i, ID=$ID" 
    j=$(echo $i | cut -f1 -d '.')
    echo "#!/bin/bash" > ./bsub_scripts/bsub_${j}_script.sh
    echo "" >> ./bsub_scripts/bsub_${j}_script.sh
    echo "#BSUB -L /bin/bash" >> ./bsub_scripts/bsub_${j}_script.sh
    echo "#BSUB -o %J_STDOUT.log" >> ./bsub_scripts/bsub_${j}_script.sh
    echo "#BSUB -e %J_STDERR.log" >> ./bsub_scripts/bsub_${j}_script.sh
    echo "#BSUB -J Pstacks_${j}" >> ./bsub_scripts/bsub_${j}_script.sh
    echo "#BSUB -n 3" >> ./bsub_scripts/bsub_${j}_script.sh
    echo "#BSUB -M 2000000" >> ./bsub_scripts/bsub_${j}_script.sh
    echo "#BSUB -q priority" >> ./bsub_scripts/bsub_${j}_script.sh
    echo "" >> ./bsub_scripts/bsub_${j}_script.sh

    echo "module add UHTS/Analysis/stacks/1.30" >> ./bsub_scripts/bsub_${j}_script.sh
    echo "" >> ./bsub_scripts/bsub_${j}_script.sh

    echo "pstacks -f $wd -i id -o path [-m min_cov] [-p num_threads -t bam" >> ./bsub_scripts/bsub_${j}_script.sh

    ((ID+=1))

done 
