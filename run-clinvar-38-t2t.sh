#!/bin/bash

# Names
name=clinvar
prim=38
luft=t2t

source include.sh

# Get data
get_data_file ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh38/weekly/clinvar_20210724.vcf.gz
get_references_and_chain_38_t2t

# lift over using the 3 tools
liftover_do " AF_ESP AF_EXAC AF_TGP" ""
