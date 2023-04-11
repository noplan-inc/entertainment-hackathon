import deleteIcon from "../../public/image/delete-icon.svg";

type Props = {
  addLetter: Function;
  deleteLetter: Function;
  answer: Function;
  correctLetters: string[];
  presentLetters: string[];
  absentLetters: string[];
};

type EnterProps = {
  answer: Function;
};

type DeleteProps = {
  deleteLetter: Function;
};

type LetterProps = {
  letter: string;
  status: string;
  addLetter: Function;
};

const EnterKey = (props: EnterProps) => {
  return (
    <div className="one-and-a-half key" onClick={() => props.answer()}>
      enter
    </div>
  );
};

const DeleteKey = (props: DeleteProps) => {
  return (
    <div className="one-and-a-half key" onClick={() => props.deleteLetter()}>
      <img src={deleteIcon} alt="delete-key" />
    </div>
  );
};

const LetterKey = (props: LetterProps) => {
  return (
    <div
      className={`key ${props.status}`}
      onClick={() => props.addLetter(props.letter)}
    >
      {props.letter}
    </div>
  );
};

const Keyboard = (props: Props) => {
  const keyboardLetters: string[][] = [
    ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
    ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
    ["Z", "X", "C", "V", "B", "N", "M"],
  ];

  type LetterWithStatus = {
    status: string;
    letter: string;
  }[][];

  const keyboardLettersWithStatus: LetterWithStatus = keyboardLetters.map(
    (letters) => {
      return letters.map((letter) => {
        let status: string = "";
        if (props.correctLetters.includes(letter)) {
          status = "correct";
        } else if (props.presentLetters.includes(letter)) {
          status = "present";
        } else if (props.absentLetters.includes(letter)) {
          status = "absent";
        }
        return { letter, status };
      });
    }
  );

  return (
    <div id="keyboard">
      <div className="row">
        {keyboardLettersWithStatus[0].map((letterWithStatus, i) => (
          <LetterKey
            key={i}
            letter={letterWithStatus.letter}
            status={letterWithStatus.status}
            addLetter={props.addLetter}
          />
        ))}
      </div>
      <div className="row">
        <div className="spacer half"></div>
        {keyboardLettersWithStatus[1].map((letterWithStatus, i) => (
          <LetterKey
            key={i}
            letter={letterWithStatus.letter}
            status={letterWithStatus.status}
            addLetter={props.addLetter}
          />
        ))}
        <div className="spacer half"></div>
      </div>
      <div className="row">
        <EnterKey answer={props.answer} />
        {keyboardLettersWithStatus[2].map((letterWithStatus, i) => (
          <LetterKey
            key={i}
            letter={letterWithStatus.letter}
            status={letterWithStatus.status}
            addLetter={props.addLetter}
          />
        ))}
        <DeleteKey deleteLetter={props.deleteLetter} />
      </div>
    </div>
  );
};

export default Keyboard;
