#!/bin/sh


#geth --dev --ipcpath geth.ipc --datadir /develop/app/ethereum --gasprice 18000000000000 --networkid 1235
#geth --dev --ipcpath geth.ipc --datadir /develop/app/ethereum --gasprice 18000000000000 --networkid 1235 attach

#./mist --rpc /develop/app/ethereum/geth.ipc --networkid 1235
#./ethereumwallet --rpc /develop/app/ethereum/geth.ipc --networkid 1235







mkdir build
#echo "var sale_var=`solc --optimize --combined-json abi,bin,interface */*.sol`" > build/sale.js
echo "var sale_var=`solc --allow-paths .,. --optimize --combined-json abi,bin,interface contracts/*.sol`" > build/sale.js
#cat build/sale.js


# new Date('2011-04-11T10:20:30Z')



