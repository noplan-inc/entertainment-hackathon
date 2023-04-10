
import { json } from "@remix-run/cloudflare";
import { Form } from "@remix-run/react";
import { Word } from "~/models/Word";
import { ActionArgs } from "@remix-run/cloudflare";
import { providers, Contract, BigNumber }from "ethers";
import nonceAbi from "../../abi/nonce.json";



export async function action({ request, context: { auth } }: ActionArgs) {
    // DBにデータを入れる
    // await Word.create({
    //   text: "giant",
    // });

    const formData = new URLSearchParams(await request.text());
    const word = formData.get("word");
    // words tableに存在するか確認 ZKでやるとこ
    const words = await Word.where("text", word);
    if (!words.length){
        throw Error("word does not exist!!!!")
    }

    let rpcUrl = 'https://rpc.ankr.com/eth_goerli'
    // superflareでは、fetch POSTするとき現状referrerを設定しないとエラーになる
    let provider = new providers.JsonRpcProvider({
      url: rpcUrl,
      fetchOptions: {
        referrer: rpcUrl,
      },
    });
    // contractからnonceを取得
    let nonceContract = new Contract("0x0F3cCCF9F963D75B9281F665c914B0C13319Aeb1", nonceAbi, provider);
    let nonce = await nonceContract.getNonce(1);
    // console.log("nonce")
    // console.log(nonce.toString())

    // nonceから正解の単語を導く
    let wordsCount = BigNumber.from(await Word.count());
    let wordIndex = nonce.mod(wordsCount).toNumber();
    console.log("wordIndex is ", wordIndex)
    let correctWord = (await Word.find(wordIndex + 1)).text;
    // console.log("correctWord")
    // console.log(correctWord)

    // 入力された単語が正解の単語に含まれてるか調べる
    let matchings = []
    for(let i = 0; i < word.length; i++){
      if(word[i] == correctWord[i]){
        matchings[i] = "match"
        continue;
      }
      if(correctWord.includes(word[i])){
        matchings[i] = "included"
        continue;
      }
      matchings[i] = "none"
    }

    console.log("{ word: word, matchings: matchings }")
    console.log({ word: word, matchings: matchings })
    

    return json({ word: word, matchings: matchings }, { status: 200 });
};

export default function Dashboard() {
  
  return (
    <>
      <h1>Dashboard</h1>
      <Form method="post">
      <label htmlFor="word">Word</label>
        <input name="word" type="text" />
        <button type="submit">submit</button>
      </Form>
      <p></p>
    </>
  );
}
