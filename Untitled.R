# # Helpful links
# https://hbctraining.github.io/DGE_workshop_salmon/lessons/01_DGE_setup_and_overview.html
# http://bioconductor.org/packages/devel/bioc/vignettes/DESeq2/inst/doc/DESeq2.html
# "The pseudocounts generated by Salmon are represented as normalized TPM 
# (transcripts per million) counts and map to transcripts. These need to be 
# converted into non-normalized count estimates for performing DESeq2 analysis. 
# To use DESeq2 we also need to collapse our abundance estimates from the transcript 
# level to the gene-level. We will be using the R Bioconductor package tximport to 
# do all of the above and get set up for DESeq2."

# To get a bunch of the packages
if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
library(BiocManager)
BiocManager::install()
BiocManager::install("DESeq2")
BiocManager::install("tximport")
BiocManager::install("tximportData")
BiocManager::install("AnnotationHub")
BiocManager::install("apeglm")
BiocManager::install("preprocessCore")
install.packages("preprocessCore")


## Setup
### Bioconductor and CRAN libraries used
library(DESeq2)
library(tidyverse)
library(RColorBrewer)
library(pheatmap)
library(tximport)
library(ggplot2)
library(ggrepel)
library(apeglm)


# To load in Salmon results
library("tximport")
library("readr")
library("tximportData")
library(sf)

# dir <- system.file("extdata", package="tximportData")

# # Load in counts across donor and day and genome
# # Collate into one frame
# all_samples = data.frame(Name = character(), NumReads = character(), Day = character(), Donor = character(), Genome = character())
# for (donor_num in 1:3) {
#   for (day_num in list(0, 2, 4, 7, 14, 21)) {
#     for (genome_flag in list("E", "H")) {
#       # Read in specific salmon results, and add a column to indicate the day and the donor
#       file_name <- string(donor_num)+string(day_num)+genome_flag+"quant.sf"
#       df <- read.table(file.path(dir,file_name), header=TRUE) # or st_read(path)?
#       specific_samples <- df[, c(Name, NumReads)]
#       specific_samples$Day <- day_num
#       specific_samples$Donor <- donor_num
#       specific_samples$Genome <- genome_flag
#       all_samples <- rbind(all_samples, specific_samples)
#     }
#   }
# }

# print(all_samples)




######################### TXI LOAD IN SALMON ######################

library(tximportData)
library("AnnotationHub")
library(AnnotationHub)



# set the working directory
setwd("/Users/acavet/Desktop/ebv_project/")

# which genome
# human, ebv_mutu, ebv_akata
curr_genome <- "human"

# List all files, then filter to just quant file names and paths 
all_files <- list.files(path = paste("./quants/", curr_genome, sep=""), recursive = TRUE, full.names = TRUE)
quant_files <- all_files[grep("quant.sf$", all_files)]
quant_files

# if ebv genome, d0_day0 all NaN, so remove!!!!
if (curr_genome != "human") {
  quant_files <- quant_files[-grep("d0_day0", all_files)]
  #quant_files <- quant_files[grep("day0", quant_files, invert=TRUE)]
}
quant_files

# label each quant file by sample
named_quants <- quant_files
names(named_quants) <- str_replace(quant_files, paste("./quants/",curr_genome,"/",sep=""), "") %>% 
  str_replace("/quant.sf", "")
named_quants



# # Connect to the AnnotationHub database
# ah <- AnnotationHub()
# 
# # Query the AnnotationHub database
# query <- query(ah, c("genome", "hg19"))
# query <- query(ah, c("genome", "Gencode", "Homo sapiens"))
# query <- query(ah, c("akata"))
# query

# # Get the first result of the query (assuming there is only one result)
# genome <- ah[query[[1]]]
# 
# # Download the genome file
# genome_file <- genome[[1]]
# 
# # Save the genome file to your working directory
# write.table(genome_file, "hg19_genome.txt", quote=FALSE, sep="\t", col.names=FALSE, row.names=FALSE)



# FOR HUMAN: 
# # Load the annotation/index table used for Salmon, so we can convert the gene
# # labels in the "Name" column of the quant files back to gene info
tx2gene_full <- read.delim("human_gene_labels.txt")
tx2gene_full %>% View()
# tx2gene_cropped <- tx2gene_full[c("Transcript.stable.ID", "Gene.stable.ID")]
# names(tx2gene_cropped)[names(tx2gene_cropped) == "Transcript.Stable.ID"] <- "TXNAME"
# names(tx2gene_cropped)[names(tx2gene_cropped) == "Gene.stable.ID"] <- "GENEID"
# # this annotation table is a dataframe with columns transcript ID, gene ID, gene symbol
# # tximport will use the first 2 cols to convert our quant info to the raw counts we need
# tx2gene_cropped %>% View()
# https://bioconductor.org/packages/devel/bioc/vignettes/tximport/inst/doc/tximport.html


?tximport

# txi: we use the TPM column to get quantities on the scale of original counts,
# no longer correlated with transcript length across samples <- FAKE NEWS
# txi <- tximport(named_quants, type="salmon", tx2gene=tx2gene[,c("tx_id", "ensgene")], countsFromAbundance="lengthScaledTPM", ignoreTxVersion = TRUE)

txi <- tximport(named_quants, type="salmon", tx2gene=NULL, txOut = TRUE, countsFromAbundance="lengthScaledTPM", ignoreTxVersion = TRUE)
# NOTE: our quant files have "versions" on the gene labels (ENST00000456328.2
# instead of ENST00000456328, for example), so we add the argument ignoreTxVersion = TRUE
# to split on the . and ignore version
txi

# txi contains abundance, counts, length
attributes(txi)

# view counts
txi$counts %>% View()



# write counts to an object
data <- txi$counts %>%
  round() %>%
  data.frame()

data

#  we need metadata: a file which maps samples across days/donors/genomes to the sample groups that we are investigating
#  each column (eg d0_day2) of txi becomes a row, with day and donor information columns
# vector of col names
donorday_cols <- colnames(data)
donorday_cols
# empty dataframe with the row names
txi_metadata <- data.frame(matrix(nrow = length(donorday_cols), ncol = 0))
rownames(txi_metadata) <- donorday_cols

txi_metadata$donor <- substring(rownames(txi_metadata), 2, 2)
txi_metadata$day <- substring(rownames(txi_metadata), 7, nchar(rownames(txi_metadata)))
txi_metadata

# # TODO delete this
# sampletype <- factor(c(rep("control",3), rep("MOV10_knockdown", 2), rep("MOV10_overexpression", 3)))
# meta <- data.frame(sampletype, row.names = colnames(txi$counts))






######################### DESeq2 WORK ######################


# # Load in salmon results
# files <- file.path(dir,"salmon", all_samples$Name, "quant.sf.gz")
# names(files) <- all_samples$Name
# tx2gene <- read_csv(file.path(dir, "tx2gene.gencode.v27.csv"))
# txi <- tximport(files, type="salmon", tx2gene=tx2gene)

# Construct deseq dataset from the txi object and sample inforation
library("DESeq2")

# Remove any NA values
# txi <- na.omit(txi)

# txi = txi[complete.cases(txi), ]
ddsTxi <- DESeqDataSetFromTximport(txi,
                                   colData = txi_metadata,
                                   design = ~ day) # ?? TODO choose factors
ddsTxi

# # Remove any NA values
# ddsTxi <- na.omit(ddsTxi)

# As in the paper, we only keep genes with at least 20 expression counts
keep <- rowSums(counts(ddsTxi)) >= 20
ddsTxi <- ddsTxi[keep,]
ddsTxi


# # Set reference level to day 0
# ddsTxi$condition <- relevel(ddsTxi$condition, ref = "0") # TODO make day 0

# Run DESeq2 
ddsDone <- DESeq(ddsTxi)


# # Extract differentially expressed genes (this will autocompare day 0 to 7)
# res <- results(ddsDone)
# res



# List of all days compared to day 0
days_versus_0 = resultsNames(ddsDone)
days_versus_0
# "day_14_vs_0" "day_2_vs_0"  "day_21_vs_0" "day_28_vs_0" "day_4_vs_0" "day_7_vs_0"
day_cmp <- "day_14_vs_0"


# Empty dataframes to merge all gene results into, 
# one for all genes expressed (ie analyzed, their counts were kept in >= 20)
# one for all genes with Bonferroni correct p value of less than 0.01 for diff exp
results_index_df <- data.frame(results(ddsDone, contrast=list(day_cmp), pAdjustMethod="bonferroni"))
all_days_v0 <- data.frame(matrix(nrow = nrow(results_index_df), ncol = 0))
rownames(all_days_v0) <- rownames(results_index_df)
all_days_v0$Transcript.stable.ID <- gsub("\\..*", "", row.names(all_days_v0))
all_days_v0_significant <- all_days_v0
all_days_v0_significant

for (day_cmp in days_versus_0) {
  save_path <- paste("./DESeq2_results/",curr_genome,"/",curr_genome,"_",day_cmp,sep="")
  
  # For each day compared with 0, save genes with <0.01 p values to dataframe and graph
  # Apply bonferroni correction for p values
  resdays <- results(ddsDone, contrast=list(day_cmp), pAdjustMethod="bonferroni")
  
  # Add transcript id (currently the row names) as a column for merging
  resdays$Transcript.stable.ID <- gsub("\\..*", "", row.names(resdays))
  resdays
  
  # Show <0.01 p values
  no_na = resdays[complete.cases(resdays), ] # get rid of any rows with NAs
  less_than_001 <- no_na[no_na$padj < 0.01, ]
  less_than_001
  # less_than_001_unadj <- no_na[no_na$pvalue < 0.01, ]
  # less_than_001_unadj
  
  # Merge in all results + significant results to dfs based on transcript id,
  # label columns with day vs day numbers
  resdays_labeled <- data.frame(resdays)
  names(resdays_labeled) <- paste0(names(data.frame(resdays)), "_", day_cmp)
  names(resdays_labeled)[names(resdays_labeled) == paste("Transcript.stable.ID", "_", day_cmp, sep="")] <- "Transcript.stable.ID"
  resdays_labeled
  all_days_v0 <- merge(resdays_labeled, all_days_v0, by = "Transcript.stable.ID", all.x=TRUE)
  
  
  
  #https://www.aaos.org/aaosnow/2012/apr/research/research7/
  
  png_name <- paste(save_path,"_count_vs_logfold.png",sep="")
  png(png_name)
  
  # Plot
  # plotMA(no_na, ylim=c(-5,5))
  # title(main =paste(curr_genome, " genes, ", day_cmp, sep=""))
  
  
  # Different plot
  plot(no_na$baseMean, no_na$log2FoldChange, main=paste(curr_genome, " genes, ", day_cmp, sep=""),
       xlab="Gene Expression Mean", ylab="Log 2 Fold Change", pch = 20, cex = 1, col = alpha(1, 0.6), ylim=c(-30,30))
  points(less_than_001$baseMean, less_than_001$log2FoldChange, pch = 20, cex = 1, col = alpha("red", 0.1), ylim=c(-30,30))
  
  # Save plot
  dev.off()
  
  getMethod("plotMA","DESeqDataSet")
  
  
  # Save to appropriate directories
  write.csv(resdays, file = paste(save_path,"_diffgeneexpr.csv",sep=""))
  write.csv(less_than_001, file = paste(save_path,"_diffgeneexpr_pval_lt01.csv",sep=""))
  
  
  
  
  ## TODO:
  # DID add new gene expression graphs with p value highligting
  # DID add bonferroni
  # DID figure out NaN, must change paper to reflect EBV compared day 0, NO SIG RESULTS
  # DID find and add gene names http://useast.ensembl.org/index.html add to paper
  # save metadata: # up/down regulated, which days most up/down regulated, combine to see how many genes across all days
  
  
  # # Shrinkage of effect size (LFC estimates) ??
  # resLFC <- lfcShrink(ddsDone, coef="day_14_vs_0", type="apeglm")
  # resLFC
  
  # plotMA(resLFC, ylim=c(-5,5))
}

######################### Data finalizing and further analysis ###################### 

all_days_v0 %>% View()

# Merge in gene information based on Ensemble transcript ID
resdays <- merge(as(resdays,"data.frame"), tx2gene_full, by = "Transcript.stable.ID")
resdays %>% View()

