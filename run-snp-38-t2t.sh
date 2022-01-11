#!/bin/bash

# (C) 2021-2022 Divon Lan

# Names
name=snp
prim=38
luft=t2t

source include.sh

# Get data
get_snp_38
get_references_and_chain_38_t2t

# lift over using the 3 tools
liftover_do " AF MLEAF" " AC"
