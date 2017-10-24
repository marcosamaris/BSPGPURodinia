#!/bin/bash

DEVICE=GPU
#declare -a apps=( backprop gaussian heartwall hotspot hotspot3D needle lud )
    declare -a apps=( backprop )
mkdir  -p ./data/

MAIN_DIR=~/rodiniaSched/rodinia_3.1

for iteration in `seq 1 1 10`; do
for app in "${apps[@]}"; do 
    rm -rf ${MAIN_DIR}/data/${app}-${DEVICE} 
     
    ### Back-propagation benchmark executions    
    if [[ "${app}" == "backprop" ]]; then
            cd ${MAIN_DIR}/cuda/${app}
        make clean; make DEVICE=$DEVICE
        for i in `seq 8192 1024 65536`; do
 	    ./${app} ${i} >> ${app}-${DEVICE}
        done
        mv ${app}-${DEVICE} ../../../data/${app}-${DEVICE}-${iteration}.csv
        rm -f ${app}-${DEVICE}; cd .. 
    fi

    ### Gaussian benchmark executions    
    if [[ "${app}" == "gaussian" ]]; then
        if [[ "${DEVICE}" == "CPU" ]]; then
            cd ${MAIN_DIR}/opencl/${app}
        else
            cd ${MAIN_DIR}/cuda/${app}
        fi
        make clean; make; rm -rf ${app}-${DEVICE} 
        for i in `seq 256 256 8192`; do
            if [[ "${DEVICE}" == "CPU" ]]; then
	        ./${app} ${i}  >> ${app}-${DEVICE}
            else
	        ./${app} -s ${i} -q  >> ${app}-${DEVICE}
        fi
        done
        mv ${app}-${DEVICE} ../../../data/${app}-${DEVICE}.csv
        rm -f ${app}-${DEVICE}; cd ..
    fi

    if [[ "${app}" == "heartwall" ]]; then
        if [[ "${DEVICE}" == "CPU" ]]; then
            cd ${MAIN_DIR}/openmp/${app}
            nThreads=1
        else
            cd ${MAIN_DIR}/cuda/${app}
        fi
        make clean; make
        for i in `seq 20 104`; do
            ./${app} ../../data/heartwall/test.avi $i $nThreads >> ${app}-${DEVICE} 
        done
        mv ${app}-${DEVICE} ../../../data/${app}-${DEVICE}.csv
        rm -f ${app}-${DEVICE}; cd ..

    fi


    if [[ "${app}" == "hotspot" ]]; then
        if [[ "${DEVICE}" == "CPU" ]]; then
            cd ${MAIN_DIR}/openmp/${app}
        else
            cd ${MAIN_DIR}/cuda/${app}
        fi
        make clean; make
        for i in  64 128 256 512 1024; do
             for j in `seq 6 256 1024 `; do
        if [[ "${DEVICE}" == "CPU" ]]; then
                 ./${app} ${i} ${i} ${j} 1 ../../data/hotspot/temp_${i} ../../data/hotspot/power_${i} output.out >> ${app}-${DEVICE} 
        else
                 ./${app} ${i} 2 ${j} ../../data/hotspot/temp_${i} ../../data/hotspot/power_${i} output.out >> ${app}-${DEVICE} 
        fi
                 
        done
    done
        mv ${app}-${DEVICE} ../../../data/${app}-${DEVICE}.csv
        rm -f ${app}-${DEVICE}; cd ..
    fi

    if [[ "${app}" == "hotspot3D" ]]; then
        if [[ "${DEVICE}" == "CPU" ]]; then
            cd ${MAIN_DIR}/openmp/${app}
        else
            cd ${MAIN_DIR}/cuda/${app}
        fi
        make clean; make
       for i in 2 4 8; do
           for j in `seq 100 100 1000 `; do
                 ./${app} 512 ${i} ${j} ../../data/hotspot3D/power_512x${i} ../../data/hotspot3D/temp_512x${i} output.out >> ${app}-${DEVICE} 
        done
    done
        mv ${app}-${DEVICE} ../../../data/${app}-${DEVICE}.csv
        rm -f ${app}-${DEVICE}; cd ..
    fi

    if [[ "${app}" == "lud" ]]; then
        for i in `seq 256 256 8192`; do
            ${app} -s ${i} -v > tempTime
        done
    fi

    if [[ "${app}" == "needle" ]]; then
        if [[ "${DEVICE}" == "CPU" ]]; then
            cd ${MAIN_DIR}/openmp/${app}
            nThreads=1
        else
            cd ${MAIN_DIR}/cuda/${app}
        fi
        make clean; make
       for i in `seq 256 256 4096`; do
           for j in `seq 1 10 `; do
                 ./${app} ${i} ${j} ${nThreads} >> ${app}-${DEVICE} 
        done
    done
        mv ${app}-${DEVICE} ../../../data/${app}-${DEVICE}.csv
        rm -f ${app}-${DEVICE}; cd ..
    fi


    done   
done

cd ../../


