#!/bin/bash -f
# calaTK const

#### CONST
red='\e[0;31m'
green='\e[1;32m'
orange='\e[0;33m'
blue='\e[1;34m'
purple='\e[1;35m'
NC='\e[0m' # No Color

#### SOURCES
source_f="src/cube.nhdr"
target_f="src/sphere.nhdr"
config_f="src/config.json"

#### INIT
#Alpha
alpha_init=0.0025
alpha_max=0.1
alpha_nbr_values=5
alpha_step=$(echo "($alpha_max-$alpha_init)/($alpha_nbr_values-1)" | bc -l)

#Gamma
gamma_init=1.0
gamma_max=5.5
gamma_nbr_values=3
gamma_step=$(echo "($gamma_max-$gamma_init)/($gamma_nbr_values-1)" | bc -l)

#Loop
max_i=$gamma_nbr_values
max_j=$alpha_nbr_values
testnumbermax=$(echo "$max_i*$max_j" | bc)
testnumber=0
