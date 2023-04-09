import { Button } from "~/components/Button";
import Layout from "~/components/Layout";

export default function Game() {
  return (
    <>
      <Layout>
        <Button href="/" prefetch="intent">
          sample Button
        </Button>
      </Layout>
    </>
  );
}
