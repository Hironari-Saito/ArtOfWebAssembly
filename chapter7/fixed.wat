(func $byte_copy
  (param $source i32) (param $dest i32) (param $len i32)
  (local $last_source_byte i32)
  local.get $source
  local.get $len
  i32.add
  local.set $last_source_byte

  (loop $copy_loop (block $break
    local.get $dest
    (i32.load8_u (local.get $source))
    i32.store8
    local.get $dest
    i32.const 1
    i32.add
    local.set $dest
    local.get $source
    i32.const 1
    i32.add
    local.tee $source
    local.get $last_source_byte
    i32.eq
    br_if $break
    br $copy_loop
  ))
)
(func $byte_copy_i64
  (param $source i32) (param $dest i32) (param $len i32)
  (local $last_source_byte i32)
  local.get $source
  local.get $len
  i32.add
  local.set $last_source_byte
  (loop $copy_loop (block $break
    (i64.store (local.get $dest) (i64.load (local.get $source)))
    local.get $dest
    i32.const 8
    i32.add
    local.set $dest
    local.get $source
    i32.const 8
    i32.add
    local.tee $source
    local.get $last_source_byte
    i32.ge_u
    br_if $break
    br $copy_loop
  ))
)
(func $string_copy
  (param $source i32) (param $dest i32) (param $len i32)
  (local $start_source_byte i32)
  (local $start_dest_byte i32)
  (local $singles i32)
  (local $len_less_singles i32)

  local.get $len
  local.set $len_less_singles

  local.get $len
  i32.const 7
  i32.and
  local.tee $singles

  if
    local.get $len
    local.get $singles
    i32.sub
    local.tee $len_less_singles

    local.get $source
    i32.add
    local.set $start_source_byte

    local.get $len_less_singles
    local.get $dest
    i32.add

    local.set $start_dest_byte
    (call $byte_copy (local.get $start_source_byte)
    (local.get $start_dest_byte)(local.get $singles))
  end
  local.get $len
  i32.const 0xff_ff_ff_f8
  i32.and
  local.set $len
  (call $byte_copy_i64 (local.get $source) (local.get $dest) (local.get $len))
)
