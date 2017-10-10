# This script runs the mapping for all samples using the BWA aligner.
# It taks 3 arguments
# Cyril Matthey-Doret
# 11.10.2017

# Default number of mismatches is 4
MM=4
threads=2
prefix=BWA

# parsing CL arguments
while [[ "$#" > 1 ]]; do case $1 in
    # Number of mismatches allowed in BWA-aln
    --mm) MM="$2";;
    # Path to indexed ref genome
    --ref) index="$2";;
    # Path to input fastq files to map
    --reads) data_dir="$2";;
    # Path to output alignment files
    --out) out_dir="$2";;
    *) break;;
  esac; shift; shift
done
## create output directory for bam files:
mkdir -p $out_dir/bam

for sample in $(cut -f1 data/popmap.tsv) #this is the list of sample names
do
  # Skip iteration for this sample if fastq file does not exist
  if [ ! -f $data_dir/$sample.fq* ]
  then
    continue
  fi

  echo "processing sample $sample";
  # Sending each sample as a separate jobs
  bash <<MAPSAMPLE
    #!/bin/bash

    # align reads
    bwa aln -n $MM -t $threads $index $data_dir/$sample.fq.gz > $out_dir/$sample.sai
    # index alignment file
    bwa samse -n 3 $index $out_dir/$sample.sai $data_dir/$sample.fq.gz > $out_dir/$sample-$prefix.sam

    # perl script removes reads which map more than once
  	perl src/mapping/split_sam.pl -i $out_dir/$sample-$prefix.sam -o $out_dir/$sample-$prefix >> $out_dir/split_summary.log

    # Remove original SAM files
    rm -v $out_dir/$sample-$prefix.sam

    # Convert SAM files to BAM
  	samtools view -@ $threads -bS -o $out_dir/bam/$sample-$prefix-uniq.bam $out_dir/$sample-$prefix-uniq.sam

    # Sort alignments by leftmost coordinate
    samtools sort -@ $threads $out_dir/bam/$sample-$prefix-uniq.bam -o $out_dir/bam/$sample-$prefix-uniq.sorted.bam

    # Index BAM files
    samtools index $out_dir/bam/$sample-$prefix-uniq.sorted.bam

    # Output index statistics
  	samtools idxstats $out_dir/bam/$sample-$prefix-uniq.sorted.bam

    # Remove unsorted bam files
  	rm -v $out_dir/bam/$sample-$prefix-uniq.bam
  	date

    # Compress SAM files
    gzip -v $out_dir/$sample*.sam
MAPSAMPLE
done
