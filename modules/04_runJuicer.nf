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

## make cool files
ls -1 !{sid}/*.hic | while read p; 
	do 
		n=$(echo $p | xargs -n 1 basename | cut -f 1 -d '.'); 
		hic2cool convert $p !{sid}/${n}.cool -p !{task.cpus}; 
	done

## Making chromosome lists
grep '>' !{params.ref} | awk -F'|' '{print $1}' | sed 's/>//g' | sed 's/ //g' > chrlist

## Compartment calling
!{projectDir}/bin/compartment.sh chrlist !{sid} !{projectDir} !{params.compartments}
unlink fastq
'''
}
