#!/bin/bash

source $(dirname $0)/argparse.bash || exit 1
argparse "$@" <<EOF || exit 1
parser.add_argument('bam')
parser.add_argument('outdir')
parser.add_argument('-fastq', '--fastq', action='store_true', default=False,
                    help='Forse [default %(default)s]')
parser.add_argument('-fasta', '--fasta', action='store_true', default=False,
                    help='Forse [default %(default)s]')
parser.add_argument('-f', '--force', action='store_true', default=False,
                    help='Forse [default %(default)s]')
EOF

DIR_CODE=`dirname $(readlink -f "$0")`

echo required infile: "$INBAM"
echo required outfile: "$OUTDIR"


ORGANISM='human'
DB="$DIR_CODE/db_$ORGANISM"

#Add MiniConda to PATH if it's available.
if [ -d "$DIR_CODE/tools/MiniConda/bin" ]; then
    echo "Add MiniConda to PATH if it's available"
    export PATH="$DIR_CODE/tools/MiniConda/bin:$PATH"
fi

#Convert to absolute paths.
BAM=`readlink -m "$BAM"`
OUTDIR=`readlink -m "$OUTDIR"`

#Check if BAM exists.
if [ ! -e "$BAM" ]
then
    echo "Error: $BAM doesn't exist." >&2
    exit 1
fi

#Check if OUTDIR exists, then make it.
if [ -d "$OUTDIR" ]
then
    if [[ $FORCE ]]
    then
        rm -fr "$OUTDIR"
    else
        echo "Error: The directory $OUTDIR exists. Please choose a" \
            'different directory in which to save results of the analysis, or' \
            'use the -f option to overwrite the directory.' >&2
        exit 1
    fi
fi
mkdir -p "$OUTDIR"

start=`date +%s`
echo  "Start needle analysis ... "$start

megahit=${DIR_CODE}/tools/megahit/build/megahit
prefix=$(basename $BAM | awk -F ".bam" '{print $1}')
SAMPLE=${OUTDIR}"/"${prefix}


UNMAPPED=""

echo "Extract unmapped reads from " $BAM
if [[ $FASTA ]]
then
echo "FASTA is provided"
perl ${DIR_CODE}/fasta_to_fastq.pl $BAM > ${SAMPLE}.unmapped.fastq
UNMAPPED=${SAMPLE}.unmapped.fastq
elif [[ $FASTQ ]]
then
echo "FASTQ is provided"
UNMAPPED=$BAM
else
echo "BAM file is provided"


samtools view -H $BAM | grep SN | awk '{print $2}' | awk -F ":" '{if ($1=="SN") print $2}' | sort | uniq | grep -v chr  | grep -v "^[1-9]$" | grep -v "^[1-9][0-9]$" | grep -v "^MT$" | grep -v "^X$" | grep -v "^Y$" | grep -v "GL000">${OUTDIR}/non.human.references.txt





echo "Number of non human references"
wc -l ${OUTDIR}/non.human.references.txt
#rm -fr ${SAMPLE}.non.human.fastq
while read line
do
echo $line
samtools view -bh $BAM $line | samtools fastq - >> ${SAMPLE}.non.human.fastq
done<${OUTDIR}/non.human.references.txt


samtools view -f4 -bh $BAM | samtools bam2fq - >${SAMPLE}.unmapped.fastq
cat ${SAMPLE}.non.human.fastq ${SAMPLE}.unmapped.fastq >${SAMPLE}.cat.unmapped.fastq

wc -l ${SAMPLE}.non.human.fastq


#rm -fr ${SAMPLE}.unmapped.fastq
UNMAPPED=${SAMPLE}.cat.unmapped.fastq
fi


echo "------>Number of unmapped reads"
wc -l $UNMAPPED 



bwa mem -a ${DB}/viral.vipr/NONFLU_All.fastq $UNMAPPED | samtools view -S -b -F 4 - | samtools sort - >${SAMPLE}.virus.bam
bwa mem -a ${DB}/fungi/fungi.ncbi.february.3.2018.fasta $UNMAPPED | samtools view -S -b -F 4 - |  samtools sort - >${SAMPLE}.fungi.bam
bwa mem -a ${DB}/protozoa/protozoa.ncbi.february.3.2018.fasta $UNMAPPED | samtools view -S -b -F 4 - | samtools sort - >${SAMPLE}.protozoa.bam

samtools index ${SAMPLE}.virus.bam
samtools index ${SAMPLE}.fungi.bam
samtools index ${SAMPLE}.protozoa.bam
samtools fastq ${SAMPLE}.virus.bam >${SAMPLE}.virus.fastq
samtools fastq ${SAMPLE}.fungi.bam >${SAMPLE}.fungi.fastq
samtools fastq ${SAMPLE}.protozoa.bam >${SAMPLE}.protozoa.fastq

rm -fr ${SAMPLE}*bam
rm -fr ${SAMPLE}*bai

$megahit --k-step 10 -r ${SAMPLE}.virus.fastq -o ${SAMPLE}.virus.megahit --out-prefix virus.megahit
$megahit --k-step 10 -r ${SAMPLE}.fungi.fastq -o ${SAMPLE}.fungi.megahit --out-prefix fungi.megahit
$megahit --k-step 10 -r ${SAMPLE}.protozoa.fastq -o ${SAMPLE}.protozoa.megahit --out-prefix protozoa.megahit
mv ${SAMPLE}.virus.megahit/virus.megahit.contigs.fa ${SAMPLE}.virus.megahit.contigs.fa
mv ${SAMPLE}.fungi.megahit/fungi.megahit.contigs.fa ${SAMPLE}.fungi.megahit.contigs.fa
mv ${SAMPLE}.protozoa.megahit/protozoa.megahit.contigs.fa ${SAMPLE}.protozoa.megahit.contigs.fa


"-------->Number of assembled contigs"
wc -l ${SAMPLE}.virus.megahit.contigs.fa
wc -l ${SAMPLE}.fungi.megahit.contigs.fa
wc -l ${SAMPLE}.protozoa.megahit.contigs.fa



# index contigs and map reads onto contigs
bwa index ${SAMPLE}.virus.megahit.contigs.fa
bwa mem ${SAMPLE}.virus.megahit.contigs.fa ${SAMPLE}.virus.fastq | samtools view -S -b -F 4 - | samtools sort - >${SAMPLE}.megahit.contigs.virus.bam



samtools depth ${SAMPLE}.megahit.contigs.virus.bam>${SAMPLE}.megahit.contigs.virus.cov
samtools view -H ${SAMPLE}.megahit.contigs.virus.bam >${OUTDIR}/header.sam
samtools view -F 4  ${SAMPLE}.megahit.contigs.virus.bam | grep -v -e 'XA:Z:' -e 'SA:Z:'| cat ${OUTDIR}/header.sam - | samtools view -b - | samtools depth - >${SAMPLE}.megahit.contigs.virus.uniq.cov




#fungi----
bwa index ${SAMPLE}.fungi.megahit.contigs.fa
bwa mem ${SAMPLE}.fungi.megahit.contigs.fa ${SAMPLE}.fungi.fastq | samtools view -S -b -F 4 - | samtools sort - >${SAMPLE}.megahit.contigs.fungi.bam


samtools depth ${SAMPLE}.megahit.contigs.fungi.bam>${SAMPLE}.megahit.contigs.fungi.cov
samtools view -H ${SAMPLE}.megahit.contigs.fungi.bam >${OUTDIR}/header.sam
samtools view -F 4  ${SAMPLE}.megahit.contigs.fungi.bam | grep -v -e 'XA:Z:' -e 'SA:Z:'| cat ${OUTDIR}/header.sam - | samtools view -b - | samtools depth - >${SAMPLE}.megahit.contigs.fungi.uniq.cov


#protozoa----
bwa index ${SAMPLE}.protozoa.megahit.contigs.fa
bwa mem ${SAMPLE}.protozoa.megahit.contigs.fa ${SAMPLE}.protozoa.fastq | samtools view -S -b -F 4 - | samtools sort - >${SAMPLE}.megahit.contigs.protozoa.bam


samtools depth ${SAMPLE}.megahit.contigs.protozoa.bam>${SAMPLE}.megahit.contigs.protozoa.cov
samtools view -H ${SAMPLE}.megahit.contigs.protozoa.bam >${OUTDIR}/header.sam
samtools view -F 4  ${SAMPLE}.megahit.contigs.protozoa.bam | grep -v -e 'XA:Z:' -e 'SA:Z:'| cat ${OUTDIR}/header.sam - | samtools view -b - | samtools depth - >${SAMPLE}.megahit.contigs.protozoa.uniq.cov

echo "-----------------------------------------------------"
echo "Map assembled contigs onto the microbial references"

bwa mem -a ${DB}/viral.vipr/NONFLU_All.fastq ${SAMPLE}.virus.megahit.contigs.fa | samtools view -bS -F 4 - | samtools sort -  >${SAMPLE}.virus.megahit.contigs.SV.bam
bwa mem -a ${DB}/fungi/fungi.ncbi.february.3.2018.fasta ${SAMPLE}.fungi.megahit.contigs.fa  | samtools view -bS -F 4 - | samtools sort -   >${SAMPLE}.fungi.megahit.contigs.SV.bam
bwa mem -a ${DB}/protozoa/protozoa.ncbi.february.3.2018.fasta ${SAMPLE}.protozoa.megahit.contigs.fa  | samtools view -bS -F 4 - | samtools sort - >${SAMPLE}.protozoa.megahit.contigs.SV.bam


samtools index ${SAMPLE}.virus.megahit.contigs.SV.bam
samtools index ${SAMPLE}.fungi.megahit.contigs.SV.bam
samtools index ${SAMPLE}.protozoa.megahit.contigs.SV.bam


#virus, fungi or protozoa
python ${DIR_CODE}/process.BWA.py -o virus ${SAMPLE}.virus.megahit.contigs.SV.bam ${SAMPLE}.virus.megahit.contigs.SV.csv
python ${DIR_CODE}/process.BWA.py -o fungi ${SAMPLE}.fungi.megahit.contigs.SV.bam ${SAMPLE}.fungi.megahit.contigs.SV.csv
python ${DIR_CODE}/process.BWA.py -o protozoa ${SAMPLE}.protozoa.megahit.contigs.SV.bam ${SAMPLE}.protozoa.megahit.contigs.SV.csv

echo "-----------------------------------------------------"
echo "Map assembled contigs onto the entire TREE of life to verify specificity of assembled contigs"

blastn -query ${SAMPLE}.virus.megahit.contigs.fa -db nt -task megablast -dust no -outfmt "7 qseqid sseqid pident qlen length mismatch" -max_target_seqs 10 -out ${SAMPLE}.virus.megahit.contigs.BLAST.csv -remote
blastn -query ${SAMPLE}.virus.megahit.contigs.fa -db nt -task megablast -dust no -max_target_seqs 10 -out ${SAMPLE}.virus.megahit.contigs.BLAST.long.csv -remote
python ${DIR_CODE}/process.blast.py ${SAMPLE}.virus.megahit.contigs.BLAST.csv ${SAMPLE}.virus.megahit.contigs.BLAST.long.csv ${SAMPLE}.virus.megahit.contigs.BLAST.house.format.csv

python ${DIR_CODE}/tree.of.life.filter.py ${SAMPLE}.virus.megahit.contigs.BLAST.house.format.csv ${SAMPLE}.virus.megahit.contigs.SV.csv ${SAMPLE}.virus.megahit.contigs.SV.filtered.csv

blastn -query ${SAMPLE}.protozoa.megahit.contigs.fa -db nt -task megablast -dust no -outfmt "7 qseqid sseqid pident qlen length mismatch" -max_target_seqs 10 -out ${SAMPLE}.protozoa.megahit.contigs.BLAST.csv -remote
blastn -query ${SAMPLE}.protozoa.megahit.contigs.fa -db nt -task megablast -dust no -max_target_seqs 10 -out ${SAMPLE}.protozoa.megahit.contigs.BLAST.long.csv -remote
python ${DIR_CODE}/process.blast.py ${SAMPLE}.protozoa.megahit.contigs.BLAST.csv ${SAMPLE}.protozoa.megahit.contigs.BLAST.long.csv ${SAMPLE}.protozoa.megahit.contigs.BLAST.house.format.csv
python ${DIR_CODE}/tree.of.life.filter.py ${SAMPLE}.protozoa.megahit.contigs.BLAST.house.format.csv ${SAMPLE}.protozoa.megahit.contigs.SV.csv ${SAMPLE}.protozoa.megahit.contigs.SV.filtered.csv



blastn -query ${SAMPLE}.fungi.megahit.contigs.fa -db nt -task megablast -dust no -outfmt "7 qseqid sseqid pident qlen length mismatch" -max_target_seqs 10 -out ${SAMPLE}.fungi.megahit.contigs.BLAST.csv -remote
blastn -query ${SAMPLE}.fungi.megahit.contigs.fa -db nt -task megablast -dust no -max_target_seqs 10 -out ${SAMPLE}.fungi.megahit.contigs.BLAST.long.csv -remote
python ${DIR_CODE}/process.blast.py ${SAMPLE}.fungi.megahit.contigs.BLAST.csv ${SAMPLE}.fungi.megahit.contigs.BLAST.long.csv ${SAMPLE}.fungi.megahit.contigs.BLAST.house.format.csv
python ${DIR_CODE}/tree.of.life.filter.py ${SAMPLE}.fungi.megahit.contigs.BLAST.house.format.csv ${SAMPLE}.fungi.megahit.contigs.SV.csv ${SAMPLE}.fungi.megahit.contigs.SV.filtered.csv


echo "Contigs after filtering are here"
wc -l ${SAMPLE}.virus.megahit.contigs.SV.filtered.csv
wc -l ${SAMPLE}.fungi.megahit.contigs.SV.filtered.csv
wc -l ${SAMPLE}.protozoa.megahit.contigs.SV.filtered.csv


echo "Success!!!"




