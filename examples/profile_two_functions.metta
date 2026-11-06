(= (profile-step $n)
   (+ $n 1))

(= (profile-driver $n $rounds $acc)
   (if (== $rounds 0)
       $acc
       (profile-driver (profile-step $n) (- $rounds 1) (+ $acc 1))))

!(test (profile-driver 0 20000 0) 20000)
