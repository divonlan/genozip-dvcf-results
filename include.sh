# (C) 2021 Divon Lan

progress() ## print progress line
{
    printf ">>>\n>>> $1\n>>>\n"
}

get_snp_37()
{
    remote_file=https://sharehost.hms.harvard.edu/genetics/reich_lab/sgdp/vcf_variants/vcfs.variants.public_samples.279samples.tar
    file=SS6004478.annotated.nh2.variants.vcf.gz
    data=$shared/$file

    if [ ! -f $data ]; then
        progress "Extracting one file $remote_file from $data\nNOTE: manually break download after file download is complete (199MB) so tar doesn't download the rest of the 57GB file. Run this script again after breaking."
        curl $1 --output - | tar xf - $data
    fi
}

get_data_file() # $1=remote $2=local (optional)
{
    remote_file=$1
    
    if [ data = "" ]; then
        data=$shared/$(basename $1)
    else
        data=$2
    fi

    if [ ! -f $data ]; then
        progress "Downloading $1 to $shared"
        wget $1 -P $shared || exit 1
        mv $shared/$(basename $1) $data
    fi
}

get_reference() # $1=remote_ref $2=local_ref $3=fai $4=genozip $5=gatk_dict
{
    downloaded=$shared/$(basename $1) # as it appears on the server (.gz or not)
    downloaded_gz=$downloaded # with .gz
    if [ "${downloaded_gz##*.}" != gz ]; then
        downloaded_gz=${downloaded_gz}.gz
    fi

    if [ ! -f $downloaded ] && [ ! -f $downloaded_gz ]; then
        echo "Downloading $1 into $shared"
        wget $1 -P $shared || exit 1
    fi

    # update variables to match actual files found (possibly from a previous run)
    if [ -f $downloaded_gz ]; then
        downloaded=$downloaded_gz
    elif [ -f ${downloaded_gz%.gz} ]; then
        downloaded=${downloaded_gz%.gz}
    fi

    # If it is compressed with gzip rather than bgzip (bgzip is needed by samtools faidx), uncompress first
    if [ "$downloaded" == "$downloaded_gz" ] && [ "`od -x $downloaded | head -1 | grep 4342`" == "" ]; then 
        progress "Uncompressing $downloaded_gz because it is compressed with gzip instead of bgzip"
        gzip -d $downloaded_gz || exit 1
        downloaded=${downloaded%.gz}
    fi

    # if not compressed, compress with bgzip
    if [ "$downloaded" != "$downloaded_gz" ]; then
        progress "Compressing $downloaded with bgzip"
        bgzip -@20 $downloaded || exit 1
    fi

    if [ ! -f $3 ]; then
        progress "Creating index file $3"
        samtools faidx $2 || exit 1
    fi

    if [ ! -f $5 ]; then
        echo "Creating dict file $5"
        gatk CreateSequenceDictionary -R $2 -O $5 || exit 1
    fi
    
    if [ ! -f $4 ]; then
        echo "Create Genozip reference file $4"
        $genozip --make-reference $2 || exit 1
    fi
}

get_hs37d5()
{
    # note: ftp://ftp.1000genomes.ebi.ac.uk sometimes doesn't work properly. If that's the case, replace ftp:// with https:// (a lot slower)
    # OR: find another source for this common reference file
    prim_ref_remote=ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/phase2_reference_assembly_sequence/hs37d5.fa.gz
    prim_ref=$shared/hs37d5.fa.gz
    prim_ref_fai=$shared/hs37d5.fa.gz.fai
    prim_ref_genozip=$shared/hs37d5.ref.genozip
    prim_ref_gatk_dict=$shared/hs37d5.dict

    get_reference $prim_ref_remote $prim_ref $prim_ref_fai $prim_ref_genozip $prim_ref_gatk_dict
}

get_GRCh38() # $1=[PRIM|LUFT] 
{
    # note: ftp://ftp.1000genomes.ebi.ac.uk sometimes doesn't work properly. If that's the case, replace ftp:// with https:// (a lot slower)
    # OR: find another source for this common reference file
    GRCh38_remote=ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/GRCh38_reference_genome/GRCh38_full_analysis_set_plus_decoy_hla.fa
    GRCh38=$shared/GRCh38_full_analysis_set_plus_decoy_hla.fa.gz
    GRCh38_fai=$shared/GRCh38_full_analysis_set_plus_decoy_hla.fa.gz.fai
    GRCh38_genozip=$shared/GRCh38_full_analysis_set_plus_decoy_hla.ref.genozip
    GRCh38_gatk_dict=$shared/GRCh38_full_analysis_set_plus_decoy_hla.dict

    get_reference $GRCh38_remote $GRCh38 $GRCh38_fai $GRCh38_genozip $GRCh38_gatk_dict

    if [ $1 = PRIM ]; then
        prim_ref=$GRCh38
        prim_ref_genozip=$GRCh38_genozip
    elif [ $1 = LUFT ]; then
        luft_ref=$GRCh38
        luft_ref_genozip=$GRCh38_genozip
    else
        progress "ERROR: get_GRCh38 expects parameter - either PRIM or LUFT"
    fi
}

get_chm13()
{
    luft_ref_remote=https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/chm13.draft_v1.0.fasta.gz
    luft_ref=$shared/chm13.draft_v1.0.fasta.gz
    luft_ref_fai=$shared/chm13.draft_v1.0.fasta.gz.fai
    luft_ref_genozip=$shared/chm13.draft_v1.0.ref.genozip
    luft_ref_gatk_dict=$shared/chm13.draft_v1.0.dict

    get_reference $luft_ref_remote $luft_ref $luft_ref_fai $luft_ref_genozip $luft_ref_gatk_dict
}

get_chain() # $1=remote-chain (with .gz) $2=local-matched-chain (.match.chain) $3=local-matched-genozip-chain (.match.chain.genozip) 
                 # $4=prim_ref_genozip $5=luft_ref_genozip
{
    downloaded=$shared/$(basename $remote_chain)

    if [ ! -f $downloaded ]; then
        echo "Downloading $1 "
        wget $1 -P $shared || exit 1
    fi

    if [ ! -f $3 ]; then
        progress "Creating $3 - generated from $downloaded with contig names matching the reference files"
        $genozip $downloaded --reference "$4" --reference "$5" --match-chrom-to-reference --force --output "$3" || exit 1
    fi

    if [ ! -f $2 ]; then
        progress "Creating $2 - a chain file with contig names matching the reference files"
        $genounzip $3 || exit 1
    fi
}

get_references_and_chain_37_38()
{
    get_hs37d5
    get_GRCh38 LUFT

    remote_chain=http://ftp.ensembl.org/pub/assembly_mapping/homo_sapiens/GRCh37_to_GRCh38.chain.gz
    chain=$shared/GRCh37_to_GRCh38.matched.chain
    chain_genozip=${chain}.genozip

    get_chain $remote_chain $chain $chain_genozip $prim_ref_genozip $luft_ref_genozip
}

get_references_and_chain_38_t2t()
{
    get_GRCh38 PRIM
    get_chm13

    remote_chain=http://t2t.gi.ucsc.edu/chm13/hub/t2t-chm13-v1.0/hg38Lastz/hg38.t2t-chm13-v1.0.over.chain.gz
    chain=$shared/hg38.t2t-chm13-v1.0.over.matched.chain
    chain_genozip=${chain}.genozip

    get_chain $remote_chain $chain $chain_genozip $prim_ref_genozip $luft_ref_genozip
}

analysis() # $1=tool $2=tool_vcf $3=tool_rejects $4=dvcf
{
    progress "Comparing Genozip to $1"

    local ostatuses=`$genocat --show-ostatus-counts $4 | grep -v Showing|cut -f1`

    for st in $ostatuses ; do
        printf "Lifted $st: "; grep $st $2 | wc -l; printf "Failed $st: "; grep $st $3 |wc -l
    done | tee $result/analysis.${1}.txt
}

prerequisite() # $1=excutable name $2=additional message (optional)
{
    # Check prerequisites
    if ! `command -v $1 >& /dev/null`; then 
        echo "Error: Cannot find $1. It is required. $2"
        exit 1
    fi
}

liftover_do() #1 LiftoverVcf --TAGS_TO_REVERSE $2 LiftoverVcf TAGS_TO_DROP (a non-empty list must start with a space)  
{
    dvcf=$result/${result}.d.vcf.genozip
    primary=$result/${name}.${prim}.annotated.vcf

    if [ ! -f $dvcf ]; then
        progress "Producing $dvcf : a DVCF with added line numbers + matching contig names to reference"
        $genozip --chain ${chain_genozip} --add-line-numbers --match-chrom-to-reference $data -o $dvcf || exit 1
    fi

    $genocat --show-counts=o\$TATUS $dvcf > $result/analysis.Genozip.txt

    if [ ! -f $primary ]; then
        progress "Producing $primary : a primary-coordinates VCF file, with added INFO/oSTATUS and line numbers"
        $genocat $dvcf --single -o $primary --show-ostatus || exit 1
    fi

    tool=CrossMap
    tool_vcf=$result/${name}.${luft}.${tool}.vcf
    tool_rejects=${tool_vcf}.unmap

    if [ ! -f $tool_vcf ]; then
        progress "Running CrossMap on $primary"

        $crossmap vcf $chain $primary $luft_ref $tool_vcf || exit 1

        analysis $tool $tool_vcf $tool_rejects $dvcf
    fi

    tool=gatk
    tool_vcf=$result/${name}.${luft}.${tool}.vcf
    tool_rejects=$result/${name}.${luft}.${tool}.rejects.vcf

    if [ ! -f $tool_vcf ]; then
        progress "Running GATK LiftoverVcf on $primary, reversing tags $1 and dropping tags $2"

        $gatk --java-options "-Xmx16g -XX:ParallelGCThreads=1" LiftoverVcf --INPUT $primary --OUTPUT $tool_vcf --CHAIN $chain --REJECT ${tool_rejects} --REFERENCE_SEQUENCE $luft_ref $(sed 's/ / --TAGS_TO_REVERSE /g' <<< "$1") $(sed 's/ / --TAGS_TO_DROP /g' <<< "$2") --RECOVER_SWAPPED_REF_ALT || exit 1

        analysis $tool $tool_vcf $tool_rejects $dvcf
    fi
}

prerequisite genozip "See installation instructions here: https://genozip.com/installing.html"
prerequisite gatk
prerequisite CrossMap.py
prerequisite samtools
prerequisite bgzip
prerequisite wget
prerequisite curl
prerequisite gzip

# Check prerequisites
if ! `command -v genozip >& /dev/null`; then 
    echo "Error: Cannot find genozip. It is required. See installation instructions here: https://genozip.com/installing.html"
    exit 1
fi

if ! `command -v samtools >& /dev/null`; then 
    echo "Error: Cannot find samtools. It is required."
    exit 1
fi

if ! `command -v gatk >& /dev/null`; then 
    echo "Error: Cannot find gatk. It is required."
    exit 1
fi

# Executables
genozip="genozip --echo"
genounzip="genounzip --echo"
genocat=genocat
gatk=gatk
crossmap=CrossMap.py

# Paths
shared=shared
result=${name}-${prim}-${luft}

mkdir $shared >& /dev/null
mkdir $result >& /dev/null
