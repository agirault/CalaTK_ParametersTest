#!/bin/bash -f
# calaTK write

source CalaTK_const.sh

#### FUNCTIONS
f_test_exit()
{
	rc=$?
	if [[ $rc != 0 ]] ; then
	    exit $rc
	fi
}
f_absValue()
{
	hide=`unu 1op abs -i $dir/sub.nrrd | unu save -e gzip -f nrrd -o $dir/subabs.nrrd`
	f_test_exit
}
f_createHisto()
{
	hide=`ImageStat $dir/subabs.nrrd -outbase $dir/subabs -histo`
	f_test_exit
	echo -e "${green}[Value = $hide] - saved for $dir ${NC}"
}
f_reference()
{
	echo -e "${blue}[REFERENCE] - computing${NC}"

	dir=ref
	mkdir $dir

	ImageMath $source_f -sub $target_f -outfile $dir/sub.nrrd -type float
	f_test_exit

	f_absValue
	f_createHisto

	txt=`cat $dir/subabs_vol.txt | grep "Fullavg"`
	IFS=', ' read -a array <<< "$txt"
	REF=${array[2]%?}

	sed -i '/^REF =/ s/$/ '$REF'/' calaTK_arrays.m
}

f_readHisto()
{
	##read value
	txt=`cat $dir/subabs_vol.txt | grep "Fullavg"`
	IFS=', ' read -a array <<< "$txt"
	val=${array[2]%?}

	##relative to REF	
	#val=$(echo "$val*100.0/$REF" | bc -l)

	## MATLAB ARRAY 
	sed -i '/^Z_values =/ s/$/ '$val'/' calaTK_arrays.m
	#echo -e "${green}[Value = $val %] - added in Matlab Array${NC}"
}
f_createArrays()
{
	echo "close all;" > calaTK_arrays.m
	echo "clear all;" >> calaTK_arrays.m
	echo "X_alpha = [" >> calaTK_arrays.m
	echo "Y_gamma = [" >> calaTK_arrays.m
	echo "Z_values = [" >> calaTK_arrays.m
	echo "REF = " >> calaTK_arrays.m
	echo "Z_relative = Z_values*100/REF;" >> calaTK_arrays.m
	echo "%X_range = [1:20];" >> calaTK_arrays.m
	echo "%Y_range = [3:40];" >> calaTK_arrays.m
	echo "%X_alpha = X_alpha(:, X_range);" >> calaTK_arrays.m
	echo "%Y_gamma = Y_gamma(:, Y_range);" >> calaTK_arrays.m
	echo "%Z_relative = Z_relative(Y_range,X_range);" >> calaTK_arrays.m
	echo "surfc(X_alpha,Y_gamma,Z_relative)" >> calaTK_arrays.m
	echo "title('Difference between the registered image and the target relatively to the difference between the source and the target','FontSize',12)" >> calaTK_arrays.m
	echo "xlabel('Alpha')" >> calaTK_arrays.m
	echo "ylabel('Gamma')" >> calaTK_arrays.m
	echo "zlabel('Diff Registered-Target (%)')" >> calaTK_arrays.m
}
f_closeArrays()
{
	#Close Matlab Arrays
	sed -i '/^X_alpha =/ s/$/];/' calaTK_arrays.m
	sed -i '/^Y_gamma =/ s/$/];/' calaTK_arrays.m
	sed -i '/^Z_values =/ s/$/];/' calaTK_arrays.m
}
f_test_errors()
{
	alpha=$alpha_init
	gamma=$gamma_init
	nbr_errors=0

	echo "" > log_errors.txt
	for (( i=1; i<=$max_i; i++ ))
	do
		for (( j=1; j<=$max_j; j++ ))
		do
			#update directory name
			dir=$(echo g"$gamma"_a"$alpha") #or $(echo "$i"_"$j") to avoid "." in name

			#look for errors
			if [ -f $dir/errors.txt ];
			then
			    let "nbr_errors += 1"
			    error_string=$(cat $dir/errors.txt)
			    echo $dir" : "$error_string >> log_errors.txt
			fi

			if [ ! -f $dir/subabs_vol.txt ];
			then
			     let "nbr_errors += 1"
			     echo $dir" : subabs_vol.txt missing">> log_errors.txt
			fi
			 
			#INC alpha
			alpha=$(echo "$alpha+$alpha_step" | bc)
			alpha=$(printf '%.5f\n' $alpha)
		done

		#INC gamma
		gamma=$(echo "$gamma+$gamma_step" | bc)
		gamma=$(printf '%.5f\n' $gamma)

		#RESET alpha
		alpha=$alpha_init
	done

	if [ "$nbr_errors" = "0" ];
	then
		rm log_errors.txt
		alpha=$alpha_init
		gamma=$gamma_init
	else
		echo -e "${red}$nbr_errors error(s) copied in log_errors.txt ${NC}"
		exit 1
	fi
}


#### PROCESSING

#Test if we had any errors
f_test_errors
f_test_exit

#Create arrays in Matlab
f_createArrays

#Get reference without registration
REF=1.0
f_reference

## WRITING
for (( i=1; i<=$max_i; i++ ))
do
	# put it in matlab array
	sed -i '/^Y_gamma =/ s/$/ '$gamma'/' calaTK_arrays.m

	for (( j=1; j<=$max_j; j++ ))
	do

		# put it in matlab array (if i==1 only)
		if [ "$i" -eq "1" ]
		then
			sed -i '/^X_alpha =/ s/$/ '$alpha'/' calaTK_arrays.m
		fi

		#update directory name
		dir=$(echo g"$gamma"_a"$alpha") #or $(echo "$i"_"$j") to avoid "." in name
		
		#update testnumber
		testnumber=$(echo "$testnumber+1" | bc)
		echo -e "${blue}[TEST "$testnumber"/"$testnumbermax"] Gamma = "$gamma", Alpha = "$alpha${NC}

		#write values
		f_readHisto
		
		#INC alpha
		alpha=$(echo "$alpha+$alpha_step" | bc)
		alpha=$(printf '%.5f\n' $alpha)
	done

	#INC gamma
	gamma=$(echo "$gamma+$gamma_step" | bc)
	gamma=$(printf '%.5f\n' $gamma)

	#RESET alpha
	alpha=$alpha_init

	#Change line in Matlab array
	sed -i '/^Z_values =/ s/$/;/' calaTK_arrays.m

done

#Close arrays in Matlab
f_closeArrays

