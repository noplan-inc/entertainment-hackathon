## これは何？
- 回答ZKP
- 答えのhashが合っているかを答えを明かさずに回答
- フロントランニング対策で、msg.senderをinputにして、private inputでaddressを入れておいて、そのaddressがmsg.senderと一致しているかを検証する

## 動かし方
1. `bash compile.bash`
2. `verifier.sol` の一部を書き換える
```solidity
    function addressToUintArray(address addr) public pure returns (uint32[8] memory) {
        uint32[8] memory result;

        // Convert address to uint
        uint addrUint = uint(uint160(addr));

        // Split the uint into chunks of 32 bits
        for (uint i = 0; i < 8; i++) {
            result[7 - i] = uint32(addrUint & 0xFFFFFFFF);
            addrUint >>= 32;
        }

        return result;
    }
    function verifyTx(
            Proof memory proof, uint[8] memory expectedHash
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](17);
        
        // 
        for(uint i = 0; i < 8; i++){
            inputValues[i] = expectedHash[i];
        }

        // フロントランニング対策
        uint32[8] memory _addresses = addressToUintArray(msg.sender);
        for(uint i = 0; i < 8; i++){
            inputValues[i + 8] = _addresses[i];
        }

        // outputがtrueになることを検証
        inputValues[16] = 1;

        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
```
3. remixとかでデプロイする
4. zokrates print-proofで出てきたproofをコピーして、貼り付ける
5. デフォルトのテストアカウントの 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4であればそのままで良い
6. 違うアドレスの場合はaddressToUintArrayでアドレスをintに変換する



## zokratesのargsについて
```bash
$ zokrates compute-witness -a 115 116 111 99 107 147072043 1599624744 3146575758 3728796041 1535580651 2154868450 3647345496 1055101002 0 0 0 1530452586 1880905349 1172110512 1070303071 1455349188 0 0 0 1530452586 1880905349 1172110512 1070303071 1455349188b
```
witnessが計算できるってことは回路がうまく動いて正常に動作してるってことだと思う

`def main(private u8[5] word, u32[8] expectedHash,private  u32[8] addressUint, u32[8] pubAddressUint) -> bool`

この引数を渡すには上記のような数字で渡す

- word: 115 116 111 99 107
- expectedHash: 147072043 1599624744 3146575758 3728796041 1535580651 2154868450 3647345496 1055101002
- addressUint: 0 0 0 1530452586 1880905349 1172110512 1070303071 1455349188
- pubAddressUint: 0 0 0 1530452586 1880905349 1172110512 1070303071 1455349188b


### wordとexpectedHashの算出方法
```bash
node sha256.js stock
word: 115 116 111 99 107
expectedHash(dec chunked): 147072043 1599624744 3146575758 3728796041 1535580651 2154868450 3647345496 1055101002
```


### addressUintとpubAddressUintの算出方法
- deployしたコントラクトに生えてる `addressToUintArray` を使う
