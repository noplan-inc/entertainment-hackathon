import { ConnectWallet } from "./ConnectWallet";

const Header = () => {
  return (
    <header className="flex">
      ZKWordle
      <div>
        <ConnectWallet />
      </div>
    </header>
  );
};

export default Header;
