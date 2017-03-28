#BSUB -L /bin/bash
#BSUB -o BWA-%J-OUT.txt
#BSUB -e BWA-%J-ERROR.txt
#BSUB -u cmatthey@unil.ch
#BSUB -J bam
#BSUB -n 24
##BSUB -R "span[ptile=8]"
##BSUB -q normal
#BSUB -R "rusage[mem=20000]"
#BSUB -M 20000000

module add UHTS/Aligner/bwa/0.7.2;
module add UHTS/Analysis/samtools/1.3;
#module add UHTS/Aligner/bowtie2/2.2.4;

data_dir=/scratch/beegfs/monthly/cmatthey/data/processed/
index=/scratch/beegfs/monthly/cmatthey/data/ref_genome/lfabarum_bwa_index ## path and prefix of indexed genome files
out_dir=/scratch/beegfs/monthly/cmatthey/data/mapped/$1_$2_$3_$4/
threads=24

# Parameters I want to change
ALG=$1 ## mem or backtrack[mem/aln]
MM=$2 ## mismatches (aln)[4]
K=$3 ## min seed length (mem)[19]
W=$4 ## band width (mem)[100]
#D=100 ## max dist between query and ref position (mem)
#R=1.5 ## min reseeding length (mem)
prefix=BWA_$1


## Do some work:
mkdir -p bam
	
date

for sample in $(tail -n +2 F4_table.csv | awk -F, '{print $1"_"$2}') #this is a list of sample names (similar as the popmap file for Populations, but without reproductive mode)
do 
        echo "\nprocessing sample $sample\n";
        #cp -v $data_dir/$sample* $sample.fq.gz
        #gunzip -v $sample.fq.gz
        
        case $ALG in
            'mem')
                bwa mem -k $K -t $threads -w $W  $index $data_dir/$sample.fq.gz > $sample.sai
                ;;
            'aln')
                bwa aln -n $MM -t $threads $index $data_dir/$sample.fq.gz > $sample.sai ## align reads
                ;;
        esac
        
        bwa samse -n $MM $index $sample.sai $data_dir/$sample.fq.gz > $sample-$prefix.sam # index alignment file
	perl /scratch/beegfs/monthly/cmatthey/src/mapping/split_sam.pl -i $sample-$prefix.sam -o $sample-$prefix >> split_summary.log ## change perl script path (script removes reads which map more than once)
	rm -v $sample-$prefix.sam
	cd bam/
	samtools view -@ $threads -bS -o $sample-$prefix-uniq.bam ../$sample-$prefix-uniq.sam ## converts from SAM to BAM
	samtools sort -@ $threads $sample-$prefix-uniq.bam -o $sample-$prefix-uniq.sorted.bam ## sort bam
	samtools index $sample-$prefix-uniq.sorted.bam # index bam
	samtools idxstats $sample-$prefix-uniq.sorted.bam # get index stats
	rm -v $sample-$prefix-uniq.bam ## remove unsorted bam file
	cd ../
	gzip -v *.sam # gzip sam files
	mv *.sam bam/*.bam $out_dir
	date
done
