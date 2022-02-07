#if (!requireNamespace("BiocManager", quietly = TRUE))
#  install.packages("BiocManager")
#BiocManager::install("rtracklayer")
library(data.table)
library(tidyverse)
library(rtracklayer)
library(scales)

setwd(".")

#####
#prepare data
#####
#All data based on GRCh38
#SNP switches obtained with Genozip and vcftools
#genocat snp-37-38.d.vcf.genozip  --grep OkRefAltSwitchSNP --luft --show-dvcf -HG | cut -f3,4 > SNPswitches.38.txt
switches <- fread("SNPswitches.38.txt", sep = "\t", header = F, stringsAsFactors = F) %>% #input is already sorted, no need to sort again
  setnames(c("chr", "start")) %>% #set header names
  mutate_at("chr", str_replace, "chr", "") %>% #delete string chr in chromosome names
  mutate(chr = case_when(chr == "X" ~ 23,
                         chr == "Y" ~ 24, 
                         TRUE ~ as.numeric(chr))) %>% #recode X as 23 and Y as 24, all other chromosome numbers are numeric type. Ignore warnings
  mutate(end = start + 1) #add end column with row values = start +1 to make it a 0-based bed file

#human genome issues in GRCh38 obtained from https://ftp.ncbi.nlm.nih.gov/pub/grc/human/GRC/Issue_Mapping/GRCh38_issues.gff3
#transform the gff3 file into data.table
issues <- as.data.table(readGFF("GRCh38_issues.gff3",
                                columns = c("start", "end"), #select columns start and end
                                tags = c("chr", "type"))) %>% #select tags chr and type
  filter(!grepl('Housekeeping', type)) %>% #delete rows that contain type tag GRC Housekeeping
  filter(!grepl('Un', chr)) %>% #delete rows that contain unknown chromosomes
  relocate(chr, start, end) %>% #reorder columns
  select(- type) %>% #remove type column
  mutate(chr = case_when(chr == "X" ~ 23,
                         chr == "Y" ~ 24, 
                         TRUE ~ as.numeric(chr))) %>% #recode X as 23 and Y as 24, all other chromosome numbers are numeric type. Ignore warnings
  group_by(chr) %>% #group data by chromosome
  arrange(start) %>% #sort by starting position in each group
  mutate(indx = c(0, cumsum(as.numeric(lead(start)) > 
                              cummax(as.numeric(end)))[-n()])) %>% #create indx and record aggregate overlaps based on start and end positions
  group_by(chr, indx) %>% #group data by chromosome and indx
  summarise(start = min(start), end = max(end)) %>% #summarise all overlapping intervals
  setDT() %>% #output of summarise is a data.frame, convert back to data.table
  select(- indx) #remove indx column
  

#data.table with count of SNP switches in issues intervals 
setkey(issues, chr, start, end)
switchesInIssues <- foverlaps(switches, issues, type="any") %>% #report overlaps and non-overlaps of switches within issues intervals
  mutate(chr = replace(chr, rowSums(is.na(select(., start))) > 0, NA)) %>% #start and end are NA if switch does not overlap with any issue. Recode chr as NA in these cases
  add_count(chr, start) %>% #create column n with count of number of duplicate rows based on issues intervals
  distinct(chr, start, .keep_all= TRUE) %>% #remove duplicate lines based on issues intervals
  select(- i.start, - i.end) #remove superfluous columns

sumSwitches <- switchesInIssues %>%
  relocate(Switches = chr) %>% #rename chr column into Switches
  mutate(Switches = case_when(!is.na(Switches) ~ "in GRC issues",
                         TRUE ~ "not in GRC issues")) %>% #recode NA as "not in GRC issues" and all other chromosome numbers as "in GRC issues"
  group_by(Switches) %>% #group data by Switches
  summarise(total = sum(n)) #obtain the number of switches for "not in GRC issues" and "in GRC issues"



#####
#prepare plots
#####
#pie chart of % of SNP switches in reported GRC issues 
p0 <- ggplot(sumSwitches, aes(x = "", y = total, fill = Switches)) +
  geom_bar(width =1 , colour = "black", stat = "identity") +
  coord_polar("y", start = 0) +
  #  scale_fill_grey() + 
  scale_fill_manual(values = c(palette.colors(palette = "Okabe-Ito")[[7]],
                               "white")) +
  theme_minimal() +
  theme(axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        panel.border = element_blank(),
        panel.grid = element_blank(),
        axis.ticks = element_blank()) +
  theme(axis.text.x = element_blank()) +
  geom_text(aes(label = paste(round(total / sum(total) * 100, 1), "%")),
            position = position_stack(vjust = 0.5),
            colour = palette.colors(palette = "Okabe-Ito")[[3]]) +
  theme(legend.position = 'right')

ggsave("issues_switches_summary_pie.pdf", width = 5, height = 3) #save plot

#bar chart of % of SNP switches in reported GRC issues 
p1 <- ggplot(sumSwitches, aes(x = Switches, y = total, fill = Switches)) +
  geom_bar(width =1 , colour = "black", stat = "identity") +
  scale_fill_manual(values = c(palette.colors(palette = "Okabe-Ito")[[7]],
                               "white")) +
  scale_y_continuous(labels = unit_format(unit = "k", scale = 1e-3, accuracy = 1)) +
  theme_minimal() +
  theme(axis.ticks = element_blank(),
        axis.text.x = element_text(colour = "black"),
        legend.position = "none") +
  xlab(element_blank()) +
  ylab("REF<=>ALT SNP switches") +
  geom_text(aes(label = paste(round(total / sum(total) * 100, 1), "%")),
            position = position_stack(vjust = 0.5),
            colour = palette.colors(palette = "Okabe-Ito")[[3]])

ggsave("issues_switches_summary_bar.pdf", width = 3, height = 4) #save plot
 
