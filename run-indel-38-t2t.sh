#!/bin/bash

# (C) 2021-2022 Divon Lan

# Names
name=indel
prim=38
luft=t2t

source include.sh

# Get data
src=20201028_CCDG_14151_B01_GRM_WGS_2020-08-05_chr22.recalibrated_variants.vcf.gz
get_data_file ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000G_2504_high_coverage/working/20201028_3202_raw_GT_with_annot/$src $shared/$src
get_references_and_chain_38_t2t

data=$shared/indel.38.vcf

if [ ! -f $shared/${src%.gz}.genozip ]; then
    rm -f $data
    $genozip $shared/$src -o $shared/${src%.gz}.genozip || exit 1
fi

if [ ! -f $data ]; then
    $genocat $shared/${src%.gz}.genozip --samples 1 --indels-only -fo $data || exit 1
fi

# lift over using the 3 tools
liftover_do " AF MLEAF AF_EUR AF_EAS AF_AMR AF_SAS AF_AFR AF_EUR_unrel AF_EAS_unrel AF_AMR_unrel AF_SAS_unrel AF_AFR_unrel" \
            " AC MLEAC AC_EUR AC_EAS AC_AMR AC_SAS AC_AFR AC_EUR_unrel AC_EAS_unrel AC_AMR_unrel AC_SAS_unrel AC_AFR_unrel AC_Hom_EUR AC_Hom_EAS AC_Hom_AMR AC_Hom_SAS AC_Hom_AFR AC_Hom AC_Het_EUR AC_Het_EAS AC_Het_AMR AC_Het_SAS AC_Het_AFR AC_Het AC_Hom_EUR_unrel AC_Hom_EAS_unrel AC_Hom_AMR_unrel AC_Hom_SAS_unrel AC_Hom_AFR_unrel AC_Het_EUR_unrel AC_Het_EAS_unrel AC_Het_AMR_unrel AC_Het_SAS_unrel AC_Het_AFR_unrel"
