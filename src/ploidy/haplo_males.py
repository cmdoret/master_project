# This script allows to differentiate between haploid and diploid males based on
# heterozygosity. It generates takes a table containing summarised statistics
# from the parsed vcf file of populations, a table with generation, sex and
# family information of each individual. And output a table containing all this
# data, along with ploidy information of each individual.
# Cyril Matthey-Doret
# 11.05.2017

import numpy as np  # Powerful vectorized methods on arrays
import pandas as pd  # Convenient data frames
from sys import argv  # Command line arguments
from math import sqrt


def ploidy(indiv,mult=1,transf=None):
    """
    This function returns a table with individuals and their ploidy, inferred
    based on parameters that were passed. Haploids and diploids sons are split
    using the inbreeding coefficient of daughters (dau):
    haploids > mean(dau) + mult * transf(stdev(dau))
    where mean and stdev are the mean and standard deviation of inbreeding
    coefficient of daughters.

    :param individuals: pd.Dataframe of individuals with names, sex, families,
    generations and inbreeding coefficients
    :param mult: Multiplier used to scale threshold
    :param transf: Optional function applied to transform threshold behaviour
    :return: A pandas.DataFrame object containing information of the input table
    plus an additional column with ploidy information: Diploid (D) or Haploid
    (H)
    """

    # Subsetting daughters from family table
    daughters = indiv.loc[(indiv.Sex == 'F') & (indiv.Generation=='F4')]

    # Summary statistics of inbreeding coefficient within each family
    Fis_ref = pd.DataFrame({'MEAN':daughters.groupby(['Family'])['F'].mean(),
                             'STD':daughters.groupby(['Family'])['F'].std()})

    # Subsetting males and grouping by family
    males = indiv[indiv.Sex == 'M'].groupby(['Family'])

    # Subsetting haploid males in each family and filtering by threshold
    # computed from daughters.
    if transf:  # If a transformation was passed to the function
        haplo = males.apply(lambda g:
                              g[g['F'] >= (Fis_ref.loc[g.name,'MEAN'] +
                                    mult * transf(Fis_ref.loc[g.name,'STD']))])
    else:
        haplo = males.apply(lambda g:
                              g[g['F'] >= (Fis_ref.loc[g.name,'MEAN'] +
                                    mult * Fis_ref.loc[g.name,'STD'])])

    # Appending new column to family table with ploidy information
    indiv['Ploidy'] = np.where(indiv.Name.isin(haplo.Name),
                                             'D','H')
    return fam_sum

# 1: read individuals table to extract families of mothers
fam_sum = pd.read_csv("data/individuals",sep='\t')

# 2: Using command line argument to load VCF file summary
vcf_sum = pd.read_csv(argv[1], sep='\t')
# vcf_sum = pd.read_csv('../misc/vcftools/summary_d-25_r-75', sep='\t')

# 3: Merging both table to get a single table with all infos
fam_sum = fam_sum.merge(vcf_sum, left_on='Name', right_on='INDV', how='inner')
fam_sum.drop('INDV',axis=1,inplace=True)

def square(n):
    return n*n

# 4: output list of males with ploidy information for different parameter values
benchmark_set = {'mult':list(range(1,5)),
                 'transf':[[sqrt,'sqrt'],[square,'square']]}

for m in benchmark_set['mult']:  # Looping over all combination of param values
    out_m = ploidy(fam_sum,mult=m)  # Without transformation
    out_m.to_csv('data/ploidy/m' + str(m), sep='\t')
    for t in benchmark_set['transf']:
        out_m_t = ploidy(fam_sum,mult=m,transf=t[0])  # With transformation
        out_m_t.to_csv('data/ploidy/m' + str(m) + t[1], sep='\t')

#out_haplo = fam_sum.loc[fam_sum.Sex == 'M',['Name','Family']]
#out_haplo = out_haplo.merge(haplo,on='Name',how='inner')[['Name','Family_x']]
#out_haplo.rename(columns={'Family_x':'Family'},inplace=True)
