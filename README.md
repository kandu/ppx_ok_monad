# ppx\_ok\_monad

A ppx syntax extension for monad syntax sugar

## basic usage

This ppx preprocessor transform `let ... in' expressions or sequence expressions to CPS code. 

i.e.

an expression like this

```
#!ocaml

let%m a= b in
let%m hd::tl= expr () in
say hi;
begin%m
  action 1;
  action 2;
end
```

will be transformed to

```
#!ocaml

bind b
  (fun a->
    bind (expr ())
    (fun hd::tl ->
      say hi;
      bind (action 1)
        (fun _ -> action 2)))
```

## indicate the current monad module

To indicate the current monad module, an optional attribute can be added after the extension node.

e.g.

```
#!ocaml

begin%m[@Option]
  action 1;
  action 2;
  action 3;
end
```

will be transformed to

```
#!ocaml

Option.bind (action 1)
  (fun _ ->
    Option.bind (action 2)
      (fun _ -> action 3))
```
