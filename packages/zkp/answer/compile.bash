set -e

zokrates compile -i root.zok --debug
zokrates setup
# zokrates compute-witness -a 73 74 6f 63 6b 99
zokrates compute-witness -a 115 116 111 99 107 147072043 1599624744 3146575758 3728796041 1535580651 2154868450 3647345496 1055101002 0 0 0 1530452586 1880905349 1172110512 1070303071 1455349188 0 0 0 1530452586 1880905349 1172110512 1070303071 1455349188
# zokrates compute-witness
zokrates generate-proof
# export a solidity verifier
zokrates export-verifier
# or verify natively
zokrates verify

zokrates print-proof