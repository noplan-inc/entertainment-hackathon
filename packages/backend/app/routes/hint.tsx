
import { type LoaderArgs, redirect, json } from "@remix-run/cloudflare";
import { Form, Link, useActionData } from "@remix-run/react";
import { Word } from "~/models/Word";
import { ActionArgs } from "@remix-run/cloudflare";
import { providers, Contract, ethers }from "ethers";
import nonceAbi from "../../abi/nonce.json";



export async function action({ request, context: { auth } }: ActionArgs) {
    const formData = new URLSearchParams(await request.text());
    const word = formData.get("word");
    // words tableに存在するか確認 ZKでやるとこ
    const words = await Word.where("text", word);
    if (!words.length){
        console.log("word does not exist!!!!")
    }

    let provider = new providers.StaticJsonRpcProvider("https://goerli.blockpi.network/v1/rpc/public", 5);
    let nonceContract = new Contract("0x0F3cCCF9F963D75B9281F665c914B0C13319Aeb1", nonceAbi, provider);
    let nonce = await nonceContract.functions.getNonce("1");
    console.log("nonce")
    console.log(nonce)
    console.log("aaaa")
    

    return json({ message: "status" }, { status: 200 });
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
