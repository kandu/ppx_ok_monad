open Asttypes
open Parsetree

open Ast_helper
open Ast_mapper

open Location

let ident_bind moduleName=
  let bind=
    (match moduleName with
    | "" -> ""
    | s -> s ^ ".")
    ^ "bind"
  in Exp.ident {txt= Longident.parse bind; loc= Location.none}

let rec cps_sequence mapper expr=
  match expr with
  | {
      pexp_desc= Pexp_sequence (expr1, expr2);
      pexp_loc;
      pexp_attributes;
    } ->
      let ident_bind=
        match pexp_attributes with
        | [] -> ident_bind ""
        | [(loc,_)]-> ident_bind loc.txt
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
              ("", expr1);
              ("", fun_ "" None (Pat.any ()) (do_cps_sequence mapper expr2));
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
      (match pexp_attributes with
      | []->
        Exp.(apply (ident_bind "") [
          ("", binding.pvb_expr);
          ("", fun_ "" None binding.pvb_pat expr);
          ])
      | [(loc,_)]->
        Exp.(apply (ident_bind loc.txt) [
          ("", binding.pvb_expr);
          ("", fun_ "" None binding.pvb_pat expr);
          ])
      | _::(loc,_)::_->
        raise (Error (error ~loc:loc.loc "too many attributes" ~if_highlight:loc.txt)))
  | _ -> default_mapper.expr mapper expr

let cps_mapper argv=
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

let ()= run_main cps_mapper

