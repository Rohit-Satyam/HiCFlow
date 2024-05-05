#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

if( params.help ) {

log.info """
 * -------------------------------------------------
 *  HiCFlow@KAUST: Analyzing Hi-C Dataset
 * -------------------------------------------------
Usage:
	nextflow run main.nf --input "${params.input}" --outdir ${params.outdir} --ref ${params.ref} \
	 --mode ${params.mode} --enzyme ${params.enzyme}  --prefix ${params.prefix} --insertSize ${params.insertSize}\
	--index_dir ${params.index_dir}
Input:
	#### Mandatory Arguments ####
	* --enzyme: Name of restriction digestion enzyme used. Default [${params.enzyme}]
	* --index_dir: Provide path to director where BWA indexes are stored. Default [${params.index_dir}]
	* --input: Path to FastqQ files. Default [${params.input}]
	* --mode: If data is Paired-end pass "PE" else "SE". Default [${params.mode}]
	* --outdir: Path/Name of the output directory. Default [${params.outdir}]
	* --ref: Path to reference fasta file. Default [${params.ref}]
	* --prefix: Prefix used by the indexed files. Default [${params.prefix}]
 	* --insertSize: Insert size. Default [${params.insertSize}]
	* --compartments: Size of the compartments. Default [${params.compartments}]

	#### Parameters to pass additional Arguments ####
	* --fastp_ext: Additional arguments to pass to FASTP. Default [${params.fastp_ext}]
	* --fastqc_ext: Additional arguments to pass to FASTQC. Default [${params.fastqc_ext}]

	#### Parameters to Skip certain Steps ####
	* --skipTrim: Set this "true" to skip Trimming Step. Default [${params.skipTrim}]
	* --skipAlignment: Set this "true" to skip Alignment Step. Default [${params.skipAlignment}]

"""

exit 0
}

include {FASTQC; QC3C} from './modules/01_fastqc'
include {FASTP; POSTTRIMFASTQC} from './modules/02_fastp'
include {JuicerPrepare} from './modules/03_prepareJuicer'
include {runJuicer} from './modules/04_runJuicer'
include {MULTIQC as PRETRIM; MULTIQC as POSTTRIM; MULTIQC as SUMMARISEALL} from './modules/01_fastqc'

params.help= false
params.input = false
params.outdir= false


workflow{

if (params.input != false){
	if (params.mode == "PE"){
		Channel.fromFilePairs(params.input, checkIfExists: true )
		.set { input_fastqs }
		} else if (params.mode == "SE") {
			Channel.fromPath(params.input, checkIfExists: true ).map { file -> tuple(file.simpleName, file)}
			.set { input_fastqs }
	}
}


//making the reference index folder a channel
if (params.index_dir == ""){
	echo "Provide genome index directory"
	} else if (params.index_dir != ""){
		index = Channel.fromPath(params.index_dir)
	}

// Step 1: Running FASTQC and qc3c
rawfqc_ch=FASTQC(input_fastqs)
pretrim_input=FASTQC.out.fastqc.collect()
PRETRIM("01_rawFastQC",pretrim_input,'pre-trimming')



// Step2: Running Adapter Trimming
if (params.skipTrim == false){
        FASTP(input_fastqs)
	      FASTP.out[0]
        raw_qc3c=QC3C(FASTP.out[0]).collect()
        POSTTRIMFASTQC(FASTP.out[0])
        postrim_input=POSTTRIMFASTQC.out.postfastqc.collect()
        POSTTRIM("02_adapterTrimming",postrim_input,'post-trimming')

} else {
  raw_qc3c=QC3C(input_fastqs)
}

// Step3 Running preparation for Juicer
JuicerPrepare()

//Step 4 Running Juicer

if (params.skipAlignment == false && params.skipTrim == true){
    runJuicer(input_fastqs,JuicerPrepare.out[0],JuicerPrepare.out[1])
    } else if (params.skipAlignment == false && params.skipTrim == false){
      runJuicer(FASTP.out[0],JuicerPrepare.out[0],JuicerPrepare.out[1])
      } else {
    echo "Alignment has been skipped"
  }

/*
//summarize all reports as multiqc data
if (params.skipTrim == true && params.skipAlignment == true ){
	all_combine=SORTMERNA.out[1]
	SUMMARISEALL("Summary_Reports",all_combine.collect(),'summary_report')
	} else if (params.skipTrim == true && params.skipAlignment == false ){
	all_combine=BAMSTATS.out[0].mix(MARKDUP.out.dedupmtx,STAR.out.star_logs,RNASEQC.out[0])
	SUMMARISEALL("Summary_Reports",all_combine.collect(),'summary_report')
	} else if (params.skipTrim == false && params.skipAlignment == true ){
	all_combine=FASTP.out.fastp_logs
	SUMMARISEALL("Summary_Reports",all_combine.collect(),'summary_report')
	} else {
	all_combine=BAMSTATS.out[0].mix(MARKDUP.out.dedupmtx,STAR.out.star_logs,RNASEQC.out[0],FASTP.out.fastp_logs)
	SUMMARISEALL("Summary_Reports",all_combine.collect(),'summary_report')
	}
*/

}
