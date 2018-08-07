#!/bin/sh


#geth --dev --ipcpath geth.ipc --datadir /develop/app/ethereum attach

#geth --dev --ipcpath geth.ipc --datadir /develop/app/ethereum --targetgaslimit '9000000000000' --gasprice 8000000000 --networkid 1235 --rpc --rpcapi personal,db,eth,net,web3  --rpcaddr 0.0.0.0 --rpcport 8545 --rpccorsdomain "*" --ws --wsapi personal,db,eth,net,web3  --wsaddr 0.0.0.0 --wsport 8546 --wsorigins "*" console

#geth --dev --ipcpath geth.ipc --datadir /develop/app/ethereum --gasprice 18000000000000 --networkid 1235
#geth --dev --ipcpath geth.ipc --datadir /develop/app/ethereum --gasprice 18000000000000 --networkid 1235 attach

#./mist --rpc /develop/app/ethereum/geth.ipc --networkid 1235
#./ethereumwallet --rpc /develop/app/ethereum/geth.ipc --networkid 1235

# /develop/app/ethereumwallet/ethereumwallet --rpc /develop/app/ethereum/geth.ipc 

# npm --proxy http://localhost:8118 install -g @types/express express body-parser cookie-parser multer @types/sequelize sequelize @types/pg pg



# NODE_PATH=. node ./sale/hello.js 


mkdir -p build
#echo "exports.sale_var=`solc --gas --optimize --combined-json abi,bin,interface */*.sol`" > build/sale.ts
echo "export=`solc --allow-paths .,. --optimize --combined-json abi,bin,interface contracts/*.sol`;" > build/sale.ts



# new Date('2011-04-11T10:20:30Z')



