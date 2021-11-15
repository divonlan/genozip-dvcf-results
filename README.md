This folder contains the scripts needed to reproduce the DVCF results as reported. These are:

- `run-all.sh` - runs the other 6 run-* scripts in sequence
- `run-*`      - 6 scripts for running the 6 analyses { snp, indel, clinvar} X { 37-to-38, 38-to-t2t }
- `reset.sh`  - deletes all the the files generated, but NOT the files in the shared directory downloaded from the Internet
- `reset-factory-defaults.sh` - deletes all files downloaded or generated.

**Note:** these scripts download all the data required from the Internet, into the "shared" directory. It is possible that you already have some of these files stored locally - in this case, you can copy or symbolic link them into this directory, to avoid downloading them again:

### Reference files:
1) ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/phase2_reference_assembly_sequence/hs37d5.fa.gz
2) ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/GRCh38_reference_genome/GRCh38_full_analysis_set_plus_decoy_hla.fa
3) https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/chm13.draft_v1.0.fasta.gz

### Chain files:
1) http://ftp.ensembl.org/pub/assembly_mapping/homo_sapiens/GRCh37_to_GRCh38.chain.gz
2) http://t2t.gi.ucsc.edu/chm13/hub/t2t-chm13-v1.0/hg38Lastz/hg38.t2t-chm13-v1.0.over.chain.gz

### Data files:
1) The file SS6004478.annotated.nh2.variants.vcf.gz which is the first file in this tar acrhive: https://sharehost.hms.harvard.edu/genetics/reich_lab/sgdp/vcf_variants/vcfs.variants.public_samples.279samples.tar (only this file is downloaded, not the entire tar file)
2) ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000G_2504_high_coverage/working/20201028_3202_raw_GT_with_annot/20201028_CCDG_14151_B01_GRM_WGS_2020-08-05_chr22.recalibrated_variants.vcf.gz
3) ftp://ftp-trace.ncbi.nih.gov/1000genomes/ftp/release/20110521/ALL.chr22.phase1_release_v3.20101123.snps_indels_svs.genotypes.vcf.gz
4) ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh38/weekly/clinvar_20210724.vcf.gz
5) ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh37/weekly/clinvar_20210724.vcf.gz

### Pre-requisite software:
1) Genozip - installation options: https://genozip.com/installing.html
2) GATK - tested on version 4.1.7
3) CrossMap.py - tested on version 0.5.2 installed from conda
4) samtools - tested on version 1.11 installed from conda
5) common utilities: wget, curl, gzip

Questions? support@genozip.com

