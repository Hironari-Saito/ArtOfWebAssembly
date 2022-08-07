(module
  (global $cnvs_size (import "env" "cnvs_size") i32)
  
  (global $no_hit_color (import "env" "no_hit_color") i32)
  (global $hit_color (import "env" "hit_color") i32)
  (global $obj_start (import "env" "obj_start") i32)
  (global $obj_size (import "env" "obj_size") i32)
  (global $obj_cnt (import "env" "obj_cnt") i32)

  (global $x_offset (import "env" "x_offset") i32)   ;; バイト00 - 03
  (global $y_offset (import "env" "y_offset") i32)   ;; バイト04 - 07
  (global $xv_offset (import "env" "xv_offset") i32) ;; バイト08 - 11
  (global $yv_offset (import "env" "yv_offset") i32) ;; バイト12 - 15
  (import "env" "buffer" (memory 80))                ;; キャンバスバッファ

  ;; キャンバス全体をクリア
  (func $clear_canvas
    (local $i i32)
    (local $pixel_bytes i32)

    ;; $width * $height
    global.get $cnvs_size
    global.get $cnvs_size
    i32.mul

    ;; ピクセルごとに4バイト
    i32.const 4
    i32.mul

    ;; $pixel_bytes = $width * $height * 4
    local.set $pixel_bytes

    (loop $pixel_loop
      (i32.store (local.get $i) (i32.const 0xff_00_00_00))

      ;; $i += 4 (ピクセルごとに4バイト)
      (i32.add (local.get $i) (i32.const 4))
      local.set $i

      ;; $i < $pixel_bytesの場合
      (i32.lt_u (local.get $i) (local.get $pixel_bytes))
      br_if $pixel_loop  ;; 全ピクセルを設定したらループ終了
    
    )
  )

  ;; この関数は渡された整数の絶対値を返す
  (func $abs
    (param $value i32)
    (result i32)

    (i32.lt_s (local.get $value) (i32.const 0)) ;; $valueは負か?
    if ;; $valueが負の場合は0から引いて正の値を求める
      i32.const 0
      local.get $value
      i32.sub
      return
    end
    
    local.get $value ;;元の値を返す
  )

  ;; 座標($x, $y)にあるピクセルの色を$cに設定
  (func $set_pixel
    (param $x i32)
    (param $y i32)
    (param $c i32)

    ;; $x > $cnvs_sizeか?
    (i32.ge_u (local.get $x) (global.get $cnvs_size))
    if  ;; $xがキャンバスの範囲外の場合
      return
    end

    ;; $y > $cnvs_sizeか?
    (i32.ge_u (local.get $y) (global.get $cnvs_size))
    if ;; $yがキャンバスの範囲外の場合
      return
    end
    
    ;; $y * $cnvs_size + $x (線形メモリ内のピクセルの位置)
    local.get $y
    global.get $cnvs_size
    i32.mul
    local.get $x
    i32.add

    ;; 各ピクセルは4バイトなので4を掛ける
    i32.const 4
    i32.mul

    ;; 格納する色値
    local.get $c

    ;; 色値をメモリ位置に格納 ($y * $cnvs_size + $x) * 4の位置
    i32.store
  )

  ;; パラメータ($x,$y,$c)でマルチピクセルオブジェクトを矩形として描画
  (func $draw_obj
    (param $x i32)
    (param $y i32)
    (param $c i32)
    
    (local $max_x i32)
    (local $max_y i32)

    (local $xi i32)
    (local $yi i32)

    ;; $max_x = $x + $obj_size
    local.get $x
    local.tee $xi  ;; $xi = $x
    global.get $obj_size
    i32.add
    local.set $max_x

    ;; $max_y = $y + $obj_size
    local.get $y
    local.tee $yi
    global.get $obj_size
    i32.add
    local.set $max_y

    (block $break (loop $draw_loop
      local.get $xi
      local.get $yi
      local.get $c
      call $set_pixel

      ;; $xi++
      local.get $xi
      i32.const 1
      i32.add
      local.tee $xi
      
      ;; $xi >= $max_xか?
      local.get $max_x
      i32.ge_u
      if
        ;; $xiを$xにリセット
        local.get $x
        local.set $xi

        ;; $yi++
        local.get $yi
        i32.const 1
        i32.add
        local.tee $yi

        ;; $yi >= $max_yか?
        local.get $max_y
        i32.ge_u
        br_if $break
      end

      br $draw_loop
    ))
  )

  ;; オブジェクト番号, 属性オフセット, 属性の値に基づいて
  ;; 線形メモリ内のオブジェクトの属性を設定
  (func $set_obj_attr
    (param $obj_number i32)
    (param $attr_offset i32)
    (param $value i32)

    ;; $obj_number * 16バイトのストライド
    local.get $obj_number
    i32.const 16
    i32.mul

    ;; オブジェクトのベースアドレスを足す
    global.get $obj_start
    ;; ($obj_number * 16) + $obj_start
    i32.add

    ;; アドレスに属性のオフセットを足す
    local.get $attr_offset
    ;; ($obj_number*16) + $obj_start + $attr_offset
    i32.add

    ;; ($obj_number*16) + $obj_start + $attr_offsetの位置に$valueを格納
    local.get $value
    i32.store
  )

  (func $get_obj_attr
    (param $obj_number i32)
    (param $attr_offset i32)
    (result i32)

    ;; $obj_number * 16
    local.get $obj_number
    i32.const 16
    i32.mul

    ;; ($obj_number * 16) + $obj_start
    global.get $obj_start
    i32.add

    ;; ($obj_number * 16) + $obj_start + $attr_offset
    local.get $attr_offset
    i32.add

    ;; このメモリの位置の値を読み込む
    i32.load

    ;; 属性の値を返す
  )

  ;; アプリケーション内のすべてのオブジェクトを動かし、衝突を検知
  (func $main (export "main")
    (local $i i32)           ;; 外側のループのカウンタ
    (local $j i32)           ;; 内側のループのカウンタ
    (local $outer_ptr i32)   ;; 外側のループのオブジェクトへのポインタ
    (local $inner_ptr i32)   ;; 内側のループのオブジェクトへのポインタ

    (local $x1 i32)          ;; 外側のループのオブジェクトのx座標
    (local $x2 i32)          ;; 内側のループのオブジェクトのx座標
    (local $y1 i32)          ;; 外側のループのオブジェクトのy座標
    (local $y2 i32)          ;; 内側のループのオブジェクトのy座標

    (local $xdist i32)       ;; オブジェクト間のx軸の距離
    (local $ydist i32)       ;; オブジェクト間のy軸の距離

    (local $i_hit i32)       ;; $iオブジェクトの衝突フラグ
    (local $xv i32)          ;; x速度
    (local $yv i32)          ;; y速度

    (call $clear_canvas)     ;; キャンバスを黒で塗りつぶす

    (loop $move_loop
      ;; x属性を取得
      (call $get_obj_attr (local.get $i) (global.get $x_offset))
      local.set $x1

      ;; y属性を取得
      (call $get_obj_attr (local.get $i) (global.get $y_offset))
      local.set $y1

      ;; xの速度属性を取得
      (call $get_obj_attr (local.get $i) (global.get $xv_offset))
      local.set $xv

      ;; yの速度属性を取得
      (call $get_obj_attr (local.get $i) (global.get $yv_offset))
      local.set $yv

      ;; xに速度を足し、キャンバスの境界内に留まらせる
      (i32.add (local.get $xv) (local.get $x1))
      i32.const 0x1ff  ;; 10進数の511
      i32.and          ;; 上位23ビットを0にする
      local.set $x1

      ;; yに速度を足し、キャンバスの境界内に止まらせる
      (i32.add (local.get $yv) (local.get $y1))
      i32.const 0x1ff  ;; 10進数の511
      i32.and          ;; 上位23ビットを0にする
      local.set $y1

      ;; 線形メモリ内のx属性を設定
      (call $set_obj_attr
        (local.get $i)
        (global.get $x_offset)
        (local.get $x1)
      )

      ;; 線形メモリ内のy属性を設定
      (call $set_obj_attr
        (local.get $i)
        (global.get $y_offset)
        (local.get $y1)
      )

      local.get $i
      i32.const 1
      i32.add
      local.tee $i ;; $iをインクリメント

      global.get $obj_cnt
      i32.lt_u ;; $i < $obj_cnt
      ;; $i < $obj_cntの場合は$move_loopの先頭に戻る
      if
        br $move_loop
      end
    )

    i32.const 0
    local.set $i

    (loop $outer_loop (block $outer_break
      i32.const 0
      local.tee $j  ;; $jを0に設定

      ;; $i_hitはブールフラグであり,falseの場合は0, trueの場合は1
      local.set $i_hit ;; $i_hitを0に設定

      ;; オブジェクト$iのx属性を取得
      (call $get_obj_attr (local.get $i) (global.get $x_offset))
      local.set $x1

      ;; オブジェクト$iのy属性を取得
      (call $get_obj_attr (local.get $i) (global.get $y_offset))
      local.set $y1
      
      (loop $inner_loop (block $inner_break
        local.get $i
        local.get $j
        i32.eq

        ;; $i == $jの場合は$jをインクリメント
        if
          local.get $j
          i32.const 1
          i32.add
          local.set $j
        end

        local.get $j
        global.get $obj_cnt
        i32.ge_u
        ;; $j >= $obj_cntの場合は内側のループを抜ける
        if
          br $inner_break
        end

        ;; x属性を取得
        (call $get_obj_attr (local.get $j) (global.get $x_offset))
        local.set $x2

        ;; $x1とx2の距離
        (i32.sub (local.get $x1) (local.get $x2))

        call $abs          ;; 距離は負にならないので絶対値を取得
        local.tee $xdist   ;; $xdist = | $x1 - $x2|

        global.get $obj_size
        i32.ge_u

        ;; $xdist >= $obj_sizeの場合、オブジェクトは衝突していない
        if
          local.get $j
          i32.const 1
          i32.add
          local.set $j
          ;; $jをインクリメントして内側のループの先頭に移動
          br $inner_loop
        end

        ;; y属性を取得
        (call $get_obj_attr (local.get $j) (global.get $y_offset))
        local.set $y2

        ;; $y1と$y2の距離
        (i32.sub (local.get $y1) (local.get $y2))

        call $abs
        local.tee $ydist

        global.get $obj_size
        i32.ge_u

        ;; $ydist >= $obj_sizeの場合、オブジェクトは衝突していない
        if
          local.get $j
          i32.const 1
          i32.add
          local.set $j
          ;; $jをインクリメントして内側のループの先頭に移動
          br $inner_loop
        end

        i32.const 1
        local.set $i_hit
        ;; オブジェクトが衝突している場合はループを終了
      ))  ;; 内側のループの終わり

      local.get $i_hit
      i32.const 0
      i32.eq
      if     ;; $i_hit == 0の場合 (衝突していない)
        (call $draw_obj (local.get $x1) (local.get $y1) (global.get $no_hit_color))
      else   ;; $i_hit == 1の場合（衝突している）
        (call $draw_obj (local.get $x1) (local.get $y1) (global.get $hit_color))
      end

      local.get $i
      i32.const 1
      i32.add
      local.tee $i ;; $iをインクリメント
      global.get $obj_cnt
      i32.lt_u
      ;; $i < $obj_cntの場合は外側のループの先頭に移動
      if
        br $outer_loop
      end    
    ))  ;; 外側のループの終わり
  )  ;; $main関数の終わり
) ;; モジュールの終わり