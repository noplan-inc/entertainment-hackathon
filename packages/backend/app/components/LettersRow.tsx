type TileProps = {
  letter: string;
  state: string;
};

type RowProps = {
  state: string;
  letterStates: {
    state: string;
    letter: string;
  }[];
};

const LetterTile = (props: TileProps) => {
  return <div className={`letter-tile ${props.state}`}>{props.letter}</div>;
};

const LettersRow = (props: RowProps) => {
  return (
    <div className={`letters-row ${props.state}`}>
      {props.letterStates.map((letterState, i) => (
        <LetterTile
          key={i}
          letter={letterState.letter}
          state={letterState.state}
        />
      ))}
    </div>
  );
};

export default LettersRow;
