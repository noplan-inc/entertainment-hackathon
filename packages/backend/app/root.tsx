import type { LinksFunction, MetaFunction } from "@remix-run/cloudflare";
import {
  Links,
  LiveReload,
  Meta,
  Outlet,
  Scripts,
  ScrollRestoration,
} from "@remix-run/react";
import styles from "./styles/index.css";

import { WagmiConfig, createClient, configureChains, goerli } from 'wagmi'
import { InjectedConnector } from 'wagmi/connectors/injected'
import { publicProvider } from 'wagmi/providers/public'

export const meta: MetaFunction = () => ({
  charset: "utf-8",
  title: "Superflare App",
  viewport: "width=device-width,initial-scale=1",
});

const { chains, provider } = configureChains(    // 1. chainやproviderの設定
  [goerli],    // 2. 使いたいchainを記載
  [
    publicProvider()
  ]
);

const client = createClient({
  autoConnect: true,
  provider: provider,
  connectors: [new InjectedConnector({
    chains,
    options: {
      name: 'Injected',
      shimDisconnect: true,
    },
  }),],
})

export const links: LinksFunction = () => [{ rel: "stylesheet", href: styles }];

export default function App() {
  return (
    <WagmiConfig client={client}>
      <html lang="en" className="h-full bg-gray-100 dark:bg-black">
        <head>
          <Meta />
          <Links />
        </head>
        <body>
          <Outlet />
          <ScrollRestoration />
          <Scripts />
          <LiveReload />
        </body>
      </html>
    </WagmiConfig>
  );
}
