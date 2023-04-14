import { useState, useEffect } from "react";
import Board from "~/components/Board";
import Keyboard from "~/components/KeyBoard";
import Layout from "~/components/Layout";
import Message from "~/components/Message";

import { json } from "@remix-run/cloudflare";
import { Form } from "@remix-run/react";
import { Word } from "~/models/Word";
import { ActionArgs } from "@remix-run/cloudflare";
import { providers, Contract, BigNumber } from "ethers";
import nonceAbi from "../../abi/nonce.json";
import { wodles } from "../../../svg-nft-sandbox/test/wordleMaster";

// ----------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------

export async function action({ request, context: { auth } }: ActionArgs) {
  // DBにデータを入れる => 直接wodlesを用いる。

  const formData = new URLSearchParams(await request.text());
  const word = formData.get("word");
  const proof = formData.get("proof");
  // words tableに存在するか確認 ZKでやるとこ
  const words = await Word.where("text", word);
  if (!words.length) {
    throw Error("word does not exist!!!!");
  }

  let rpcUrl = "https://rpc.ankr.com/eth_goerli";
  // superflareでは、fetch POSTするとき現状referrerを設定しないとエラーになる
  let provider = new providers.JsonRpcProvider({
    url: rpcUrl,
    fetchOptions: {
      referrer: rpcUrl,
    },
  });
  // contractからnonceを取得
  let nonceContract = new Contract(
    "0x0F3cCCF9F963D75B9281F665c914B0C13319Aeb1",
    nonceAbi,
    provider
  );
  let nonce = await nonceContract.getNonce(1);
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
  const answerWord: string = "REACT";

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
    if (correctLetters.length === 5) {
      setClearStatus(true);
      setMessage("Is correct!");
    }
  }, [correctLetters]);

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
