#!/bin/bash

salmon index -t ../transcriptomes/EBV_akata_annotated_sequence.txt -i ebv_index

salmon quant -i ebv_index \
            -l A -r ../data/d0_day21/SRR8514723.fastq \
            -p 8 -o quants/
