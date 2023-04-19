#!/bin/bash
cd ..
rm -r quants
mkdir quants
mkdir quants/human
mkdir quants/ebv_akata
mkdir quants/ebv_mutu

cd data

days=(0 2 4 7 14 21 28)

for donor in {0..2}; 
do
  # for day in 0 2 4 7 14 21 28;
  for day in {0..6};
  do
    cd d${donor}_day${days[$day]}; 
    srr_number=$((8514718 + ($day + ($donor*7))))



    # quantify against human transcripts
#    salmon quant -i ../../indexes/gencode.v43.transcripts_index \
#	    -l A -r SRR${srr_number}.fastq \
#	    -p 8 -o ../../quants/human/d${donor}_day${days[$day]}/

#    echo "quantified against human transcripts"

    # quantify against ebv akata transcripts
#    salmon quant -i ../../indexes/ebv_akata_index \
#	    -l A -r SRR${srr_number}.fastq \
#	    -p 8 -o ../../quants/ebv_akata/d${donor}_day${days[$day]}/

#    echo "quantified against EBV-akata"

    # quantify against ebv mutu transcripts
    salmon quant -i ../../indexes/ebv_mutu_index \
	    -l A -r SRR${srr_number}.fastq \
	    -p 8 -o ../../quants/ebv_mutu/d${donor}_day${days[$day]}/

    echo "quantified against EBV-mutu"
    cd ..
  done
done 
