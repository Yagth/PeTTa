!(import! &self profile_inner_leaf)

(= (profile-outer $n $rounds $acc)
   (if (== $rounds 0)
       $acc
       (profile-outer $n (- $rounds 1) (+ $acc (profile-inner $n 0)))))
