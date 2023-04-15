import { ConnectWallet } from "./ConnectWallet";

const Header = () => {
  return <header className="flex">
    Blockchain Wordle
    <div>
      <ConnectWallet/>
    </div>
  </header>;
};

export default Header;
