open Asttypes
open Parsetree

open Ast_helper
open Ast_mapper

exception Error of Location.t

let ident_bind= Exp.ident {txt= Longident.parse "bind"; loc= Location.none}

let rec cps_sequence mapper expr=
  match expr with
  | {
      pexp_desc= Pexp_sequence (expr1, expr2);
      pexp_loc;
      pexp_attributes;
    } ->
      Exp.(apply ident_bind [
        ("", expr1);
        ("", fun_ "" None (Pat.any ()) (cps_sequence mapper expr2));
        ])
  | _ -> default_mapper.expr mapper expr

let cps_let mapper expr=
  match expr with
  | {
      pexp_desc= Pexp_let (flag, [binding], expr);
      pexp_loc;
      pexp_attributes;
    } ->
      Exp.(apply ident_bind [
        ("", binding.pvb_expr);
        ("", fun_ "" None binding.pvb_pat expr);
        ])
  
  | _ -> default_mapper.expr mapper expr

let cps_mapper argv=
  { default_mapper with
    expr= fun mapper expr->
      match expr with
      | { pexp_desc= Pexp_extension ({txt= "c"; loc}, pstr)}->
        (match pstr with
        | PStr[{pstr_desc= Pstr_eval (expr, attrs)}] ->
          { (expr |> cps_sequence mapper |> cps_let mapper)
            with pexp_loc= expr.pexp_loc
          }
        | _ -> raise (Error loc))
      | _ -> default_mapper.expr mapper expr
  }

let ()= run_main cps_mapper

