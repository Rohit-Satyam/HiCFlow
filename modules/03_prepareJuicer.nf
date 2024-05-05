params.memory = "3g"
params.cpus = 1
params.outdir = "."
params.jobs = 1

process JuicerPrepare{
    cpus params.cpus
    memory params.memory
    publishDir "${params.outdir}/03_JuicerPrepare", mode: "copy"

    output:
    path("*.txt")
    path("*.chrom.sizes")

    shell:
'''
# Create restriction sites file for DpnII enzyme
python !{projectDir}/tools/juicer/misc/generate_site_positions.py !{params.enzyme} !{params.prefix} !{params.ref}

# Get chromosome sizes for your genome
awk 'BEGIN{OFS="\t"}{print $1, $NF}' !{params.prefix}_!{params.enzyme}.txt > !{params.prefix}.chrom.sizes

'''
}
