# Superflare + Remix

This is a template for using Superflare + Remix.

```bash
npm run dev
```

```bash
cp .dev.vars.example .dev.vars
```

## migrate
```bash
npx wrangler d1 migrations apply backend-db -j
```

## deploy
```bash
npx wrangler publish -j
```

