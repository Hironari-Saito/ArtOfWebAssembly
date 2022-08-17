(module
  (func $distance (export "distance")
    (param $x1 f64) (param $y1 f64) (param $x2 f64) (param $y2 f64)
    (result f64)
    (local $x_dist f64)
    (local $y_dist f64)
    (local $temp_f64 f64)

    ;; ($x1 - $x2) ^ 2
    local.get $x1
    local.get $x2
    f64.sub

    local.tee $x_dist
    local.get $x_dist
    f64.mul

    ;; ($y1 - $y2) ^ 2
    ;; 誤って ($y1 + $y2) ^ 2とした場合
    local.get $y1
    local.get $y2
    f64.add   ;; この行が誤っている
    local.tee $y_dist

    local.get $y_dist
    f64.mul

    ;; $x_dist ^2 + $y_dist ^ 2
    f64.add

    ;; 平方根
    f64.sqrt

  )
)