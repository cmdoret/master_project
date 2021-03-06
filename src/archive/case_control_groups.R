# In this script I use a naive test for allelic association
# to test for association with homozygosity in males. The test should be performed 
# only within a category of family (inferred from diploid male production).
# Cyril Matthey-Doret
# 18.08.2017

#======== LOAD DATA =========#
# Loading libraries for data processing and visualisation
library(dplyr);library(readr);library(ggplot2)
in_args <- commandArgs(trailingOnly = T)
# Input files for grouping families by genotypes (OBSOLETE)
groups_path <- in_args[1]
groups <- read.table(groups_path, header = T)
# Input table with proportion of homozygous individuals
hom_path <-in_args[2]
sum_stat <- read_tsv(file=hom_path, col_names=T, col_types = "iciddddddc")
# Output folder
out_folder <- in_args[3]

#======= PROCESS DATA =======#
# Cleaning input table: removing SNPS absent in all samples
sum_stat <- sum_stat[sum_stat$N.Males>0 & sum_stat$N.Females>0,]
sum_stat <- sum_stat[!is.na(sum_stat$Prop.Hom),]

# Map families to mother categories (OBSOLETE)
#sum_stat$cluster <- groups$cluster[match(sum_stat$Family, groups$Family)]
#sum_stat <- sum_stat[!is.na(sum_stat$cluster),]

# Compute proportion per family category
#cat_stat <- sum_stat %>%
#  group_by(Locus.ID, Chr, BP, cluster) %>%
#  summarise(Nf=sum(N.Females), Nm=sum(N.Males), N=sum(N.Samples), 
#            Prop.Hom=sum(Prop.Hom*N.Samples, na.rm=T)/sum(N.Samples, na.rm=T), 
#            Prop.Hom.F=sum(Prop.Hom.F*N.Females, na.rm=T)/sum(N.Females, na.rm=T), 
#            Prop.Hom.M=sum(Prop.Hom.M*N.Males, na.rm=T)/sum(N.Males, na.rm=T))


#==== COMPUTE STATISTICS ====#
# Compute assocation on each cat. separately (OBSOLETE)
# Output single file with corrected significant p-values with
# associatied SNP and category.
# Abbreviations: M: Males, F: Females, T: Male+Female, 
# o:homozygous, e:heterozygous, t:hom+het, E: Expected

get_fisher <- function(df){
  # Computes fisher exact test on one row of the dataframe.
  # alternative=greater -> test if males are more heterozygous than females
  # alternative=less -> test if males are more homozygous than females
  mat <- matrix(as.numeric(df[c("Fo","Mo","Fe","Me")]), ncol=2)
  f <- fisher.test(as.table(mat), alt="less")
  return(f$p.value)
}


odds_list <- cat_stat %>% 
  rename(Ft = Nf, Mt = Nm, Tt = N) %>%
  mutate(Fo = Ft * Prop.Hom.F, Mo = Mt * Prop.Hom.M, 
         Fe = Ft * (1-Prop.Hom.F), Me = Mt * (1-Prop.Hom.M),
         To = Tt * Prop.Hom, Te = Tt * (1-Prop.Hom)) %>%
  select(-Prop.Hom, -Prop.Hom.F, -Prop.Hom.M) %>%
  mutate_at(funs(round(.,0)), .vars = c("Fo","Fe","Mo","Me"))

odds_list$fisher <- apply(odds_list, 1,  get_fisher)

odds_list$fisher <- p.adjust(odds_list$fisher, method = "bonferroni")
#for(group in unique(odds_list$cluster)){
#  odds_list$fisher[odds_list$cluster==group] <- p.adjust(odds_list$fisher[odds_list$cluster==group], method = "BH")
#}
#nloci <- log2(max(groups$cluster)+1)
nloci=2
#========= VISUALISE ========#
odds_chrom <- odds_list[grep("chr.*",odds_list$Chr),]
pdf(paste0(out_folder, "/../plots/","case_control_hits_",nloci,"loci.pdf"), width=12, height=12)
ggplot(data=odds_chrom, aes(x=BP, y=-log10(fisher))) + geom_point() + facet_grid(~Chr, space='free_x', scales = 'free_x') +  
  geom_hline(aes(yintercept=-log10(0.05))) + geom_hline(aes(yintercept=-log10(0.01)), lty=2, col='red') + 
  xlab("Genomic position") + ylab("-log10 p-value") + ggtitle("Case-control association test for CSD") + ylim(c(0,10)) + 
  theme_bw()
dev.off()

# Unmapped contigs
odds_cont <- odds_list[grep("tig.*",odds_list$Chr),]
tigs <- unique(odds_cont$Chr[odds_cont$fisher<0.01])  # Contigs with significant hits
odds_cont <- odds_cont[odds_cont$Chr %in% tigs,]
ggplot(data=odds_cont, aes(x=BP, y=-log10(fisher))) + geom_point() + 
  geom_hline(aes(yintercept=-log10(0.05))) + geom_hline(aes(yintercept=-log10(0.01)), lty=2, col='red') + 
  xlab("Genomic position") + ylab("-log10 p-value") + ggtitle("Case-control association test for CSD: Unordered contigs") + 
  ylim(c(0,10)) + facet_wrap(~Chr, scales='free_x')
#======= WRITE OUTPUT =======#
# Number of groups is (2^n)-1 where n is the number of CSD loci
nloci <- log2(max(groups$cluster)+1)
odds_chrom_sig <- odds_chrom[odds_chrom$fisher<=0.05,]
write.table(odds_chrom_sig, paste0(out_folder, "case_control_hits.tsv"), 
            sep='\t', row.names=F, quote=F)
