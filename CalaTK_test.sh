#!/bin/bash -f
# calaTK test

source CalaTK_const.sh
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
clear

#init
gamma=$gamma_init

#process
for (( i=1; i<=$max_i; i++ ))
do
	########
	bsub -q day -M 1 -n 1 ./CalaTK_process2.sh $gamma $i
	./CalaTK_process.sh $gamma $i
	########

	#INC gamma
	gamma=$(echo "$gamma+$gamma_step" | bc)
	gamma=$(printf '%.5f\n' $gamma)

done

