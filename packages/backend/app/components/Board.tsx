import LettersRow from "./LettersRow";

type Props = {
  letterRowStates: {
    state: string;
    letterStates: {
      state: string;
      letter: string;
    }[];
  }[];
};

const Board = (props: Props) => {
  return (
    <div className="board">
      {props.letterRowStates.map((letterRowState, i) => (
        <LettersRow
          key={i}
          state={letterRowState.state}
          letterStates={letterRowState.letterStates}
        />
      ))}
    </div>
  );
};

export default Board;
