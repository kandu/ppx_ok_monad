# ok-monad

A ppx syntax extension for monad syntax sugar

## basic usage

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

## indicate the current monad module

To indicate the current monad module, an alternative attribute can be added after the extension node.

e.g.

    begin%m[@Option]
      action 1;
      action 2;
      action 3;
    end;

will be transformed to

    Option.bind (action 1)
      (fun _ ->
        Option.bind (action 2)
          (fun _ -> action 3))

