# The Art of WebAssembly


## webassembly
```
# install
npm install

# exec
npx wat2wasm <wat file>
npx node <js file>

# ダウンロードサイズの最適化優先
## -Oz < -Os: ファイルサイズ
## -Oz > -Os: 実行時間
npx wasm-opt <wasm file> -O[zs] -o <output file>

# パフォーマンスの最適化優先
## -O1 < -O2 < -O3: 最適化の効果
## -O1 < -O2 < -O3: 実行時間
npx wasm-opt <wasm file> -O[1-3] -o <output file>
```

## assemblyScript

```
npx <assembly script> -O[0-3sz] -o < .wat | .wasm> [--sourceMap]

# 文字列をWebAssemblyモジュールに渡す。 JavaScriptから__allocString関数を呼び出すことができるようになる。
--exportRuntime
```