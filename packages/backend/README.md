# Superflare + Remix

This is a template for using Superflare + Remix.

```bash
npm run dev
```

```bash
cp .dev.vars.example .dev.vars
```

## SQL execute

CloudFlare D1に対して行うとき、wrangler.jsonを編集する必要ある

```wrangler.json
"d1_databases": [
    {
      "binding": "DB",
      "database_name": "YOUR_DATABASE_NAME",
      "database_id": "YOUR_DATABASE_ID"
    }
  ],
```

以下コマンドで実行する

```bash
yarn wrangler d1 execute backend-db --file migrations/0002_seed_words.sql -j
```

## migrate
```bash
npx wrangler d1 migrations apply backend-db -j
```

## deploy
```bash
npx wrangler publish -j
```

