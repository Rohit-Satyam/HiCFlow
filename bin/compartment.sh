while read q
do
	chr=$q
	ls -1 $2/*.hic | while read p; 
do  
	n=$(echo $p | xargs -n 1 basename | cut -f 1 -d '.'); 
	$3/tools/juicer-1.6/scripts/common/juicer_tools eigenvector KR $p \
				${chr} BP $4 $2/${chr}_eigen.txt -p
	done
done < $1
