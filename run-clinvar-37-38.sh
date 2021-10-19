#!/bin/bash

# (C) 2021 Divon Lan

# Names
name=clinvar
prim=37
luft=38

source include.sh

# Get data
get_data_file ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh37/weekly/clinvar_20210724.vcf.gz $shared/clinvar.37.vcf.gz
get_references_and_chain_37_38

# lift over using the 3 tools
liftover_do " AF_ESP AF_EXAC AF_TGP" ""
