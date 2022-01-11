#!/bin/bash

# (C) 2021-2022 Divon Lan

# removes all files, except the downloaded reference, chain and data files

rm -Rf clinvar-37-38 clinvar-38-t2t snp-37-38 snp-38-t2t indel-37-38 indel-38-t2t 
rm -f shared/*.matched.* shared/snp.38.vcf shared/indel.37.vcf shared/indel.38.vcf

