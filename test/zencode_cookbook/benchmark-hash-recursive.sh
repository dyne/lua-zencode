#!/usr/bin/env bash
LUA=luajit
. ../utils.sh

time=50

users=""
for i in $(seq $time)
do
  users+=" time_${i}"
done

data="data"
zencode="zencode"

cat <<EOF  > $data
{
	"JackInTheShop": {
		"keypair": {
			"private_key": "Aku7vkJ7K01gQehKELav3qaQfTeTMZKgK+5VhaR3Ui0=",
			"public_key": "BBCQg21VcjsmfTmNsg+I+8m1Cm0neaYONTqRnXUjsJLPa8075IYH+a9w2wRO7rFM1cKmv19Igd7ntDZcUvLq3xI="
		}
	},
	"TransactionsBatchA": {
		"Information": {
			"Metadata": "TransactionsBatchB6789",
			"Buyer": "John Doe"
		},
		"ABC-Transactions1Data": {
			"timestamp": 1597573139,
			"TransactionValue": 1500,
			"PricePerKG": 100,
			"TransferredProductAmount": 15,
			"UndeliveredProductAmount": 7,
			"ProductPurchasePrice": 50
		},
		"ABC-Transactions2Data": {
			"timestamp": 1597573239,
			"TransactionValue": 1600,
			"TransferredProductAmount": 20,
			"PricePerKG": 80
		},
		"ABC-Transactions3Data": {
			"timestamp": 1597573340,
			"TransactionValue": 700,
			"PricePerKG": 70,
			"TransferredProductAmount": 10
		}
	},
	"dictionaryToBeFound": "Information",
	"salesStartTimestamp": 1597573200,
	"PricePerKG": 3
}
EOF

cat <<EOF  > $zencode
Rule check version 1.0.0
Scenario 'ecdh': keypair management and ECDSA signature

# Here we load everything we need

Given that I have a 'string dictionary' named 'TransactionsBatchA'

# Hash dictionaries, using default (sha256) or sha256

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA01' 

Then print all data 
EOF

hash() {

cat $zencode | zexe $zencode -a $data

}


loop(){
for user in ${users[@]}
do
hash ${user}
echo  " "
echo  "-----------------------------"
echo  " "
echo  " I have hashed"  ${time} "times"
echo  " "
echo  " it took a total of: "
done
}

time loop

echo  " "
echo  "-----------------------------"
echo  " "

rm ./data
rm ./zencode

