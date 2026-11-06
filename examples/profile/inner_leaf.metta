(= (profile-inner $n $acc)
   (if (== $n 0)
       $acc
       (profile-inner (- $n 1) (+ $acc 1))))
