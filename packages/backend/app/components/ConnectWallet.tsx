import { useAccount, useConnect, useDisconnect } from "wagmi";
import { InjectedConnector } from "wagmi/connectors/injected";

export const ConnectWallet = () => {
  const { address, isConnected } = useAccount();
  const { connect } = useConnect({
    connector: new InjectedConnector(),
  });
  const { disconnect } = useDisconnect();

  if (isConnected)
    return (
      <div className="text-connected">
        Connected to
        <br />
        {address}
        <br />
        <button className="btn-connect" onClick={() => disconnect()}>
          Disconnect
        </button>
      </div>
    );
  return (
    <button className="btn-connect" onClick={() => connect()}>
      Connect Wallet
    </button>
  );
};
