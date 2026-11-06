; A repeated variable in a call argument must not loop type inference.
; Before the fix, each of these definitions exhausted the stack at load time.
(= (rv-id $x) $x)
(= (rv-dup $e) (rv-id ($e $e)))
!(test (rv-dup 7) (7 7))

(= (rv-fst ($a $b)) $a)
(= (rv-pair $e) (rv-fst ($e $e)))
!(test (rv-pair 7) 7)

(= (rv-merge $xs $ys)
   (case ($xs $ys)
         (((() $ys) $ys)
          (($xs ()) $xs)
          (($xs $ys)
           (let* ((($x $xss) (decons-atom $xs))
                  (($y $yss) (decons-atom $ys)))
                 (if (< $x $y)
                     (let $t (rv-merge $xss $ys) (cons-atom $x $t))
                     (let $t (rv-merge $xs $yss) (cons-atom $y $t))))))))
!(test (rv-merge (1 3) (2 4)) (1 2 3 4))
