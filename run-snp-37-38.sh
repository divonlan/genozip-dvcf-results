#!/bin/bash

# (C) 2021 Divon Lan

# Names
name=snp
prim=37
luft=38

source include.sh

# Get data
get_snp_37
get_references_and_chain_37_38

# lift over using the 3 tools
liftover_do " AF MLEAF" " AC"

# delete 38 data file as we have now generate a source DVCF
rm -f $shared/snp.38.vcf
