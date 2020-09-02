#!/bin/bash

echo "
********************************************************************************

             CCC  WWW                CCC  WWW                CCC  WWW
           CC  :CC|  WW            CC  :CC|  WW            CC  :CC|  WW
          C :  W  C  | W          C :  W  C  | W          C :  W  C  | W
W        C  : W    C |  W        C  : W    C |  W        C  : W    C |  W
|W      C:  :W      C|  |W      C:  :W      C|  |W      C:  :W      C|  |W
| W    C :  W        C  | W    C :  W        C  | W    C :  W        C  | W    C
|  W  C  : W          C |  W  C  : W          C |  W  C  : W          C |  W  C
C  |WW:  WW            CC  |WW:  WW            CC  |WW:  WW            CC  |WW:
 CCC  WWW                CCC  WWW                CCC  WWW                CCC  WW

********************************************************************************
"

#Variables to set;

SPECIES="TEST"
Kmer=25

if find . -name "*fastq.gz" -o -name "*fq.gz" ; then
  echo ""
  echo "*********************** GZipped Files Found - Unzipping ************************"
  find . -name "*fastq.gz" -o -name "*fq.gz"| xargs -n1 gunzip -v
else
fi

#for i in `ls *1*.fast* | sed 's/_MERGE_R1.fastq.gz//'`
if find . -name "*.fa" -o -name "*.fastq" -o -name "*.fasta" | grep -q "." ; then
  echo ""
  echo "********************************* Variables ************************************"
  echo ""
  echo "Input Files:"
  echo ""
  INPUT_READS=$(find . -name "*.fa" -o -name "*.fastq" -o -name "*.fasta")
  echo $INPUT_READS
  echo ""
  echo "File output name; " $SPECIES
  echo ""
  echo "Kmer to be used; "$Kmer
  echo ""
  sleep 3s
  echo "********************************************************************************"
else
  echo "No input files found"
  echo "N.B. Ensure input files are in .fasta .fastq or .fa format"
  exit 1
fi

#########################
# FastQC
#########################

mkdir -p fastqc_output/
fastqc $INPUT_READS -outdir=fastqc_output/ -t 12

#########################
# Trimming
#########################

stringarray=($INPUT_READS)
READ1=${stringarray[0]} # Full file
READ1_FILENAME1=${READ1%.*} #Full file without file extension
READ2=${stringarray[1]}
READ2_FILENAME1=${READ2%.*}

echo "******************************** Trimming Adapters *******************************"
echo ""
/usr/local/bin/bbmap/bbduk.sh \
in1=${stringarray[0]} \
in2=${stringarray[1]} \
out1=${READ1_FILENAME1}_Trimmed.fastq \
out2=${READ2_FILENAME1}_Trimmed.fastq \
ref=/usr/local/bin/bbmap/resources/adapters.fa tpe
echo ""
echo "********************************************************************************"
echo ""
sleep 3s

#NOTE; Option "tbo" omitted. Trims BOTH reads if only ONE shows adapters to ensure same sizing

#########################
# FastQC
#########################

mkdir -p fastqc_output_trimmed/
fastqc ${READ1_FILENAME1}_Trimmed.fastq -outdir=fastqc_output_trimmed/ -t 12
fastqc ${READ2_FILENAME1}_Trimmed.fastq -outdir=fastqc_output_trimmed/ -t 12

#########################
# MultiQC
#########################

multiqc .
open multiqc_report.html

#########################
# Assembly
#########################

# https://github.com/bcgsc/abyss#install-abyss-on-mac-os-x
while true; do
    read -p "Do you wish to use trimmed data? `echo $'\n> '`" yn
    case $yn in
        [Yy]* ) abyss-pe name=$SPECIES k=$Kmer in="${READ1_FILENAME1}_Trimmed.fastq ${READ2_FILENAME1}_Trimmed.fastq"; break;;
        [Nn]* ) abyss-pe name=$SPECIES k=$Kmer in="$READ1_FILENAME1.fastq $READ2_FILENAME1.fastq"; break;;
        cancel|Cancel|exit|Exit|quit|Quit ) exit 1 ; break;;
        * ) echo "Please answer yes or no. Or type cancel to quit";;
    esac
done

cat $SPECIES\-stats



#Name - Eventual output naming
#k -
#K -
#in - Input reads

#########################
# Annotation - Optional
#########################

#########################
# Final QC
#########################

# py .quast.py
