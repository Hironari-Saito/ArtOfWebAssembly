(module
  (func (export "pow2_mul")
    (param $p1 i32)
    (param $p2 i32)
    (result i32)

    ;; 2^4 (16)を掛ける
    local.get $p1
    i32.const 16
    i32.mul

    ;; 2^3 (8)で割る
    local.get $p2
    i32.const 8
    i32.div_u
    i32.add
  )
)