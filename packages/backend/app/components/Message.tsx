type Props = {
  message?: string;
};

const Message = (props: Props) => {
  return (
    <div className="message">
      <span className={props.message !== "" ? "show" : ""}>
        {props.message}
      </span>
    </div>
  );
};

export default Message;
