get_snp_37()
{
    remote_file=https://sharehost.hms.harvard.edu/genetics/reich_lab/sgdp/vcf_variants/vcfs.variants.public_samples.279samples.tar
    file=SS6004478.annotated.nh2.variants.vcf.gz
    data=$shared/$file

    if [ ! -f $data ]; then
        echo "Extracting one file $remote_file from $data"
        echo "NOTE: manually break download after file download is complete (199MB) so tar doesn't download the rest of the 57GB file. Run this script again after breaking."
        curl $1 --output - | tar xf - $data
    fi
}

get_data_file() # $1 remote 
{
    if [ ! -f $2 ]; then
        echo Downloading $1 to $shared
        wget $1 -P $(dirname $2) -P $shared || exit 1
    fi

    remote_file=$1
    data=$shared/$(basename $1)
}

get_reference() # $1=remote_ref $2=local_ref $3=fai $4=genozip $5=picard_dict
{
    if [ ! -f $2 ]; then
        echo Downloading $1 into $2
        wget $1 -P $(dirname $2) || exit 1
        downloaded=$(dirname $2)/$(basename $1)

        if [ "${downloaded##*.}" != gz ]; then
            bgzip -@20 $downloaded || exit 1
        fi
    fi

    if [ ! -f $3 ]; then
        echo Creating index file $3
        samtools faidx $2 || exit 1
    fi

    if [ ! -f $5 ]; then
        echo Creating dict file $5
        gatk CreateSequenceDictionary -R $2 -O $5 || exit 1
    fi

    if [ ! -f $4 ]; then
        echo Create Genozip reference file $4
        genozip --make-reference $2 || exit 1
    fi
}

get_hs37d5()
{
    prim_ref_remote=ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/phase2_reference_assembly_sequence/hs37d5.fa.gz
    prim_ref=$shared/hs37d5.fa.gz
    prim_ref_fai=$shared/hs37d5.fa.fai
    prim_ref_genozip=$shared/hs37d5.ref.genozip
    prim_ref_picard_dict=$shared/hs37d5.dict

    get_reference $prim_ref_remote $prim_ref $prim_ref_fai $prim_ref_genozip $prim_ref_picard_dict
}

get_GRCh38() # $1=[PRIM|LUFT] 
{
    GRCh38_remote=ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/GRCh38_reference_genome/GRCh38_full_analysis_set_plus_decoy_hla.fa
    GRCh38=$shared/GRCh38_full_analysis_set_plus_decoy_hla.fa.gz
    GRCh38_fai=$shared/GRCh38_full_analysis_set_plus_decoy_hla.fa.fai
    GRCh38_genozip=$shared/GRCh38_full_analysis_set_plus_decoy_hla.ref.genozip
    GRCh38_picard_dict=$shared/GRCh38_full_analysis_set_plus_decoy_hla.dict

    get_reference $GRCh38_remote $GRCh38 $GRCh38_fai $GRCh38_genozip $GRCh38_picard_dict

    if [ $1 = PRIM ]; then
        prim_ref=$GRCh38
        prim_ref_genozip=$GRCh38_genozip
    elif [ $1 = LUFT ]; then
        luft_ref=$GRCh38
        luft_ref_genozip=$GRCh38_genozip
    else
        echo "ERROR: get_GRCh38 expects parameter - either PRIM or LUFT"
    fi
}

get_chm13()
{
    luft_ref_remote=https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/chm13.draft_v1.0.fasta.gz
    luft_ref=$shared/chm13.draft_v1.0.fasta.gz
    luft_ref_fai=$shared/chm13.draft_v1.0.fasta.fai
    luft_ref_genozip=$shared/chm13.draft_v1.0.ref.genozip
    luft_ref_picard_dict=$shared/chm13.draft_v1.0.dict

    get_reference $luft_ref_remote $luft_ref $luft_ref_fai $luft_ref_genozip $luft_ref_picard_dict
}

get_chain() # $1=remote-chain (with .gz) $2=local-matched-chain (.match.chain) $3=local-matched-genozip-chain (.match.chain.genozip) 
                 # $4=prim_ref_genozip $5=luft_ref_genozip
{
    if [ ! -f $2 ] || [ ! -f $3 ]; then
        echo Downloading $1 
        wget $1 -P $(dirname $2) || exit 1
        downloaded=$(dirname $2)/$(basename $1)

        echo Creating $3 - a generated from $downloaded with contig names matching the reference files
        genozip $downloaded --reference $4 --reference $5 --match-chrom-to-reference --force --output $3 || exit 1

        echo Creating $2 - a chain file with contig names matching the reference files
        genounzip $3 || exit 1
    fi
}

get_chain_37_38()
{
    get_hs37d5
    get_GRCh38 LUFT

    remote_chain=http://ftp.ensembl.org/pub/assembly_mapping/homo_sapiens/GRCh37_to_GRCh38.chain.gz
    chain=$shared/GRCh37_to_GRCh38.matched.chain
    chain_genozip=${chain}.genozip
    prim_ref_genozip=$hs37d5_genozip
    luft_ref_genozip=$GRCh38_genozip

    get_chain $remote_chain $chain $chain_genozip $prim_ref_genozip $luft_ref_genozip
}

get_references_and_chain_38_t2t()
{
    get_GRCh38 PRIM
    get_chm13

    remote_chain=http://t2t.gi.ucsc.edu/chm13/hub/t2t-chm13-v1.0/hg38Lastz/hg38.t2t-chm13-v1.0.over.chain.gz
    chain=$shared/hg38.t2t-chm13-v1.0.over.matched.chain
    chain_genozip=${chain}.genozip
    prim_ref_genozip=$GRCh38_genozip
    luft_ref_genozip=$chm13_genozip

    get_chain $remote_chain $chain $chain_genozip $prim_ref_genozip $luft_ref_genozip
}

analysis() # $1=tool $2=tool_vcf $3=tool_rejects $4=dvcf
{
    echo "Comparing Genozip to $1"

    local ostatuses=`$genocat --show-ostatus-counts $4 | grep -v Showing|cut -f1`

    for st in $ostatuses ; do
        printf "Lifted $st: "; grep $st $2 | wc -l; printf "Failed $st: "; grep $st $3 |wc -l
    done | tee $result/analysis.${1}.txt
}

liftover_do() #1 LiftoverVcf --TAGS_TO_REVERSE $2 LiftoverVcf TAGS_TO_DROP (a non-empty list must start with a space)  
{
    dvcf=$result/${name}.d.vcf.genozip
    primary=$result/${name}.${prim}.annotated.vcf

    if [ ! -f $dvcf ]; then
        echo "Producing $dvcf : a DVCF with added line numbers + matching contig names to reference"
        $genozip -C ${chain_genozip} --add-line-numbers --match-chrom-to-reference $data -o $dvcf || exit 1
    fi

    if [ ! -f $primary ]; then
        echo "Producing $primary : a primary-coordinates VCF file, with added INFO/oSTATUS and line numbers"
        $genocat $dvcf --single -o $primary --show-ostatus || exit 1
    fi

    tool=CrossMap
    tool_vcf=$result/${name}.${luft}.${tool}.vcf
    tool_rejects=${tool_vcf}.unmap

    if [ ! -f $tool_vcf ]; then
        echo "Running CrossMap on $primary"

        CrossMap.py vcf $chain $primary $luft_ref $tool_vcf || exit 1

        analysis $tool $tool_vcf $tool_rejects $dvcf
    fi

    tool=picard
    tool_vcf=$result/${name}.${luft}.${tool}.vcf
    tool_rejects=$result/${name}.${luft}.${tool}.rejects.vcf

    if [ ! -f $tool_vcf ]; then
        echo "Running Picard LiftoverVcf on $primary, reversing tags $1 and dropping tags $2"

        if [ ! -f chm13.draft_v1.0.dict ]; then
            gatk CreateSequenceDictionary -R $luft_ref || exit 1
        fi

        picard -Xmx64g $picard LiftoverVcf --INPUT $primary --OUTPUT $tool_vcf --CHAIN $chain --REJECT ${tool_rejects} --REFERENCE_SEQUENCE $luft_ref $(sed 's/ / --TAGS_TO_REVERSE /g' <<< "$1") $(sed 's/ / --TAGS_TO_DROP /g' <<< "$2") --RECOVER_SWAPPED_REF_ALT || exit 1
#        java -Xmx64g -jar $picard LiftoverVcf --INPUT $primary --OUTPUT $tool_vcf --CHAIN $chain --REJECT ${tool_rejects} --REFERENCE_SEQUENCE $luft_ref $(sed 's/ / --TAGS_TO_REVERSE /g' <<< "$1") $(sed 's/ / --TAGS_TO_DROP /g' <<< "$2") --RECOVER_SWAPPED_REF_ALT || exit 1

        analysis $tool $tool_vcf $tool_rejects $dvcf
    fi
}

# Executables
genozip=genozip
genocat=genocat
picard=../picard.jar

# Paths
root=.
shared=$root/shared
result=${name}-${prim}-${luft}
dvcf=$result/${name}.d.vcf.genozip
primary=$result/${name}.${prim}.annotated.vcf

mkdir $result >& /dev/null

