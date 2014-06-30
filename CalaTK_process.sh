#!/bin/bash -f
# calaTK process

source CalaTK_const.sh

#### FUNCTIONS
f_test_exit()
{
	rc=$?
	if [[ $rc != 0 ]] ; then
	    echo $1 > $dir/errors.txt
	    exit $rc
	fi
}
f_changeAlpha() #Update Alpha in CONFIG.JSON 
{
	alpha=$1
	oldLine=`cat $dir/config.json | grep "Alpha"`
	newLine='		"Alpha" : '$alpha','
	sed -i 's/'"$oldLine"'/'"$newLine"'/'  $dir/config.json
	f_test_exit "Alpha update failed"
	echo -e "${orange}[Alpha = $alpha] - updated in config file${NC}"
}
f_changeGamma() #Update Gamma in CONFIG.JSON 
{
	gamma=$1
	oldLine=`cat $dir/config.json | grep "Gamma"`
	newLine='		"Gamma" : '$gamma
	sed -i 's/'"$oldLine"'/'"$newLine"'/' $dir/config.json
	f_test_exit "Gamma update failed"
	echo -e "${orange}[Gamma = $gamma] - updated in config file${NC}"
}
f_LDDMM() #INPUT : source, target. OUTPUT : transformation field
{
	transform=$1
	echo -e "${purple}[LDDMM] - processing${NC}"
	LDDMM $source_f $target_f $transform --config $dir/config.json --configOut $dir/config.json --cleanConfigOutput --cleanedConfigurationType expert
	f_test_exit "LDDMM failed"
	echo -e "${purple}[LDDMM] - completed${NC}"
}
f_applyMap()  #INPUT : source, transformation field. OUTPUT : transformed
{
	echo -e "${purple}[applyMap] - processing${NC}"
	applyMap $dir/transform.nhdr $source_f $dir/out.nrrd
	f_test_exit "applyMap failed"
	echo -e "${purple}[applyMap] - completed${NC}"
}
f_substract() #INPUT : transformed, target. OUTPUT : difference
{
	echo -e "${purple}[substract] - processing${NC}"
	ImageMath $dir/out.nrrd -sub $target_f -outfile $dir/sub.nrrd -type float
	f_test_exit "ImageMath -sub failed"
	echo -e "${purple}[substract] - completed${NC}"
}
f_absValue()  #INPUT : difference. OUTPUT : absolute difference
{
	echo -e "${purple}[absoluteValue] - processing${NC}"
	unu 1op abs -i $dir/sub.nrrd | unu save -e gzip -f nrrd -o $dir/subabs.nrrd
	f_test_exit "unu 1op abs failed"
	echo -e "${purple}[absoluteValue] - completed${NC}"

}
f_createHisto() #INPUT : absolute difference. OUTPUT : histogramme values
{
	echo -e "${purple}[histogram] - processing${NC}"
	value=$(ImageStat $dir/subabs.nrrd -outbase $dir/subabs -histo)
	f_test_exit "ImageStat -histo failed"
	echo -e "${purple}[histogram] - completed${NC}"
	echo -e "${green}[Value = $value] - saved for $dir ${NC}"
}


#### PROCESSING

#init
i=$2
gamma=$1
alpha=$alpha_init

#process
for (( j=1; j<=$max_j; j++ ))
do
	#update testnumber
	testnumber=$(echo "$max_j*($i-1)+$j" | bc)
	echo -e "${blue}[TEST "$testnumber"/"$testnumbermax"] Gamma = "$gamma", Alpha = "$alpha${NC}

	#update directory name
	dir=$(echo g"$gamma"_a"$alpha") #or $(echo "$i"_"$j") to avoid "." in name
	mkdir $dir
	cp $config_f $dir/config.json
	f_test_exit "Copy of config.json failed"

	#update alpha and gamma in config
	f_changeGamma $gamma
	f_changeAlpha $alpha

	#PROCESS : intensity difference
	f_LDDMM $dir/transform.nhdr
	f_applyMap
	f_substract
	f_absValue
	f_createHisto

	#INC alpha
	alpha=$(echo "$alpha+$alpha_step" | bc)
	alpha=$(printf '%.5f\n' $alpha)
done

