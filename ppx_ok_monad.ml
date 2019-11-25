open Migrate_parsetree
open OCaml_403.Ast

open Asttypes
open Parsetree

open Ast_helper
open Ast_mapper
open Location

let ident_bind moduleName loc=
  let bind=
    (match moduleName with
    | "" -> ""
    | s -> s ^ ".")
    ^ "bind"
  in Exp.ident (Location.mkloc (Longident.parse bind) loc)

let cps_expr mapper expr=
  match expr with
  | {
      pexp_desc= Pexp_let (_flag, [binding], expr);
      pexp_loc;
      pexp_attributes;
    } ->
      (let attrs=
        if OCaml_current.version = 402
        then pexp_attributes
        else binding.pvb_attributes
      in
      match attrs with
      | []->
        Exp.(apply ~loc:pexp_loc (ident_bind "" pexp_loc) [
          (Nolabel, binding.pvb_expr);
          (Nolabel, fun_ ~loc:pexp_loc Nolabel None binding.pvb_pat (mapper.expr mapper expr));
          ])
      | [(loc,_)]->
        Exp.(apply ~loc:pexp_loc (ident_bind loc.txt pexp_loc) [
          (Nolabel, binding.pvb_expr);
          (Nolabel, fun_ ~loc:pexp_loc Nolabel None binding.pvb_pat (mapper.expr mapper expr));
          ])
      | _::(loc,_)::_->
        raise (Error (error ~loc:loc.loc "too many attributes" ~if_highlight:loc.txt)))
  | {
      pexp_desc= Pexp_sequence (_expr1, _expr2);
      pexp_loc;
      pexp_attributes;
    } ->
      let ident_bind=
        match pexp_attributes with
        | [] -> ident_bind "" pexp_loc
        | [(loc,_)]-> ident_bind loc.txt pexp_loc
        | _::(loc,_)::_->
          raise (Error (error ~loc:loc.loc "too many attributes" ~if_highlight:loc.txt))
      in
      let rec do_cps_sequence mapper expr=
        (match expr with
        | {
            pexp_desc= Pexp_sequence (expr1, expr2);
            pexp_loc;
            pexp_attributes=_;
          } ->
            Exp.(apply ~loc:pexp_loc ident_bind [
              (Nolabel, mapper.expr mapper expr1);
              (Nolabel,
                fun_
                  ~loc:pexp_loc
                  Nolabel
                  None
                  (Pat.construct ~loc:expr1.pexp_loc (Location.mkloc (Longident.parse "()") !default_loc) None)
                  (do_cps_sequence mapper expr2));
              ])
        | _ -> mapper.expr mapper expr)
      in do_cps_sequence mapper expr
  | _ -> default_mapper.expr mapper expr

let cps_mapper _config _cookies=
  { default_mapper with
    expr= fun mapper expr->
      match expr with
      | { pexp_desc= Pexp_extension ({txt= "m"; loc}, pstr); _}->
        (match pstr with
        | PStr[{pstr_desc= Pstr_eval (expr, _attrs);_ }] ->
          { (expr |> cps_expr mapper)
            with pexp_loc= expr.pexp_loc
          }
        | _ -> raise (Error (error ~loc:loc "unknown error")))
      | _ -> default_mapper.expr mapper expr
  }

let ()= Driver.register ~name:"ppx_ok_monad" (module OCaml_403) cps_mapper

