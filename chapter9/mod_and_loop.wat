(module
  (func (export "mod_loop")
    (result i32)
    (local $i i32)
    (local $total i32)
    i32.const 100_000_000
    local.set $i

    (loop $loop
      local.get $i
      i32.const 0x3ff
      i32.rem_u
      local.set $total

      ;; $i--
      local.get $i
      i32.const 1
      i32.sub
      local.tee $i

      br_if $loop
    )
    local.get $total
  )
  (func (export "and_loop")
    (result i32)
    (local $total i32)
    (local $i i32)
    i32.const 100_000_000
    local.set $i

    (loop $loop
      local.get $i
      i32.const 0x3ff
      i32.and
      local.set $total

      local.get $i
      i32.const 1
      i32.sub
      local.tee $i

      br_if $loop
    )
    local.get $total
  )
)