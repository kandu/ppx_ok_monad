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
  in Exp.ident ~loc:(in_file loc.loc_start.Lexing.pos_fname) (Location.mkloc (Longident.parse bind) !default_loc)

let rec cps_sequence mapper expr=
  match expr with
  | {
      pexp_desc= Pexp_sequence (expr1, expr2);
      pexp_loc;
      pexp_attributes;
    } ->
      let ident_bind=
        match pexp_attributes with
        | [] -> ident_bind "" pexp_loc
        | [(loc,_)]-> ident_bind loc.txt loc.loc
        | _::(loc,_)::_->
          raise (Error (error ~loc:loc.loc "too many attributes" ~if_highlight:loc.txt))
      in
      let rec do_cps_sequence mapper expr=
        (match expr with
        | {
            pexp_desc= Pexp_sequence (expr1, expr2);
            pexp_loc;
            pexp_attributes;
          } ->
            Exp.(apply ident_bind [
              (Nolabel, expr1);
              (Nolabel, fun_ Nolabel None (Pat.construct (Location.mkloc (Longident.parse "()") !default_loc) None) (do_cps_sequence mapper expr2));
              ])
        | _ -> default_mapper.expr mapper expr)
      in do_cps_sequence mapper expr
  | _ -> default_mapper.expr mapper expr

let cps_let mapper expr=
  match expr with
  | {
      pexp_desc= Pexp_let (flag, [binding], expr);
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
        Exp.(apply (ident_bind "" pexp_loc) [
          (Nolabel, binding.pvb_expr);
          (Nolabel, fun_ Nolabel None binding.pvb_pat expr);
          ])
      | [(loc,_)]->
        Exp.(apply (ident_bind loc.txt loc.loc) [
          (Nolabel, binding.pvb_expr);
          (Nolabel, fun_ Nolabel None binding.pvb_pat expr);
          ])
      | _::(loc,_)::_->
        raise (Error (error ~loc:loc.loc "too many attributes" ~if_highlight:loc.txt)))
  | _ -> default_mapper.expr mapper expr

let cps_mapper _config _cookies=
  { default_mapper with
    expr= fun mapper expr->
      match expr with
      | { pexp_desc= Pexp_extension ({txt= "m"; loc}, pstr)}->
        (match pstr with
        | PStr[{pstr_desc= Pstr_eval (expr, attrs)}] ->
          { (expr |> cps_sequence mapper |> cps_let mapper)
            with pexp_loc= expr.pexp_loc
          }
        | _ -> raise (Error (error ~loc:loc "unknown error")))
      | _ -> default_mapper.expr mapper expr
  }

let ()= Driver.register ~name:"ppx_ok_monad" (module OCaml_403) cps_mapper

