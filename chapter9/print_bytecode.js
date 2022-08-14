// node --print-bytecode --print-bytecode-filter=bytecode_test print_bytecode.js

function bytecode_test() {
  let x = 0;
  for (let i = 0; i < 100_000_000; i++) {
    x = i % 1000;
  }
  return 99;
}

// この呼出がないとDCE検査で関数が削除される
bytecode_test();