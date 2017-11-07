# This script blasts the chromosomes containing GWAS hits against one-another.
# Cyril Matthey-Doret
# 04.11.2017

gwas='../../data/assoc_mapping/case_control/case_control_hits.tsv'
blast_files="../../data/homology/blast_files/"
ref='../../data/ref_genome/ordered_genome/merged.fasta'
mkdir -p $blast_files

module add Blast/ncbi-blast/2.6.0+;
module add UHTS/Analysis/BEDTools/2.26.0

# Extracting chromosomes containing sighificant GWAS hits
chr_hits=$(cut -f2 $gwas | tail -n +2 | sort | uniq)

# Generating one fasta file for each chromosome and building local blast db
for chrom in $chr_hits
do
  echo "awk is extracting $chrom from the genome"
  awk 'BEGIN{RS=">";}/'$chrom'/{print ">"$0}' $ref > "$blast_files/$chrom.fasta"
  echo "Making a BLAST database for $chrom..."
  makeblastdb -in "$blast_files/$chrom.fasta" -dbtype nucl
done

# Blasting chromosomes against each other (one-way)
blasted=''
for chrQ in $chr_hits
do
  for chrS in $chr_hits
  do
    # Do not blast chrom against itself of use twice the same pair
    if [[ ! $blasted =~ "${chrQ}${chrS}" && \
          ! $blasted =~ "${chrS}${chrQ}" && \
          $chrQ != $chrS ]]
     then
       echo "Blasting $chrQ against $chrS..."
       blasted+="${chrQ}${chrS} "
       blastn -query "$blast_files/$chrQ.fasta" \
              -db "$blast_files/$chrS.fasta" \
              -outfmt 6 \
              -max_target_seqs 1 \
              -out "$blast_files/${chrQ}_${chrS}.out"
      echo "$chrQ vs $chrS BLAST finished !"
    fi
  done
done

# Generate unique IDs for alignments and bed files
for b_out in $blast_files/*.out;
do
  file_id=$(basename $b_out)
  file_id=${file_id%.*}
  # Extracting query and subject chromosomes from filename
  q=${file_id#*_}
  s=${file_id%_*}
  echo "$b_out"
  awk -v ID=$file_id '{print $0,ID"_"NR}' $b_out > "$blast_files/b_tmp"
  mv "$blast_files/b_tmp" $b_out
  # Transform significant hits into intervals in bedfiles
  awk '$11 < 1e-10 {print $1,$7,$8,$12}' $b_out > "$blast_files/${q}_${s}.bed"
  awk '$11 < 1e-10 {print $2,$9,$10,$12}' $b_out > "$blast_files/${s}_${q}.bed"
  echo "BLAST output parsed, unique alignment IDs added for $b_out !"
done

# Intersect alignment sets
# Naming convention : coords_ID.
for Q in $chr_hits
do
  for a in $chr_hits
  do
    for b in $chr_hits
    do
      if [[ $Q != $a && \
            $Q != $b && \
            $a != $b ]]
      then
        echo "Looking for overlapping $Q - $a and $Q - $b alignments..."
        # Both output files will contain the same alignments and their
        # coordinates are in chrom Q, but they contain IDs in chromosomes a and
        # respectively.
        bedtools intersect -a "$blast_files/${Q}_${a}.bed" \
                           -b "$blast_files/${Q}_${b}.bed" \
                           -wa > "$blast_files/inter_${Q}_${a}.bed"
        bedtools intersect -a "$blast_files/${Q}_${a}.bed" \
                          -b "$blast_files/${Q}_${b}.bed" \
                          -wb > "$blast_files/inter_${Q}_${b}.bed"
      fi
    done
  done
done

# for each chrom, subset ID that are present in all 3chroms. (i.e. intersect of
# IDs in inter_Q_a and inter_b_a)
for Q in $chr_hits
do
  previous=""
  for bed in "$blast_files/inter*$Q.bed"
  do
    if [ -z $first ]
    then
      # First iteration: skip file and consider as previous
      previous=$(cut -f4 $bed | sort)
    else
      echo "Extracting IDs of alignments present in all chromosomes."
      # Next iterations: intersection of ID between current and previous files
      # extracting IDs from bed files
      currID=$(cut -f4 $bed | sort)
      comm -12 <($prevID) <($currID) > temp_$bed
      # Set current intersect with current file as previous
      previous=$(cat "temp_$bed")
    fi
  done
  mv "temp_$bed" "$blast_files/$Q_IDs.tsv"
  rm temp_*
done

module rm Blast/ncbi-blast/2.6.0+;
module rm UHTS/Analysis/BEDTools/2.26.0
