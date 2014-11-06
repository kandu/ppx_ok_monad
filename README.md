ok-monad
========

A ppx syntax extension for monad syntax sugar

This ppx preprocessor transform `let ... in' expressions or sequence expressions to CPS code. 

i.e.

an expression like this

    let%m a= b in
    let%m hd::tl= expr () in
    say hi;
    begin%m
      action 1;
      action 2;
    end

will be transformed to

    bind b
      (fun a->
        bind (expr ())
        (fun hd::tl ->
          say hi;
          bind (action 1)
            (fun _ -> say goodbye)))

