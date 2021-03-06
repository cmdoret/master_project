
# Genetic basis of sex determination in a parasitoid wasp species
Master project for the Molecular Life Sciences master in Bioinformatics, University of Lausanne

### Cyril Matthey-Doret
### Supervisor: Casper Van der Kooi
### Director: Tanja Schwander
---
In this project, we use restriction-site associated DNA-sequencing (RAD-seq) and build a custom pipeline to locate and identify the complementary sex determination (CSD) locus/loci in the parasitoid wasp species _Lysiphlebus fabarum_. This repository contains a pipeline to map the reads using BWA and build loci using the different components of STACKS with optimal parameters. It was designed to run on a distributed High Performance Computing (HPC) environment with Platform load Sharing Facility (LSF).

## Instructions:
To run the pipeline with the data provided:
1. Download or clone this repository.
2. Download the `data` archive (not available yet) into the main folder
3. ```cd``` to the main folder
4. Untar the data using ```tar -xzvf data.tar.gz data```
5. Run the  pipeline
    1. On a cluster with LSF:
        + `make` to run the STACKS pipeline
    	+ `make assoc_mapping` to run the association mapping (needs STACKS data)
    	+ `make collinearity` to compute collinearity blocks (needs STACKS data)
    	+ `make wgs_wild` to run the analysis of wild WGS samples
    2. On a local machine
        + `make ref_local` to run the STACKS pipeline
        + `make assoc mapping` to run the association mapping (needs STACKS data)
        + `make collinearity LOCAL=yes` to compute collinearity blocks (needs STACKS data)
        + `make wgs_wild LOCAL=yes` to run the analysis of wild WGS samples


To run the STACKS pipeline with new data in the form of demultiplexed, trimmed single end reads in compressed fastq files (.fq.gz):
1. Describe your samples by writing 2 files named `popmap.tsv` and `individuals.tsv`, respectively. The structure of the `popmap.tsv` file is described on the [official STACKS website](http://catchenlab.life.illinois.edu/stacks/manual/) (here, populations should be the sex of individuals). The `individuals.tsv` file is a tab delimited text file with 4 columns with the following headers __included__:
* Name: The names of samples. This should be the name of their data files (e.g. if the sample name is SAMPLE1, the corresponding reads file should be named SAMPLE1.fq.gz).
* Sex: F for females and M for males.
* Family: Clutches to which the individual belongs. These can be any combination of alphanumeric characters.
* Generation: Useful if there are mothers and offspring. Values should be F3 for mothers and F4 for offspring.
2. Create an empty folder named data and place the 2 files inside. This folder needs to be located inside the same directory as src.
3. Place your (trimmed, demultiplexed) reads in a subfolder of data named `processed` and your reference genome in a subfolder named `ref_genome`. You will also need to edit the `REF` path in `config.mk` accordingly. If you wish to use different folder names, just edit the corresponding paths in `config.mk`.

4. Set the variable `D` in `config.mk` to 25 (minimum locus depth for STACKS populations). Type `make` in the command line (or `make `ref_local` if running on a local machine). Once the pipeline has finished running, set the variable `D` back to 5 and type `make ploidy` to infer ploidy from the homozygosity of variant sites. Note the threshold selected to define ploidy is adapted to the dataset presented here. You might want to define a threshold yourself by inspecting the distribution of homozygosity (HOM variable) in `data/ploidy/thresholds/fixed.tsv` and the variable `HOM_PLOID` in `config.mk` to this value. Once you have modified the threshold, run `make ploidy` again to update the ploidy classification with the new threshold.
5. Type `make -B` to run the pipeline again without haploids.

### Status:

![](https://placehold.it/15/00ff00/000000?text=+) __DONE:__ Quality control and Processing of RAD-seq data.

![](https://placehold.it/15/00ff00/000000?text=+) __DONE:__ Transformation of data into catalogue of loci.

![](https://placehold.it/15/00ff00/000000?text=+) __DONE:__ Measuring heterozygosity levels and other statistics per individual and per loci.

![](https://placehold.it/15/00ff00/000000?text=+) __DONE:__ Excluding haploid males and loci homozygous in mothers from the analysis.

![](https://placehold.it/15/00ff00/000000?text=+) __DONE:__ Locate centromeres for each chromosome.

![](https://placehold.it/15/00ff00/000000?text=+) __DONE:__ Perform association mapping to locate candidate region(s) for CSD.

![](https://placehold.it/15/00ff00/000000?text=+) __DONE:__ Look for annotated proteins in candidate region(s).

![](https://placehold.it/15/00ff00/000000?text=+) __DONE:__ Assemble transcriptome from larvae reference-aligned RNA-seq reads.

![](https://placehold.it/15/00ff00/000000?text=+) __DONE:__ Analyse collinearity of transcripts across genome to identify potential duplicated genes between candidate CSD regions.

![](https://placehold.it/15/00ff00/000000?text=+) __DONE:__ Validate CSD loci using signatures of balancing selection in whole genome sequencing from wild females.


![](https://placehold.it/15/00ff00/000000?text=+) __DONE:__ Look for annotated transcripts from larvae RNA-seq data.

![](https://placehold.it/15/00ff00/000000?text=+) __DONE:__ Streamline pipeline, add option to run without HPC and use a docker container for dependencies.


### Dependencies:
* [FastQC 0.11.5](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/): Quality control of sequencing data.
* [BWA 0.7.2](http://bio-bwa.sourceforge.net/)
* [STACKS 1.48](http://catchenlab.life.illinois.edu/stacks/)
* [SAMtools 1.3](http://samtools.sourceforge.net/)
* [VCFtools 0.1.13](https://vcftools.github.io/)
* [BEDtools 2.25](http://bedtools.readthedocs.io/)
* [DeepTools 2.4.2](http://deeptools.readthedocs.io/)
* [CuffLinks 2.2.1](http://cole-trapnell-lab.github.io/cufflinks/)
* [ncbi-BLAST+](https://blast.ncbi.nlm.nih.gov/Blast.cgi)
* [MCScanX](http://chibba.pgml.uga.edu/mcscan2/)
* [Trimmomatic](http://usadellab.org/cms/?page=trimmomatic)
* [R 3.3.x](https://www.r-project.org/)
  + [readr 1.1.1](https://cran.r-project.org/web/packages/readr/README.html)
  + [tidyr 0.7.0](https://cran.r-project.org/web/packages/tidyr/index.html)
  + [dplyr 0.7.2](https://www.rdocumentation.org/packages/dplyr/versions/0.7.2)
  + [ggplot2 2.2.1](http://ggplot2.org/)
  + [ggjoy 0.3.0](https://cran.r-project.org/web/packages/ggjoy/index.html)
  + [stringr 1.2.0](https://cran.r-project.org/web/packages/stringr/index.html)
  + [reshape2 1.4.2](https://cran.r-project.org/web/packages/reshape2/index.html)
  + [zoo 1.8-0](https://cran.r-project.org/web/packages/zoo/index.html)
  + [Rcpp](https://cran.r-project.org/web/packages/Rcpp/)
  + [RcppRoll](https://cran.r-project.org/web/packages/RcppRoll/)
  + [viridis 0.4.0](https://cran.r-project.org/web/packages/viridis/vignettes/intro-to-viridis.html)
  + [optparse](https://cran.r-project.org/web/packages/optparse)
* [Python 2.7.x](https://www.python.org/)
  + [numpy 1.11](http://www.numpy.org/)
  + [pandas 0.19](http://pandas.pydata.org/)
  + [matplotlib 1.5](https://matplotlib.org/)
  + [biopython 1.70](http://biopython.org/)
  + [pybedtools 0.7.10](http://daler.github.io/pybedtools/)

### Scripts

The `src` folders contains all scripts required to run the analysis along with other programs used for automated report generation and benchmarking. Those scripts are organized into several sub folders:

* `archive`: This folder contains previous versions of scripts and code snippets which may prove useful again.


* `process_reads`: This folder contains script for demultiplexing, trimming and removing adaptors from raw sequencing reads. These are not implemented in the pipeline as the processed reads are provided.
  + `process_reads`: Template for processing raw reads using the `process_radtags` module from STACKS, which allows to detect restriction sites from RAD-sequencing and perform all common read processing steps.
  + `qc.sh`: small template script for quality control using fastqc.


* `mapping`: This folder contains scripts used to map processed sequencing reads to the reference genome of _Lysiphlebus fabarum_.
  + `bwa_script.sh`: Coordinates the mapping of all samples using BWA, sending the output to `split_sam.pl`.
  + `parse_summaries.sh`: Produces a condensed summary table of reads mapped to the reference genome by parsing the log files from `split_sam.pl` produced with different mapping parameters.
  + `split_sam.pl`: Parses the output sam files to split single hits and multiple hits into separate files and convert the files into bam format.


* `misc`: This folder contains various scripts, most of which are not required for the main pipeline, but are needed for report generation, benchmarking and exploring the parameter space to optimize the pipeline.
  + `map_param.py`: Generates a line plot to visualize the mapping statistics produced by `parse_summaries.sh` in the report.
  + `parse_pstacks.sh`: Parses the log files obtained by pstacks with different parameter values to produce a table of summary statistics for the report.
  + `parse_cstacks.sh`: Parses the cstacks output catalogue to compute summary statistics and store them in a table for the report.
  + `parse_VCF.sh`: Uses vcftools to compute several statistics from the output VCF file returned by the populations module of STACKS and store them in text files inside the `vcftools` subfolder. This script is used in the `ploidy` Makefile rule, when inferring the ploidy of males.
  + `plot_VCF.R`: Produces barplots to visualize the output statistics extracted by `parse_VCF.sh`: Plots are stored in the `vcftools` subfolder and used in the report.
  + `assembly_stats.R`: Generates a table with standard descriptive statistics of the assembly (N50, number of contigs...).
  + `explo_assoc.py`: Uses genotype matrices of each family to measure proportion of heterozygosity across individuals of each SNPs, and producing visualizations. Also produces a list of SNPs that are homozygous in mothers and another list of "potential CSD candidates".
  + `SNP_stats.R`: Summarises lists of SNPs into number of SNPs per family for producing tables in lab book.


* `stacks_pipeline`: This folder contains scripts required to run the different components of the STACKS suite
  + `pstacks_script.sh`: Produces 'stacks' from processed reads, using the Pstacks module.
  + `cstacks_script.sh`: Constructs a catalogue of loci from the output of `pstacks_script.sh`. Only files containing at least 10% of the mean number of RAD-tags (computed over all files) are included in the catalogue to remove poor quality samples.
  + `group_sstacks.sh`: Copy pstacks and cstacks output files to the sample folder to provide a working directory for `multi_sstacks.sh`.
  + `sstacks_script.sh`: Produces 'match' files from pstacks and cstacks output files (stacks and catalogue, respectively).
  + `populations.sh`: Uses the populations module to compute populations statistics and generate different outputs from sstacks output files.

* `ploidy`: This folder contains scripts required to classify males as diploid or haploid based on the genomic data.
  + `haplo_males.py`: Uses a threshold to infer the ploidy of males.
  + `comp_thresh.R`: Plots the ploidy inferred by different threshold, using tables produces by `haplo_males.py`. Allows to visually selevt the most realistic threshold.
  + `prop_offspring.R`: Produces pie charts showing proportion of haploid males, diploid males and daughters for each family.


* `assoc_mapping`: This folder contains scripts used to locate candidate CSD region(s).
  + `assoc_map.R`: Performs the actual association mapping, incorporating linkage map information. (WIP)
  + `chrom_types.R`: Modeling recombination rates along chromosomes to locate centromeres and refine the list CSD hits using this information.
  + `blast_loci.sh`: Quickly blast candidate genomic regions.
  + `process_genomic.py`: Process genomic output from STACKS' populations module by transforming numeric encoding of genotypes into homozygous/heterozygous/missing, removing loci that are either homozygous or missing in mothers from their families and computing proportion of homozygous individuals per sex/family at each site.


* `coverage_analysis`: Contains analyses related to genomic coverage along genome or per sample.
  + `cov_per_site.sh`: computes average coverage per SNP in each family.
  + `cov_plotter.R`: Plots the coverages values computed by `cov_per_site.sh`.
  + `raw_reads.sh`: records the number of reads per sample.


### Data files

Once the `data.tar.gz` has been uncompressed, the data folder should contain the following files:

* `processed`: This folder contains the processed RAD-tags generated for each sample using process_radtags.
* `ref_genome`: This folder contains only the reference genome.
* `individuals.tsv`: Detailed characteristic of each individuals: Name, Sex, Family and Generation where F4 are son/daughter and F3 is the mother.
* `popmap.tsv`: Population map required by STACKS to match sample names to population group (i.e. male and female).
* `ploidy`: contains information about the ploidy of individuals in the dataset.

After the pipeline has been running, all intermediary and final output files will be generated and stored in their respective sub-folders inside `data`.

### Flowchart

Visual summary of how the pipeline works. Rectangles show operations/programs, diamonds represent data files. Red items are not included in the repository. Green fields are completed, yellow fields are still WIP.

<img src="reports/lab_book/flowchart.png" width="400">
