while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo "$package - attempt to capture frames"
      echo " "
      echo "$package [options] application [arguments]"
      echo " "
      echo "options:"
      echo "-h, --help                show brief help"
      echo "-v, --vcf=VCF       specify input vcf"
      echo "-r, --range=RANGE      specify the distance to gene centre to include markers"
      echo "-m, --MIT=MIT      specify the marker_independence_threshold to use"
      echo "-c, --CT=CT      specify the cluster_threshold to use"
      echo "-n, --name=NAME       specify name of gene to build script for"
      echo "-g, --newgene=NEWGENE      add gene information to my_gene_db.txt with fields: chr, start, end"
      echo "-o, --output-dir=DIR      specify a directory to store output in"
      echo "e.g. runHM.sh "
      exit 0
      ;;
     -v)
      shift
      if test $# -gt 0; then
        export VCF=$1
      else
        echo "no vcf specified"
        exit 1
      fi
      shift
      ;;
    --vcf*)
      export VCF=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
      -r)
      shift
      if test $# -gt 0; then
        export RANGE=$1
      else
        echo "no range specified"
        exit 1
      fi
      shift
      ;;
    --range*)
    export RANGE=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
      -m)
      shift
      if test $# -gt 0; then
      export MIT=$1
      else
      echo "no marker_independence_threshold specified"
        exit 1
        fi
        shift
        ;;
        --MIT*)
        export MIT=`echo $1 | sed -e 's/^[^=]*=//g'`
        shift
        ;;
      -c)
      shift
      if test $# -gt 0; then
        export CT=$1
      else
        echo "no cluster_threshold specified"
        exit 1
      fi
      shift
      ;;
    --CT*)
      export CT=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    -n)
      shift
      if test $# -gt 0; then
        export NAME=$1
      else
        echo "no gene name specified"
        exit 1
      fi
      shift
      ;;
    --name*)
      export NAME=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    -g)
      shift
      if test $# -gt 2; then
        export CHR=$1
        export GENESTART=$2
        export GENEEND=$3
        echo -e "${NAME}\t${CHR}\t${GENESTART}\t${GENEEND}" >> ../input/my_gene_db.txt
      else
        echo "new gene info to add to db not specified: put chromosome number in first field, bp of gene start in second and bp of gene end in third"
      fi
      shift
      ;;
    --newgene*)
      export CHR=`echo $1 | sed -e 's/^[^=]*=//g'`
      export GENESTART=`echo $3 | sed -e 's/^[^=]*=//g'`
      export GENEEND=`echo $2 | sed -e 's/^[^=]*=//g'`
      echo -e "\$NAME\t\$CHR\t\$GENESTART\t\$GENEEND" >> ../input/my_gene_db.txt
      shift
      ;;
    -o)
      shift
      if test $# -gt 0; then
        export OUTPUT=$1/
      else
        echo "no output dir specified"
        exit 1
      fi
      shift
      ;;
    --output-dir*)
      export OUTPUT=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    *)
      break
      ;;
  esac
done


echo -e "library(snpStats)
library(HaplotypeMiner)
library(ggplot2)

paramsHM${NAME} <- haplo_params(
   input_file = 'haploupe/input/nohet_fin_impu_bial_16_SNP_id_filt_all.hmp.txt',
   gene_db_file = 'haploupe/input/my_gene_db.txt',
   chr_db_file = 'haploupe/input/chr16_size.txt',
   structure_file = 'haploupe/input/impu_bial_16_SNP_id_filt_all.vcf.10.meanQ_HMformatted.txt',
   kinship_file = 'haploupe/input/nohet_fin_impu_bial_16_SNP_id_filt_all_kinship_HMformatted.txt',
   gene_name = '${NAME}',
   R2_measure = 'r2vs',
   cluster_R2 = 'r2',
   max_missing_threshold = 0.6,
   max_het_threshold = 0.3,
   min_alt_threshold = 0.01,
   min_allele_count = 4,
   cluster_threshold = ${CT},
   max_marker_to_gene_distance = ${RANGE},
   max_flanking_pair_distance = 2*${RANGE},
   marker_independence_threshold = ${MIT})

HM${NAME}_haplotypes <- haplo_selection(paramsHM${NAME}, verbose = TRUE)
str(HM${NAME}_haplotypes, max.level = 1)
HM${NAME}_haplotypes

graph_list_HM${NAME} <- list('All_markers' = 'density',
                   'Filtered_markers' = c('matrix', 'distance', 'genotypes'),
                   'Clustered_markers' = c('matrix', 'genotypes'),
                   'Selected_clusters' = c('matrix', 'genotypes'),
                   'Selected_markers' = c('matrix', 'genotypes'),
                    'Haplotypes' = c('genotypes'))
haplo_output(HM${NAME}_haplotypes, output_dir = '../analysis_output/HM${NAME}_CT${CT}_MIT${MIT}', graphs = graph_list_HM${NAME})

haplo_logfile(HM${NAME}_haplotypes, to_file = TRUE)

genotype_plot(snp_data = HM${NAME}_haplotypes\$Filtered_markers,
              gene_pos = HM${NAME}_haplotypes\$Parameters\$Gene_center,
              kept_markers = HM${NAME}_haplotypes\$Haplotypes\$Markers,
              assignment = HM${NAME}_haplotypes\$Haplotypes\$Assignment,
              name_order = FALSE) +
  theme(axis.text = element_text(size = 0.1))

genotype_plot(snp_data = HM${NAME}_haplotypes\$Haplotypes,
              gene_pos = HM${NAME}_haplotypes\$Parameters\$Gene_center,
              kept_markers = HM${NAME}_haplotypes\$Haplotypes\$Markers,
              assignment = NULL,
              name_order = TRUE)

density_plot(snp_data = HM${NAME}_haplotypes\$All_markers,
             center_pos = HM${NAME}_haplotypes\$Parameters\$Gene_center,
             chr_length = HM${NAME}_haplotypes\$Parameters\$Chromosome_length)

ld_plot(snp_data = HM${NAME}_haplotypes\$Filtered_markers,
        center_pos = HM${NAME}_haplotypes\$Parameters\$Gene_center,
        kept_markers = HM${NAME}_haplotypes\$Haplotypes\$Markers) +
  theme(axis.text = element_text(size = 5))

ld_plot(snp_data = HM${NAME}_haplotypes\$Clustered_markers,
        center_pos = HM${NAME}_haplotypes\$Parameters\$Gene_center,
        kept_markers = HM${NAME}_haplotypes\$Haplotypes\$Markers)

distance_plot(snp_data = HM${NAME}_haplotypes\$Filtered_markers,
              center_pos = HM${NAME}_haplotypes\$Parameters\$Gene_center,
              r2_threshold3 = HM${NAME}_haplotypes\$Parameters\$Marker_independence_threshold)" > HM${NAME}_CT${CT}_MIT${MIT}.r
scp haploupe/input/template.slm HM${NAME}_CT${CT}_MIT${MIT}.slm
sed -i "s/genename/HM${NAME}_CT${CT}_MIT${MIT}/g" HM${NAME}_CT${CT}_MIT${MIT}.slm
sbatch HM${NAME}_CT${CT}_MIT${MIT}.slm

##11/04 run runHM.sh -r 100000 -m 0.8 -c 0.5 -n Gm16_301_302_C0.5 -g 16 30100000 30200000 -o ../analysis_output/
##11/04 run runHM.sh -r 100000 -m 0.8 -c 0.6 -n Gm16_301_302_C0.6 -g 16 30100000 30200000 -o ../analysis_output/
##11/04 run runHM.sh -r 100000 -m 0.8 -c 0.7 -n Gm16_301_302_C0.7 -g 16 30100000 30200000 -o ../analysis_output/
##11/04 run runHM.sh -r 100000 -m 0.8 -c 0.8 -n Gm16_301_302_C0.8 -g 16 30100000 30200000 -o ../analysis_output/
##11/04 run runHM.sh -r 100000 -m 0.8 -c 0.9 -n Gm16_301_302_C0.9 -g 16 30100000 30200000 -o ../analysis_output/
generic_runHM.sh -i ../input/indep500_1_0.9_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -k ../input/nohet_fin_impu_bial_16_SNP_id_filt_all_kinship_HMformatted.txt -s ../input/impu_bial_16_SNP_id_filt_all.vcf.10.meanQ_HMformatted.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.9 -n Gm16_301_302_C0.6
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -k ../input/nohet_fin_impu_bial_16_SNP_id_filt_all_kinship_HMformatted.txt -s ../input/impu_bial_16_SNP_id_filt_all.vcf.10.meanQ_HMformatted.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.9 -c 0.6 -n Gm16_301_302_C0.6
generic_runHM.sh -r 100000 -m 0.8 -c 0.5 -n Gm16_301_302_C0.5_indep -g 16 30100000 30200000 -o ../analysis_output/
generic_runHM.sh -r 100000 -m 0.8 -c 0.6 -n Gm16_301_302_C0.6_indep -g 16 30100000 30200000 -o ../analysis_output/
generic_runHM.sh -r 100000 -m 0.8 -c 0.7 -n Gm16_301_302_C0.7_indep -g 16 30100000 30200000 -o ../analysis_output/
generic_runHM.sh -r 100000 -m 0.8 -c 0.8 -n Gm16_301_302_C0.8_indep -g 16 30100000 30200000 -o ../analysis_output/
generic_runHM.sh -r 100000 -m 0.8 -c 0.9 -n Gm16_301_302_C0.9_indep -g 16 30100000 30200000 -o ../analysis_output/
##no RS m09 noindep
generic_runHM.sh -i ../input/nohet_fin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.9 -c 0.5 -n Gm16_301_302_C0.5 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_fin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.9 -c 0.6 -n Gm16_301_302_C0.6 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_fin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.9 -c 0.7 -n Gm16_301_302_C0.7 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_fin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.9 -c 0.8 -n Gm16_301_302_C0.8 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_fin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.9 -c 0.9 -n Gm16_301_302_C0.9 -o ../analysis_output/
##no RS m08 noindep
generic_runHM.sh -i ../input/nohet_fin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.5 -n Gm16_301_302_C0.5 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_fin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.6 -n Gm16_301_302_C0.6 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_fin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.7 -n Gm16_301_302_C0.7 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_fin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.8 -n Gm16_301_302_C0.8 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_fin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.9 -n Gm16_301_302_C0.9 -o ../analysis_output/

##no RS m09 indep
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.9 -c 0.5 -n Gm16_301_302_indep -o ../analysis_output/
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.9 -c 0.6 -n Gm16_301_302_indep -o ../analysis_output/
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.9 -c 0.7 -n Gm16_301_302_indep -o ../analysis_output/
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.9 -c 0.8 -n Gm16_301_302_indep -o ../analysis_output/
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.9 -c 0.9 -n Gm16_301_302_indep -o ../analysis_output/
##no RS m08 indep 
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.5 -n Gm16_301_302_indep -o ../analysis_output/
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.6 -n Gm16_301_302_indep -o ../analysis_output/
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.7 -n Gm16_301_302_indep -o ../analysis_output/
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.8 -n Gm16_301_302_indep -o ../analysis_output/
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.9 -n Gm16_301_302_indep -o ../analysis_output/

########## AROUND PDH1

Gm16_25kbflank

generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.7 -c 0.5 -n GmPDH1 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.7 -c 0.6 -n GmPDH1 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.7 -c 0.7 -n GmPDH1 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.7 -c 0.8 -n GmPDH1 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.7 -c 0.9 -n GmPDH1 -o ../analysis_output/

generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.8 -c 0.5 -n GmPDH1 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.8 -c 0.6 -n GmPDH1 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.8 -c 0.7 -n GmPDH1 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.8 -c 0.8 -n GmPDH1 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.8 -c 0.9 -n GmPDH1 -o ../analysis_output/

generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.8 -c 0.5 -n GmPDH1_indep -o ../analysis_output/
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.8 -c 0.6 -n GmPDH1_indep -o ../analysis_output/
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.8 -c 0.7 -n GmPDH1_indep -o ../analysis_output/
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.8 -c 0.8 -n GmPDH1_indep -o ../analysis_output/
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.8 -c 0.9 -n GmPDH1_indep -o ../analysis_output/

generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.9 -c 0.5 -n GmPDH1 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.9 -c 0.6 -n GmPDH1 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.9 -c 0.7 -n GmPDH1 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.9 -c 0.8 -n GmPDH1 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 75000 -m 0.9 -c 0.9 -n GmPDH1 -o ../analysis_output/

Rscript HMGmPDH1_MIT0.8_CT0.7.r
Rscript HMGmPDH1_MIT0.8_CT0.6.r
Rscript HMGmPDH1_MIT0.8_CT0.5.r
Rscript HMGmPDH1_MIT0.7_CT0.9.r
Rscript HMGmPDH1_MIT0.7_CT0.8.r
Rscript HMGmPDH1_MIT0.7_CT0.7.r
Rscript HMGmPDH1_MIT0.7_CT0.6.r
Rscript HMGmPDH1_MIT0.7_CT0.5.r
Rscript HMGmPDH1_indep_MIT0.8_CT0.8.r
Rscript HMGmPDH1_indep_MIT0.8_CT0.7.r
Rscript HMGmPDH1_indep_MIT0.8_CT0.6.r
Rscript HMGmPDH1_indep_MIT0.8_CT0.5.r
Rscript HMGmPDH1_MIT0.8_CT0.9.r
Rscript HMGmPDH1_MIT0.8_CT0.8.r
Rscript HMGmPDH1_indep_MIT0.8_CT0.9.r
Rscript HMGmPDH1_MIT0.9_CT0.8.r
Rscript HMGmPDH1_MIT0.9_CT0.7.r
Rscript HMGmPDH1_MIT0.9_CT0.6.r
Rscript HMGmPDH1_MIT0.9_CT0.5.r
Rscript HMGmPDH1_MIT0.9_CT0.9.r

cd tagphenobox
get_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_MIT0.8_CT0.7/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_MIT0.8_CT0.7
get_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_MIT0.8_CT0.6/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_MIT0.8_CT0.6
get_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_MIT0.8_CT0.5/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_MIT0.8_CT0.5
get_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_MIT0.7_CT0.9/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_MIT0.7_CT0.9
get_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_MIT0.7_CT0.8/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_MIT0.7_CT0.8
get_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_MIT0.7_CT0.7/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_MIT0.7_CT0.7
get_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_MIT0.7_CT0.6/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_MIT0.7_CT0.6
get_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_MIT0.7_CT0.5/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_MIT0.7_CT0.5
get_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_indep_MIT0.8_CT0.8/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_indep_MIT0.8_CT0.8
get_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_indep_MIT0.8_CT0.7/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_indep_MIT0.8_CT0.7
get_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_indep_MIT0.8_CT0.6/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_indep_MIT0.8_CT0.6
get_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_indep_MIT0.8_CT0.5/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_indep_MIT0.8_CT0.5
get_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_MIT0.8_CT0.9/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_MIT0.8_CT0.9
get_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_MIT0.8_CT0.8/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_MIT0.8_CT0.8
wget_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_MIT0.9_CT0.8/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_MIT0.9_CT0.8
get_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_MIT0.9_CT0.7/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_MIT0.9_CT0.7
get_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_MIT0.9_CT0.6/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_MIT0.9_CT0.6
get_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_MIT0.9_CT0.5/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_MIT0.9_CT0.5
get_24file.sh ../glyma/haploupe/analysis_output/HMGmPDH1_MIT0.9_CT0.9/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmPDH1_MIT0.9_CT0.9


#########GmSCL15

generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.7 -c 0.5 -n GmSCL15 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.7 -c 0.6 -n GmSCL15 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.7 -c 0.7 -n GmSCL15 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.7 -c 0.8 -n GmSCL15 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.7 -c 0.9 -n GmSCL15 -o ../analysis_output/

generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.5 -n GmSCL15 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.6 -n GmSCL15 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.7 -n GmSCL15 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.8 -n GmSCL15 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.9 -n GmSCL15 -o ../analysis_output/

generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.5 -n GmSCL15_indep -o ../analysis_output/
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.6 -n GmSCL15_indep -o ../analysis_output/
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.7 -n GmSCL15_indep -o ../analysis_output/
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.8 -n GmSCL15_indep -o ../analysis_output/
generic_runHM.sh -i ../input/indep1000_5_0.8_nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.8 -c 0.9 -n GmSCL15_indep -o ../analysis_output/

generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.9 -c 0.5 -n GmSCL15 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.9 -c 0.6 -n GmSCL15 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.9 -c 0.7 -n GmSCL15 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.9 -c 0.8 -n GmSCL15 -o ../analysis_output/
generic_runHM.sh -i ../input/nohet_prefin_impu_bial_16_SNP_id_filt_all.hmp.txt -gdb ../input/my_gene_db.txt -cdb ../input/chr16_size.txt -r 50000 -m 0.9 -c 0.9 -n GmSCL15 -o ../analysis_output/

Rscript HMGmSCL15_MIT0.8_CT0.7.r
Rscript HMGmSCL15_MIT0.8_CT0.6.r
Rscript HMGmSCL15_MIT0.8_CT0.5.r
Rscript HMGmSCL15_MIT0.7_CT0.9.r
Rscript HMGmSCL15_MIT0.7_CT0.8.r
Rscript HMGmSCL15_MIT0.7_CT0.7.r
Rscript HMGmSCL15_MIT0.7_CT0.6.r
Rscript HMGmSCL15_MIT0.7_CT0.5.r
Rscript HMGmSCL15_indep_MIT0.8_CT0.9.r
Rscript HMGmSCL15_indep_MIT0.8_CT0.8.r
Rscript HMGmSCL15_indep_MIT0.8_CT0.7.r
Rscript HMGmSCL15_indep_MIT0.8_CT0.6.r
Rscript HMGmSCL15_indep_MIT0.8_CT0.5.r
Rscript HMGmSCL15_MIT0.8_CT0.9.r
Rscript HMGmSCL15_MIT0.8_CT0.8.r
Rscript HMGmSCL15_MIT0.9_CT0.8.r
Rscript HMGmSCL15_MIT0.9_CT0.7.r
Rscript HMGmSCL15_MIT0.9_CT0.6.r
Rscript HMGmSCL15_MIT0.9_CT0.5.r
Rscript HMGmSCL15_MIT0.9_CT0.9.r

cd tagphenobox
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_MIT0.8_CT0.7/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_MIT0.8_CT0.7
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_MIT0.8_CT0.6/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_MIT0.8_CT0.6
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_MIT0.8_CT0.5/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_MIT0.8_CT0.5
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_MIT0.7_CT0.9/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_MIT0.7_CT0.9
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_MIT0.7_CT0.8/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_MIT0.7_CT0.8
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_MIT0.7_CT0.7/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_MIT0.7_CT0.7
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_MIT0.7_CT0.6/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_MIT0.7_CT0.6
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_MIT0.7_CT0.5/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_MIT0.7_CT0.5
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_indep_MIT0.8_CT0.9/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_indep_MIT0.8_CT0.9
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_indep_MIT0.8_CT0.8/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_indep_MIT0.8_CT0.8
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_indep_MIT0.8_CT0.7/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_indep_MIT0.8_CT0.7
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_indep_MIT0.8_CT0.6/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_indep_MIT0.8_CT0.6
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_indep_MIT0.8_CT0.5/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_indep_MIT0.8_CT0.5
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_MIT0.8_CT0.9/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_MIT0.8_CT0.9
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_MIT0.8_CT0.8/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_MIT0.8_CT0.8
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_MIT0.9_CT0.8/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_MIT0.9_CT0.8
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_MIT0.9_CT0.7/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_MIT0.9_CT0.7
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_MIT0.9_CT0.6/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_MIT0.9_CT0.6
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_MIT0.9_CT0.5/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_MIT0.9_CT0.5
get_24file.sh ../glyma/haploupe/analysis_output/HMGmSCL15_MIT0.9_CT0.9/Haplotypes.hmp.txt ../glyma/snp_calling/16_SNP_id_filt_bial_all.vcf HMGmSCL15_MIT0.9_CT0.9
