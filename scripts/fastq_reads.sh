#!/bin/bash
cd ..
rm -r data
rm -r quants
mkdir quants
mkdir quants/human
mkdir quants/ebv
mkdir data

cd data

days=(0 2 4 7 14 21 28)

for donor in {0..2}; 
do
  # for day in 0 2 4 7 14 21 28;
  for day in {0..6};
  do
    mkdir d${donor}_day${days[$day]};
    cd d${donor}_day${days[$day]}; 
    srr_number=$((8514718 + ($day + ($donor*7))))

    # get experiment reads
    # I was reading SRA files smh
    # curl https://sra-pub-run-odp.s3.amazonaws.com/sra/SRR${srr_number}/SRR${srr_number} \
    #	    -o SRR${srr_number};

    echo "fasterq dumping"

    fasterq-dump SRR${srr_number}

    echo "dumped to FASTQ format"
    cd ..;
  done 
done
