import { useState, useEffect } from "react";
import Board from "~/components/Board";
import Keyboard from "~/components/KeyBoard";
import Layout from "~/components/Layout";
import Message from "~/components/Message";

import { json } from "@remix-run/cloudflare";
import { Form } from "@remix-run/react";
import { Word } from "~/models/Word";
import { ActionArgs } from "@remix-run/cloudflare";
import { providers, Contract, BigNumber, utils } from "ethers";
import zkWordleAbi from "../../abi/zkWordle.json";
import { useWriteAnswer } from "~/hooks/useWriteAnswer";

// ----------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------

const zkSource = `
import "hashes/sha256/sha256Padded";
def main(private u8[5] word, u32[8] expectedHash,private  u32[8] addressUint, u32[8] pubAddressUint) -> bool {
    u32[8] hash = sha256Padded(word);
    assert(hash == expectedHash);
    assert(addressUint == pubAddressUint);
    return true;
}
`;


const splitByChunk = (str: string, size: number) => {
  const numChunks = Math.ceil(str.length / size)
  const chunks = new Array(numChunks)
  for (let i = 0, x = 0; i < numChunks; ++i, x += size) {
      chunks[i] = str.substr(x, size)
  }
  return chunks
}

const fetchProvingKey = async () => {
  const res = await fetch("/zkp/answer/proving_raw.key");
  // resをv8.deserializeする
  const data = await res.arrayBuffer();
  // const deserialized = v8.deserialize(new Uint8Array(data));
  return new Uint8Array(data);
 
}

const getWordDec = (word: string) => {
  return [...word].map(c => c.charCodeAt(0).toString());
}


const getWordHex = (word: string) => {
  const hex = utils.sha256(utils.toUtf8Bytes(word)).slice(2);
  console.log(`hex: ${hex}`);
  const chunked = splitByChunk(hex, 8).map(e => `0x${e}`);
  return chunked.map(e => parseInt(e, 16).toString());
}

const addressToUintArray = (address: string) => {
  // Remove the '0x' prefix from the address
  address = address.replace(/^0x/, '');

  // Convert the address to a BigInt
  const addressBigInt = BigInt(`0x${address}`);

  // Create an empty array for the result
  const result = new Array(8);

  // Split the BigInt into chunks of 32 bits
  for (let i = 0; i < 8; i++) {
      result[7 - i] = Number(addressBigInt >> BigInt(32 * i) & 0xFFFFFFFFn).toString();
  }

  return result;
}

export async function action({ request, context: { auth } }: ActionArgs) {
  // TODO: wordleMasterから直接読み込む

  const formData = new URLSearchParams(await request.text());
  const word = formData.get("word");
  const proof = formData.get("proof");
  // words tableに存在するか確認 ZKでやるとこ
  const words = await Word.where("text", word);
  if (!words.length) {
    throw Error("word does not exist!!!!");
  }

  const rpcUrl = "https://rpc.ankr.com/eth_goerli";
  // superflareでは、fetch POSTするとき現状referrerを設定しないとエラーになる
  const provider = new providers.JsonRpcProvider({
    url: rpcUrl,
    fetchOptions: {
      referrer: rpcUrl,
    },
  });
  // contractからnonceを取得
  const zkWordle = new Contract(
    "0x22f5887ae1bc1E941090CCf00356F897856102dE",
    zkWordleAbi,
    provider
  );
  const nonce = await zkWordle.getLatestNonce();
  // console.log("nonce")
  // console.log(nonce.toString())

  // nonceから正解の単語を導く
  let wordsCount = BigNumber.from(await Word.count());
  let wordIndex = nonce.mod(wordsCount).toNumber();
  console.log("wordIndex is ", wordIndex);
  let correctWord = (await Word.find(wordIndex + 1)).text;
  // console.log("correctWord")
  // console.log(correctWord)

  // 入力された単語が正解の単語に含まれてるか調べる
  let matchings = [];
  for (let i = 0; i < word.length; i++) {
    if (word[i] == correctWord[i]) {
      matchings[i] = "match";
      continue;
    }
    if (correctWord.includes(word[i])) {
      matchings[i] = "included";
      continue;
    }
    matchings[i] = "none";
  }

  console.log("{ word: word, matchings: matchings }");
  console.log({ word: word, matchings: matchings });

  return json({ word: word, matchings: matchings }, { status: 200 });
}

// ----------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------

export default function Game() {
  const {writeAnswer, signer} = useWriteAnswer();
  const answerWord: string = "MOKKY";

  type LetterRowState = {
    state: string;
    letterStates: {
      state: string;
      letter: string;
    }[];
  }[];

  const InitialLetterRowStates: LetterRowState = [];

  for (let i = 0; i < 6; i++) {
    InitialLetterRowStates.push({
      state: "",
      letterStates: [],
    });
    for (let n = 0; n < 5; n++) {
      InitialLetterRowStates[i].letterStates.push({
        state: "",
        letter: "",
      });
    }
  }

  // TODO: useReducerでリファクタ
  const [letterRowStates, setLetterRowStates] = useState<LetterRowState>(
    InitialLetterRowStates
  );
  const [isClear, setClearStatus] = useState<boolean>(false);
  const [isChecking, setChekingState] = useState<boolean>(false);
  const [answeredCount, setAnsweredCount] = useState<number>(0);
  const [letterCount, setLetterCount] = useState<number>(0);
  const [correctLetters, setCorrectLetters] = useState<string[]>([]);
  const [presentLetters, setPresentLetters] = useState<string[]>([]);
  const [absentLetters, setAbsentLetters] = useState<string[]>([]);
  const [message, setMessage] = useState<string>("");

  const addLetter = (letter: string) => {
    if (letterCount < 5 && answeredCount < 6) {
      setLetterRowStates((prevState) => {
        const copyForUpdate = prevState.slice();
        copyForUpdate[answeredCount].letterStates[letterCount] = {
          letter,
          state: "inputted",
        };
        return copyForUpdate;
      });
      setLetterCount((prevState) => prevState + 1);
    }
  };

  const deleteLetter = () => {
    if (letterCount > 0) {
      setLetterRowStates((prevState) => {
        const copyForUpdate = prevState.slice();
        copyForUpdate[answeredCount].letterStates[letterCount - 1] = {
          letter: "",
          state: "",
        };
        return copyForUpdate;
      });
      setLetterCount((prevState) => prevState - 1);
    }
  };

  const addCorrectLetters = (letter: string) => {
    if (correctLetters.indexOf(letter) === -1) {
      setCorrectLetters((prevLetters) => [...prevLetters, letter]);
    }
  };

  const addPresentLetters = (letter: string) => {
    if (presentLetters.indexOf(letter) === -1) {
      setPresentLetters((prevLetters) => [...prevLetters, letter]);
    }
  };

  const addAbsentLetters = (letter: string) => {
    if (absentLetters.indexOf(letter) === -1) {
      setAbsentLetters((prevLetters) => [...prevLetters, letter]);
    }
  };

  // TODO: 現在はフロントでwordle比較を仮でしています。APIとの繋ぎ込みで以下は修正
  const answer = () => {
    if (answeredCount !== 6 && !isClear) {
      if (!isChecking) {
        if (letterCount === 5) {
          setChekingState(true);

          const promiseList: Promise<void>[] = [];

          for (let i = 0; i < 5; i++) {
            const promise: Promise<void> = new Promise((resolve) => {
              setTimeout(() => {
                let state: string;
                const checkLetter =
                  letterRowStates[answeredCount].letterStates[i].letter;
                if (checkLetter === answerWord[i]) {
                  state = "correct";
                } else if (answerWord.indexOf(checkLetter) !== -1) {
                  state = "present";
                } else {
                  state = "absent";
                }

                setLetterRowStates((prevState) => {
                  const copyForUpdate = prevState.slice();
                  copyForUpdate[answeredCount].letterStates[i].state = state;
                  return copyForUpdate;
                });

                resolve();
              }, i * 300);
            });
            promiseList.push(promise);
          }

          Promise.all(promiseList).then(() => {
            letterRowStates[answeredCount].letterStates.forEach(
              (letterState, i) => {
                if (letterState.letter === answerWord[i]) {
                  addCorrectLetters(letterState.letter);
                } else if (answerWord.indexOf(letterState.letter) !== -1) {
                  addPresentLetters(letterState.letter);
                } else {
                  addAbsentLetters(letterState.letter);
                }
              }
            );

            setAnsweredCount((prevState) => prevState + 1);
            setLetterCount(0);
            setChekingState(false);
          });
        } else {
          setLetterRowStates((prevState) => {
            const copyForUpdate = prevState.slice();
            copyForUpdate[answeredCount].state = "shake";
            return copyForUpdate;
          });
          setTimeout(() => {
            setLetterRowStates((prevState) => {
              const copyForUpdate = prevState.slice();
              copyForUpdate[answeredCount].state = "";
              return copyForUpdate;
            });
          }, 500);
          setMessage("Not enough letters");
        }
      }
    }
  };

  useEffect(() => {
    (async () => {
      if (correctLetters.length === 5) {
        setClearStatus(true);
        setMessage("Is correct!");
        let { initialize } = await import("zokrates-js");
  
        const zokrates = await initialize();
        const artifacts = zokrates.compile(zkSource);
        console.log(artifacts);
        const answerRaw = correctLetters.join('').toLowerCase();
        console.log(answerRaw);
        const answerDec = getWordDec(answerRaw);
        const hashedAnswer = getWordHex(answerRaw);
        const address = await signer?.getAddress();
        if (!address) {
          alert('Please connect to metamask')
          return;
        }
        const uintAddress = addressToUintArray(address);

        // 引数全部をconsole.log
        const {witness} = zokrates.computeWitness(artifacts, [answerDec, hashedAnswer, uintAddress, uintAddress]);

        const pk = await fetchProvingKey();

        const {proof} =  zokrates.generateProof(artifacts.program, witness, pk);
        // @ts-ignore
        const {a, b, c} = proof;

        // TODO colors
        await writeAnswer([a,b,c], answerRaw);
      }
    })();
  }, [correctLetters, signer]);

  useEffect(() => {
    if (answeredCount === 6) {
      setMessage(`${answerWord} is correct`);
    }
  }, [answeredCount]);

  useEffect(() => {
    setTimeout(() => {
      setMessage("");
    }, 2000);
  }, [message]);

  return (
    <>
      <Layout>
        <Message message={message} />
        <Board letterRowStates={letterRowStates} />
        <Keyboard
          correctLetters={correctLetters}
          presentLetters={presentLetters}
          absentLetters={absentLetters}
          addLetter={addLetter}
          deleteLetter={deleteLetter}
          answer={answer}
        />
      </Layout>

      <Form method="post">
        <label htmlFor="word">Word</label>
        <input name="word" type="text" />
        <button type="submit">submit</button>
      </Form>
      <p></p>
    </>
  );
}
