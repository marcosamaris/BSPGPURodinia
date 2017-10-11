#!/bin/bash

declare -a apps=( backprop )
mkdir  -p ./data/

cd rodinia_3.1/cuda/

for app in "${apps[@]}"; do 
    rm -rf ../../data/${app}* 
     
    cd ${app}
    make clean; make
    ### Back-propagation benchmark executions    
    if [[ "${app}" == "backprop" ]]; then
        for i in `seq 8192 1024 65536`; do
			./${app} ${i} >> ${app}-$device
        done
        mv ${app}-$device ../../../data/${app}-$device
    fi
    
    rm -f ${app}-$device}; cd ..



done   

cd ../../




