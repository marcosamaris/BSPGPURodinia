#!/bin/bash

DEVICE=GPU
declare -a apps=( backprop )
mkdir  -p ./data/

cd rodinia_3.1/cuda/

for app in "${apps[@]}"; do 
    rm -rf ../../data/${app}-${DEVICE} 
     
    cd ${app}
    make clean; make
    ### Back-propagation benchmark executions    
    if [[ "${app}" == "backprop" ]]; then
        for i in `seq 8192 1024 65536`; do
			./${app} ${i} >> ${app}-${DEVICE}
        done
        mv ${app}-${DEVICE} ../../../data/${app}-${DEVICE}
    fi
    
    rm -f ${app}-${DEVICE}; cd ..



done   

cd ../../




