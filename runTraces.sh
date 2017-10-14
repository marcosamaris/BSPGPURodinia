#!/bin/bash

DEVICE=CPU
declare -a apps=( gaussian )
mkdir  -p ./data/

cd rodinia_3.1/cuda/

for app in "${apps[@]}"; do 
    rm -rf ../../data/${app}-${DEVICE} 
     
    ### Back-propagation benchmark executions    
    if [[ "${app}" == "backprop" ]]; then
        cd ${app}
        make clean; make
        for i in `seq 8192 1024 65536`; do
			./${app} ${i} >> ${app}-${DEVICE}
        done
        mv ${app}-${DEVICE} ../../../data/${app}-${DEVICE}
        rm -f ${app}-${DEVICE}; cd .. 
    fi


    ### Gaussian benchmark executions    
    if [[ "${app}" == "gaussian" ]]; then
            cd ../opencl/${app}
        make clean; make
        for i in `seq 256 256 8192`; do
			./${app} ${i}  >> ${app}-${DEVICE}
        done
        mv ${app}-${DEVICE} ../../../data/${app}-${DEVICE}
        rm -f ${app}-${DEVICE}; cd ..
    fi
done   

cd ../../




