import { useState, useEffect, useRef, useMemo } from "react";
import Board from "~/components/Board";
import Keyboard from "~/components/KeyBoard";
import Layout from "~/components/Layout";
import Message from "~/components/Message";

import { json } from "@remix-run/cloudflare";
import { Form, useActionData } from "@remix-run/react";
import { ActionArgs } from "@remix-run/cloudflare";
import { providers, Contract, utils } from "ethers";
import zkWordleAbi from "../../abi/zkWordle.json";
import { useWriteAnswer } from "~/hooks/useWriteAnswer";
import { useSubmit } from "@remix-run/react";
import { decode } from "@msgpack/msgpack";
import mockNFT from "../../public/image/mock.svg";

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
  const numChunks = Math.ceil(str.length / size);
  const chunks = new Array(numChunks);
  for (let i = 0, x = 0; i < numChunks; ++i, x += size) {
    chunks[i] = str.substr(x, size);
  }
  return chunks;
};

const fetchProvingKey = async () => {
  const res = await fetch("/zkp/answer/proving_raw.key");
  // resをv8.deserializeする
  const data = await res.arrayBuffer();
  // const deserialized = v8.deserialize(new Uint8Array(data));
  return new Uint8Array(data);
};

const fetchWordCheckerProvingKey = async () => {
  const res = await fetch("/zkp/hint/proving.key");
  // resをv8.deserializeする
  const data = await res.arrayBuffer();
  // const deserialized = v8.deserialize(new Uint8Array(data));
  return new Uint8Array(data);
};

const fetchWordCheckerArtifacts = async (): Promise<any> => {
  const res = await fetch("/zkp/hint/wordChecker-artifacts");
  // resをv8.deserializeする
  const data = await res.arrayBuffer();
  console.log(data.byteLength);
  // const deserialized = v8.deserialize(new Uint8Array(data));
  return decode(data) as any;
};

const getWordDec = (word: string) => {
  return [...word].map((c) => c.charCodeAt(0).toString());
};

const getWordHex = (word: string) => {
  const hex = utils.sha256(utils.toUtf8Bytes(word)).slice(2);
  console.log(`hex: ${hex}`);
  const chunked = splitByChunk(hex, 8).map((e) => `0x${e}`);
  return chunked.map((e) => parseInt(e, 16).toString());
};

const addressToUintArray = (address: string) => {
  // Remove the '0x' prefix from the address
  address = address.replace(/^0x/, "");

  // Convert the address to a BigInt
  const addressBigInt = BigInt(`0x${address}`);

  // Create an empty array for the result
  const result = new Array(8);

  // Split the BigInt into chunks of 32 bits
  for (let i = 0; i < 8; i++) {
    result[7 - i] = Number(
      (addressBigInt >> BigInt(32 * i)) & 0xffffffffn
    ).toString();
  }

  return result;
};

export async function action({ request, context: { auth } }: ActionArgs) {
  // TODO: wordleMasterから直接読み込む

  console.log(request.url);
  // urlからquery stringのwordを取得する
  const url = new URL(request.url);
  const urlWord = url.searchParams.get("word") || "";

  const formData = new URLSearchParams(await request.text());
  const word = formData.get("word") || urlWord;
  const proof = formData.get("proof");

  if (!word) {
    return json({ error: "word is required" }, { status: 400 });
  }

  console.log(word);

  const rpcUrl = "https://goerli.blockpi.network/v1/rpc/public";
  // superflareでは、fetch POSTするとき現状referrerを設定しないとエラーになる
  const provider = new providers.StaticJsonRpcProvider({
    url: rpcUrl,
    skipFetchSetup: true,
    // fetchOptions: {
    //   referrer: rpcUrl,
    // },
  });
  // contractからnonceを取得
  const zkWordle = new Contract(
    "0x7C372a3E9c275632cF10b2095746e55833Ea5407",
    zkWordleAbi,
    provider
  );
  const nonce = await zkWordle.getLatestNonce();
  // console.log("nonce")
  // console.log(nonce.toString())
  const { master } = await import("../wordle");

  const wordIndex = nonce.mod(master.length).toNumber();
  console.log("wordIndex is ", wordIndex);
  const correctWord = master[wordIndex];
  console.log("correctWord");
  console.log(correctWord);

  type Wordle = "correct" | "present" | "absent";

  // 入力された単語が正解の単語に含まれてるか調べる
  let matchings: Wordle[] = [];
  for (let i = 0; i < word.length; i++) {
    if (word[i] == correctWord[i]) {
      matchings[i] = "correct";
      continue;
    }
    if (correctWord.includes(word[i])) {
      matchings[i] = "present";
      continue;
    }
    matchings[i] = "absent";
  }

  console.log("{ word: word, matchings: matchings }");
  console.log({ word: word, matchings: matchings });

  return json({ word: word, matchings: matchings }, { status: 200 });
}

// ----------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------

export default function Game() {
  const { writeAnswer, signer } = useWriteAnswer();
  const submit = useSubmit();
  const hintData = useActionData<typeof action>();
  const formRef = useRef<HTMLFormElement>(null);
  const wordRef = useRef<HTMLInputElement>(null);

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
  const [isChecking, setCheckingState] = useState<boolean>(false);
  const [answeredCount, setAnsweredCount] = useState<number>(0);
  const [letterCount, setLetterCount] = useState<number>(0);
  const [correctLetters, setCorrectLetters] = useState<string[]>([]);
  const [presentLetters, setPresentLetters] = useState<string[]>([]);
  const [absentLetters, setAbsentLetters] = useState<string[]>([]);
  const [message, setMessage] = useState<string>("");

  const [isRead, setReadStatus] = useState<boolean>(false);

  const isAnswered = useMemo(() => {
    return correctLetters.length === 5;
  }, [correctLetters]);

  const handleCommit = async () => {
    if (!isAnswered) return;
    const answerRaw = correctLetters.join("").toLowerCase();

    setClearStatus(true);
    setMessage("Is correct!");
    let { initialize } = await import("zokrates-js");

    const zokrates = await initialize();
    const artifacts = zokrates.compile(zkSource);
    console.log(artifacts);
    // const answerRaw = correctLetters.join('').toLowerCase();
    console.log(answerRaw);
    const answerDec = getWordDec(answerRaw);
    const hashedAnswer = getWordHex(answerRaw);
    const address = await signer?.getAddress();
    if (!address) {
      alert("Please connect to metamask");
      return;
    }
    const uintAddress = addressToUintArray(address);

    // 引数全部をconsole.log
    const { witness } = zokrates.computeWitness(artifacts, [
      answerDec,
      hashedAnswer,
      uintAddress,
      uintAddress,
    ]);

    const pk = await fetchProvingKey();

    const { proof } = zokrates.generateProof(artifacts.program, witness, pk);
    // @ts-ignore
    const { a, b, c } = proof;

    // TODO colors
    await writeAnswer([a, b, c], answerRaw);
  };

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

  const addCorrectLetters = async (letter: string) => {
    if (correctLetters.indexOf(letter) === -1) {
      setCorrectLetters((prevLetters) => {
        return [...prevLetters, letter];
      });
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

  // formのsubmitボタンを押した時の処理
  const handleSubmit = async (event: any) => {
    const f = formRef.current;

    const word = letterRowStates[answeredCount].letterStates
      .map((el) => el.letter)
      .join("");
    if (!wordRef.current) {
      return;
    }
    wordRef.current.value = word.toLowerCase();

    submit(event.currentTarget);
  };

  const answer = async () => {
    setTimeout(() => {
      setReadStatus(true);
    }, 1000);
  };

  useEffect(() => {
    if (!hintData || !isRead) return;
    if (answeredCount !== 6 && !isClear) {
      if (!isChecking) {
        if (letterCount === 5) {
          setCheckingState(true);

          /* HINT ZKP
          const { initialize } = await import("zokrates-js");
          const zokrates = await initialize();
          const artifacts = await fetchWordCheckerArtifacts();
          console.log(artifacts);
          const pk = await fetchWordCheckerProvingKey();

          const word = letterRowStates[answeredCount].letterStates.map(el => el.letter).join('');
          console.log(`word: ${JSON.stringify(word)}`);
          const encoded = new TextEncoder().encode(word).join(',');
          console.log(`encoded: ${encoded}`);
          try {
            const {witness, output} = zokrates.computeWitness(artifacts, [encoded.split(',')]);
            console.log(witness);

          } catch (e) {
            console.log('witness error')
            console.log(e);
          }
          */

          const promiseList: Promise<void>[] = [];

          for (let i = 0; i < 5; i++) {
            const promise: Promise<void> = new Promise((resolve) => {
              setTimeout(() => {
                if (!hintData) return;
                console.log(`effect in:`);
                console.log(hintData);

                setLetterRowStates((prevState) => {
                  const copyForUpdate = prevState.slice();
                  // @ts-ignore
                  console.log(hintData.matchings[i]);
                  // @ts-ignore
                  copyForUpdate[answeredCount].letterStates[i].state =
                    hintData.matchings[i];
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
                // @ts-ignore
                if (hintData.matchings[i] === "correct") {
                  addCorrectLetters(letterState.letter);
                  // @ts-ignore
                } else if (hintData.matchings[i] === "present") {
                  addPresentLetters(letterState.letter);
                } else {
                  addAbsentLetters(letterState.letter);
                }
              }
            );

            setAnsweredCount((prevState) => prevState + 1);
            setLetterCount(0);
            setCheckingState(false);
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
    setReadStatus(false);
  }, [hintData, isRead, answeredCount]);

  useEffect(() => {
    setTimeout(() => {
      setMessage("");
    }, 2000);
  }, [message]);

  // mocking flug
  const isGetNft = false;
  const isLoading = false;

  return (
    <>
      <Layout>
        <Message message={message} />
        <Board letterRowStates={letterRowStates} />
        <Form method="post" ref={formRef} onSubmit={handleSubmit}>
          <Keyboard
            correctLetters={correctLetters}
            presentLetters={presentLetters}
            absentLetters={absentLetters}
            addLetter={addLetter}
            deleteLetter={deleteLetter}
            answer={answer}
          />
          {isAnswered && (
            <div className="modal">
              <div className="modal-content">
                <h1 className="text-congratulate">Congratulation 🎉</h1>
                {!isGetNft && (
                  <button
                    className="btn-congratulate"
                    onClick={handleCommit}
                    type="button"
                  >
                    GET NFT
                  </button>
                )}
                {isLoading && <div className="loader"></div>}
                {isGetNft && (
                  <div className="svg-image-nft">
                    <img src={mockNFT} alt="nft" />
                  </div>
                )}
              </div>
            </div>
          )}
          <div style={{ display: "none" }}>
            <input name="word" type="text" ref={wordRef} />
          </div>
        </Form>
      </Layout>
    </>
  );
}
