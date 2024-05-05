params.memory = "3g"
params.cpus = 1
params.outdir = "."
params.jobs = 1


process runJuicer {
        publishDir "${params.outdir}/04_juicerResults", mode: 'copy'
        cpus params.cpus
        maxForks params.jobs
input:
        tuple val(sid), path(reads)
        each path(enzyme)
        each path(chromsize)

output:
path(sid)


shell:
'''
DIR=$(dirname !{reads[0].toRealPath()})
ln -s $DIR fastq
!{projectDir}/tools/juicer-1.6/scripts/juicer.sh -g !{params.prefix} -d $PWD -s !{params.enzyme} -p !{chromsize} -y !{enzyme}  -z !{params.ref} \
-t 5 -D !{projectDir}/tools/juicer-1.6
mv aligned !{sid}
unlink fastq
'''
}
