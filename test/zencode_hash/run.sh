#!/usr/bin/env bash

# RNGSEED="hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"


####################
# common script init
. ../utils.sh
####################

set -e

 # | save hash hex.json
cat <<EOF | zexe hash_string.zen | save hash hex.json
rule output encoding hex
Given nothing
When I write string 'a string to be hashed' in 'source'
and I create the hash of 'source'
Then print the 'hash'
EOF


cat <<EOF | zexe hash_compare.zen -a hex.json | save hash hexeq.json
Given I have a 'hex' named 'hash'
When I set 'myhash' to 'c24463f5e352da20cb79a43f97436cce57344911e1d0ec0008cbedb5fabcca33' as 'hex'
and I verify 'myhash' is equal to 'hash'
Then print the 'hash'
EOF

cat <<EOF | zexe hash_string256.zen | save hash hex256.json
rule output encoding hex
Given nothing
When I write string 'a string to be hashed' in 'source'
and I create the hash of 'source' using 'sha256'
Then print the 'hash'
EOF


cat <<EOF | zexe hash_string512.zen | save hash hex512.json
rule output encoding hex
Given nothing
When I write string 'a string to be hashed' in 'source'
and I create the hash of 'source' using 'sha512'
Then print the 'hash'
EOF


cat << EOF | zexe hash_default.zen | save hash hexdefault.json
rule output encoding hex
Given nothing
When I create the random 'source'
and I create the hash of 'source'
Then print 'hash'
EOF

cat << EOF | zexe kdf_default.zen | save hash kdfdefault.json
rule output encoding hex
Given nothing
When I create the random 'source'
and I create the key derivation of 'source'
Then print 'key derivation'
EOF

cat << EOF | zexe pbkdf_default.zen | save hash pbkdfdefault.json
rule output encoding hex
Given nothing
When I create the random 'source'
and I write string 'my pbkdf password' in 'secret' 
and I create the key derivation of 'source' with password 'secret'
Then print 'key derivation'
EOF

cat << EOF | zexe hmac_default.zen | save hash hmacdefault.json
rule output encoding hex
Given nothing
When I create the random 'source'
and I write string 'my HMAC key' in 'secret'
and I create the HMAC of 'source' with key 'secret'
Then print 'HMAC'
EOF

cat << EOF | zexe hash_sha512.zen
rule output encoding hex
rule set hash sha512
Given nothing
When I create the random 'source'
and I create the hash of 'source'
Then print 'hash'
EOF

cat <<EOF | zexe random_numbers.zen | tee array_random_nums.json
# test hashing serialized tables
Given nothing
When I create the array of '64' random numbers
and I create the hash of 'array'
and I rename the 'hash' to 'sha256'
and I create the hash of 'array' using 'sha512'
and I rename the 'hash' to 'sha512'
and I set 'secret' to 'my password' as 'string'
and I create the key derivation of 'array' with password 'secret'
and I create the HMAC of 'array' with key 'secret'
Then print 'sha256'
Then print 'sha512'
Then print 'key derivation'
Then print 'HMAC'
EOF

success
