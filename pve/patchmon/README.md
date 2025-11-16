# PatchMon

See documentation located [here][1].

## Backend

```shell
cd /opt/patchmon/backend
rm -rf node_modules
rm -f package-lock.json
npm install --include=dev --no-audit --no-fund --ignore-scripts
npm rebuild vite
npm rebuild rollup
npm run build
```

[1]: <https://nicholaswilde.io/homelab/apps/patchmon/>
