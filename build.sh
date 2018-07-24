#!/bin/sh


#geth --dev --ipcpath geth.ipc --datadir /develop/app/ethereum --targetgaslimit '9000000000000' --gasprice 8000000000 --networkid 1235 --rpc --rpcapi personal,db,eth,net,web3  --rpcaddr 0.0.0.0 --rpcport 8545 --rpccorsdomain "*" console
#geth --dev --ipcpath geth.ipc --datadir /develop/app/ethereum --gasprice 18000000000000 --networkid 1235
#geth --dev --ipcpath geth.ipc --datadir /develop/app/ethereum --gasprice 18000000000000 --networkid 1235 attach

#./mist --rpc /develop/app/ethereum/geth.ipc --networkid 1235
#./ethereumwallet --rpc /develop/app/ethereum/geth.ipc --networkid 1235





# NODE_PATH=. node ./sale/hello.js 


mkdir build
#echo "exports.sale_var=`solc --gas --optimize --combined-json abi,bin,interface */*.sol`" > build/sale.ts
echo "export=`solc --allow-paths .,. --optimize --combined-json abi,bin,interface contracts/*.sol`;" > build/sale.ts



# new Date('2011-04-11T10:20:30Z')



