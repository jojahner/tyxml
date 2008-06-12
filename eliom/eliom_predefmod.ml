(* Ocsigen
 * http://www.ocsigen.org
 * Module Eliom_predefmod
 * Copyright (C) 2007 Vincent Balat
 * Laboratoire PPS - CNRS Universit� Paris Diderot
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)




open Lwt
open Ocsigen_lib
open XHTML.M
open Xhtmltypes
open Ocsigen_extensions
open Eliom_sessions
open Eliom_services
open Eliom_parameters
open Eliom_mkforms
open Eliom_mkreg

open Ocsigen_http_frame
open Ocsigen_http_com


module type ELIOMSIG = sig
  include Eliom_mkreg.ELIOMREGSIG
  include Eliom_mkforms.ELIOMFORMSIG
end

let code_of_code_option = function
  | None -> 200
  | Some c -> c

module Xhtmlreg_(Xhtml_content : Ocsigen_http_frame.HTTP_CONTENT
                   with type t = [ `Html ] XHTML.M.elt) = struct
  open XHTML.M
  open Xhtmltypes

  type page = xhtml elt

  type options = unit

  module Xhtml_content = struct

    include Xhtml_content

    let add_css (a : 'a) : 'a =
      let css =
        XHTML.M.toelt
          (XHTML.M.style ~contenttype:"text/css"
             [XHTML.M.pcdata "\n.eliom_inline {display: inline}\n.eliom_nodisplay {display: none}\n"])
      in
      let rec aux = function
        | (XML.Element ("head",al,el))::l -> (XML.Element ("head",al,css::el))::l
        | (XML.BlockElement ("head",al,el))::l ->
            (XML.BlockElement ("head",al,css::el))::l
        | (XML.SemiBlockElement ("head",al,el))::l ->
            (XML.SemiBlockElement ("head",al,css::el))::l
        | (XML.Node ("head",al,el))::l -> (XML.Node ("head",al,css::el))::l
        | e::l -> e::(aux l)
        | [] -> []
      in
      XHTML.M.tot
        (match XHTML.M.toelt a with
           | XML.Element ("html",al,el) -> XML.Element ("html",al,aux el)
           | XML.BlockElement ("html",al,el) -> XML.BlockElement ("html",al,aux el)
           | XML.SemiBlockElement ("html",al,el) ->
               XML.SemiBlockElement ("html",al,aux el)
           | XML.Node ("html",al,el) -> XML.Node ("html",al,aux el)
           | e -> e)

    let get_etag c = get_etag (add_css c)

    let result_of_content c = result_of_content (add_css c)

  end

  let send ?options ?(cookies=[]) ?charset ?code ~sp content =
    Xhtml_content.result_of_content content >>= fun r ->
      Lwt.return
        (EliomResult
           {r with
            res_cookies=
            Eliom_services.cookie_table_of_eliom_cookies ~sp cookies;
            res_code= code_of_code_option code;
            res_charset= (match charset with
            | None -> Some (get_config_file_charset sp)
            | _ -> charset)
          })

end

module Xhtmlforms_ = struct
  open XHTML.M
  open Xhtmltypes

  type form_content_elt = form_content elt
  type form_content_elt_list = form_content elt list
  type uri = XHTML.M.uri

  type a_content_elt = a_content elt
  type a_content_elt_list = a_content elt list

  type div_content_elt = div_content elt
  type div_content_elt_list = div_content elt list

  type a_elt = a elt
  type a_elt_list = a elt list
  type form_elt = form elt

  type textarea_elt = textarea elt
  type input_elt = input elt

  type link_elt = link elt
  type script_elt = script elt

  type pcdata_elt = pcdata elt

  type select_elt = select elt
  type select_content_elt = select_content elt
  type select_content_elt_list = select_content elt list
  type option_elt = selectoption elt
  type option_elt_list = selectoption elt list

  type button_elt = button elt
  type button_content_elt = button_content elt
  type button_content_elt_list = button_content elt list

  type a_attrib_t = Xhtmltypes.a_attrib XHTML.M.attrib list
  type form_attrib_t = Xhtmltypes.form_attrib XHTML.M.attrib list
  type input_attrib_t = Xhtmltypes.input_attrib XHTML.M.attrib list
  type textarea_attrib_t = Xhtmltypes.textarea_attrib XHTML.M.attrib list
  type select_attrib_t = Xhtmltypes.select_attrib XHTML.M.attrib list
  type link_attrib_t = Xhtmltypes.link_attrib XHTML.M.attrib list
  type script_attrib_t = Xhtmltypes.script_attrib XHTML.M.attrib list
  type optgroup_attrib_t = [ common | `Disabled ] XHTML.M.attrib list
  type option_attrib_t = Xhtmltypes.option_attrib XHTML.M.attrib list
  type button_attrib_t = Xhtmltypes.button_attrib XHTML.M.attrib list

  type input_type_t =
      [ `Button
    | `Checkbox
    | `File
    | `Hidden
    | `Image
    | `Password
    | `Radio
    | `Reset
    | `Submit
    | `Text ]

  type button_type_t =
      [ `Button | `Reset | `Submit ]

  let hidden = `Hidden
  let checkbox = `Checkbox
  let radio = `Radio
  let submit = `Submit
  let file = `File
  let image = `Image

  let buttonsubmit = `Submit

  let uri_of_string = XHTML.M.uri_of_string

  let empty_seq = []
  let cons_form a l = a::l

  let map_option = List.map
  let map_optgroup f a l = ((f a), List.map f l)
  let select_content_of_option a = (a :> select_content_elt)

  let make_pcdata s = pcdata s

  let make_a ?(a=[]) ~href l : a_elt =
    XHTML.M.a ~a:((a_href (uri_of_string href))::a) l

  let make_get_form ?(a=[]) ~action elt1 elts : form_elt =
    form ~a:((a_method `Get)::a)
      ~action:(uri_of_string action) elt1 elts

  let make_post_form ?(a=[]) ~action ?id ?(inline = false) elt1 elts
      : form_elt =
    let aa = (match id with
    | None -> a
    | Some i -> (a_id i)::a)
    in
    form ~a:((XHTML.M.a_enctype "multipart/form-data")::
             (* Always Multipart!!! How to test if there is a file?? *)
             (a_method `Post)::
             (if inline then (a_class ["inline"])::aa else aa))
      ~action:(uri_of_string action) elt1 elts

  let make_hidden_field content =
    let c = match content with
      | None -> []
      | Some c -> [c]
    in
    (div ~a:[a_class ["eliom_nodisplay"]] c :> form_content_elt)

  let make_empty_form_content () = p [pcdata ""] (**** � revoir !!!!! *)

  let remove_first = function
    | a::l -> a,l
    | [] -> (make_empty_form_content ()), []

  let make_input ?(a=[]) ?(checked=false) ~typ ?name ?src ?value () =
    let a2 = match value with
    | None -> a
    | Some v -> (a_value v)::a
    in
    let a2 = match name with
    | None -> a2
    | Some v -> (a_name v)::a2
    in
    let a2 = match src with
    | None -> a2
    | Some v -> (a_src v)::a2
    in
    let a2 = if checked then (a_checked `Checked)::a2 else a2 in
    input ~a:((a_input_type typ)::a2) ()

  let make_button ?(a = []) ~button_type ?name ?value c =
    let a = match value with
    | None -> a
    | Some v -> (a_value v)::a
    in
    let a = match name with
    | None -> a
    | Some v -> (a_name v)::a
    in
    button ~a:((a_button_type button_type)::a) c

  let make_textarea ?(a=[]) ~name ?(value=pcdata "") ~rows ~cols () =
    let a3 = (a_name name)::a in
    textarea ~a:a3 ~rows ~cols value

  let make_select ?(a=[]) ~multiple ~name elt elts =
    let a = if multiple then (a_multiple `Multiple)::a else a in
    select ~a:((a_name name)::a) elt elts

  let make_option ?(a=[]) ~selected ?value c =
    let a = match value with
    | None -> a
    | Some v -> (a_value v)::a
    in
    let a = if selected then (a_selected `Selected)::a else a in
    option ~a c

  let make_optgroup ?(a=[]) ~label elt elts =
    optgroup ~label ~a elt elts

  let make_css_link ?(a=[]) ~uri () =
    link ~a:((a_href uri)::
             (a_type "text/css")::(a_rel [`Stylesheet])::a) ()

  let make_js_script ?(a=[]) ~uri () =
    script ~a:((a_src uri)::a) ~contenttype:"text/javascript" (pcdata "")

end



(*****************************************************************************)
(*****************************************************************************)

module Xhtmlforms' = MakeForms(Xhtmlforms_)
module Xhtmlreg = MakeRegister(Xhtmlreg_(Ocsigen_senders.Xhtml_content))
module Xhtmlcompactreg =
  MakeRegister(Xhtmlreg_(Ocsigen_senders.Xhtmlcompact_content))

module type XHTMLFORMSSIG = sig
(* Pasted from mli *)




  open XHTML.M
  open Xhtmltypes

(** {2 Links and forms} *)

    val make_full_string_uri :
      ?https:bool ->
      service:('get, unit, [< get_service_kind ],
               [< suff ], 'gn, unit,
               [< registrable ]) service ->
      sp:Eliom_sessions.server_params ->
      ?fragment:string ->
      'get -> 
      string
(** Creates the string corresponding to the
    full (absolute) URL of a service applied to its GET parameters.
 *)

    val make_full_uri :
      ?https:bool ->
      service:('get, unit, [< get_service_kind ],
               [< suff ], 'gn, unit,
               [< registrable ]) service ->
      sp:Eliom_sessions.server_params ->
      ?fragment:string ->
      'get -> 
      XHTML.M.uri
(** Creates the string corresponding to the
    full (absolute) URL of a service applied to its GET parameters.
 *)

    val make_string_uri :
      ?https:bool ->
      service:('get, unit, [< get_service_kind ],
               [< suff ], 'gn, unit,
               [< registrable ]) service ->
      sp:Eliom_sessions.server_params ->
      ?fragment:string ->
      'get -> 
      string
(** Creates the string corresponding to the relative URL of a service applied to
   its GET parameters.
 *)

  val make_uri :
    ?https:bool ->
    service:('get, unit, [< get_service_kind ],
             [< suff ], 'gn, unit,
             [< registrable ]) service ->
    sp:Eliom_sessions.server_params -> 
    ?fragment:string -> 
    'get -> 
    uri
(** Create the text of the service. Like the [a] function, it may take
   extra parameters. *)

  val a :
    ?https:bool ->
    ?a:a_attrib attrib list ->
    service:
      ('get, unit, [< get_service_kind ],
       [< suff ], 'gn, 'pn,
       [< registrable ]) service ->
    sp:Eliom_sessions.server_params -> 
    ?fragment:string ->
    a_content elt list -> 
    'get -> 
    [> a] XHTML.M.elt
(** [a service sp cont ()] creates a link to [service].
   The text of
   the link is [cont]. For example [cont] may be something like
   [[pcdata "click here"]].

   The last  parameter is for GET parameters.
   For example [a service sp cont (42,"hello")]

   The [~a] optional parameter is used for extra attributes
   (see the module XHTML.M).

   The [~fragment] optional parameter is used for the "fragment" part
   of the URL, that is, the part after character "#".
 *)

  val css_link : ?a:(link_attrib attrib list) ->
    uri:uri -> unit ->[> link ] elt
(** Creates a [<link>] tag for a Cascading StyleSheet (CSS). *)

  val js_script : ?a:(script_attrib attrib list) ->
    uri:uri -> unit -> [> script ] elt
(** Creates a [<script>] tag to add a javascript file *)



    val get_form :
      ?https:bool ->
      ?a:form_attrib attrib list ->
      service:('get, unit, [< get_service_kind ],
               [<suff ], 'gn, 'pn,
               [< registrable ]) service ->
      sp:Eliom_sessions.server_params -> 
      ?fragment:string ->
      ('gn -> form_content elt list) -> 
      [>form] elt
(** [get_form service sp formgen] creates a GET form to [service].
   The content of
   the form is generated by the function [formgen], that takes the names
   of the service parameters as parameters. *)

    val post_form :
      ?https:bool ->
      ?a:form_attrib attrib list ->
      service:('get, 'post, [< post_service_kind ],
               [< suff ], 'gn, 'pn,
               [< registrable ]) service ->
      sp:Eliom_sessions.server_params ->
      ?fragment:string ->
      ?keep_get_na_params:bool ->
      ('pn -> form_content elt list) ->
      'get ->
      [>form] elt
(** [post_form service sp formgen] creates a POST form to [service].
   The last parameter is for GET parameters (as in the function [a]).
 *)

(** {2 Form widgets} *)

  type basic_input_type =
      [
    | `Hidden
    | `Password
    | `Submit
    | `Text ]

  val int_input :
      ?a:input_attrib attrib list -> input_type:[< basic_input_type ] ->
        ?name:[< int setoneradio ] param_name ->
          ?value:int -> unit -> [> input ] elt
(** Creates an [<input>] tag for an integer *)

  val int32_input :
      ?a:input_attrib attrib list -> input_type:[< basic_input_type ] ->
        ?name:[< int32 setoneradio ] param_name ->
          ?value:int32 -> unit -> [> input ] elt
(** Creates an [<input>] tag for a 32 bits integer *)

  val int64_input :
      ?a:input_attrib attrib list -> input_type:[< basic_input_type ] ->
        ?name:[< int64 setoneradio ] param_name ->
          ?value:int64 -> unit -> [> input ] elt
(** Creates an [<input>] tag for a 64 bits integer *)

  val float_input :
      ?a:input_attrib attrib list -> input_type:[< basic_input_type ] ->
        ?name:[< float setoneradio ] param_name ->
          ?value:float -> unit -> [> input ] elt
(** Creates an [<input>] tag for a float *)

  val string_input :
      ?a:input_attrib attrib list -> input_type:[< basic_input_type ] ->
        ?name:[< string setoneradio ] param_name ->
          ?value:string -> unit -> [> input ] elt
(** Creates an [<input>] tag for a string *)

  val user_type_input :
      ?a:input_attrib attrib list -> input_type:[< basic_input_type ] ->
        ?name:[< 'a setoneradio ] param_name ->
          ?value:'a -> ('a -> string) -> [> input ] elt
(** Creates an [<input>] tag for a user type *)

  val raw_input :
      ?a:input_attrib attrib list ->
        input_type:[< basic_input_type | `Reset | `Button ] ->
        ?name:string -> ?value:string -> unit -> [> input ] elt
(** Creates an untyped [<input>] tag. You may use the name you want
   (for example to use with {!Eliom_parameters.any}).
 *)

  val file_input :
      ?a:input_attrib attrib list ->
        name:[< file_info setoneradio ] param_name ->
          unit -> [> input ] elt
(** Creates an [<input>] tag for sending a file *)

  val image_input :
      ?a:input_attrib attrib list ->
        name:[< coordinates oneradio ] param_name ->
          ?src:uri -> unit -> [> input ] elt
(** Creates an [<input type="image" name="...">] tag that sends the coordinates
   the user clicked on *)

  val int_image_input :
      ?a:input_attrib attrib list ->
        name:[< (int * coordinates) oneradio ] param_name -> value:int ->
          ?src:uri -> unit -> [> input ] elt
(** Creates an [<input type="image" name="..." value="...">] tag that sends
   the coordinates the user clicked on and a value of type int *)

  val int32_image_input :
      ?a:input_attrib attrib list ->
        name:[< (int32 * coordinates) oneradio ] param_name -> value:int32 ->
          ?src:uri -> unit -> [> input ] elt
(** Creates an [<input type="image" name="..." value="...">] tag that sends
   the coordinates the user clicked on and a value of type int32 *)

  val int64_image_input :
      ?a:input_attrib attrib list ->
        name:[< (int64 * coordinates) oneradio ] param_name -> value:int64 ->
          ?src:uri -> unit -> [> input ] elt
(** Creates an [<input type="image" name="..." value="...">] tag that sends
   the coordinates the user clicked on and a value of type int64 *)

  val float_image_input :
      ?a:input_attrib attrib list ->
        name:[< (float * coordinates) oneradio ] param_name -> value:float ->
          ?src:uri -> unit -> [> input ] elt
(** Creates an [<input type="image" name="..." value="...">] tag that sends
    the coordinates the user clicked on and a value of type float *)

  val string_image_input :
      ?a:input_attrib attrib list ->
        name:[< (string * coordinates) oneradio ] param_name -> value:string ->
          ?src:uri -> unit -> [> input ] elt
(** Creates an [<input type="image" name="..." value="...">] tag that sends
   the coordinates the user clicked on and a value of type string *)

  val user_type_image_input :
      ?a:input_attrib attrib list ->
        name:[< ('a * coordinates) oneradio ] param_name -> value:'a ->
          ?src:uri -> ('a -> string) -> [> input ] elt
(** Creates an [<input type="image" name="..." value="...">] tag that sends
   the coordinates the user clicked on and a value of user defined type *)

  val raw_image_input :
      ?a:input_attrib attrib list ->
        name:string -> value:string -> ?src:uri -> unit -> [> input ] elt
(** Creates an [<input type="image" name="..." value="...">] tag that sends
   the coordinates the user clicked on and an untyped value *)


  val bool_checkbox :
      ?a:input_attrib attrib list -> ?checked:bool ->
        name:[ `One of bool ] param_name -> unit -> [> input ] elt
(** Creates a checkbox [<input>] tag that will have a boolean value.
   The service must declare a [bool] parameter.
 *)

    val int_checkbox :
        ?a:input_attrib attrib list -> ?checked:bool ->
          name:[ `Set of int ] param_name -> value:int ->
            unit -> [> input ] elt
(** Creates a checkbox [<input>] tag that will have an int value.
   Thus you can do several checkboxes with the same name
   (and different values).
   The service must declare a parameter of type [set].
 *)

    val int32_checkbox :
        ?a:input_attrib attrib list -> ?checked:bool ->
          name:[ `Set of int32 ] param_name -> value:int32 ->
            unit -> [> input ] elt
(** Creates a checkbox [<input>] tag that will have an int32 value.
   Thus you can do several checkboxes with the same name
   (and different values).
   The service must declare a parameter of type [set].
 *)

    val int64_checkbox :
        ?a:input_attrib attrib list -> ?checked:bool ->
          name:[ `Set of int64 ] param_name -> value:int64 ->
            unit -> [> input ] elt
(** Creates a checkbox [<input>] tag that will have an int64 value.
   Thus you can do several checkboxes with the same name
   (and different values).
   The service must declare a parameter of type [set].
 *)

    val float_checkbox :
        ?a:input_attrib attrib list -> ?checked:bool ->
          name:[ `Set of float ] param_name -> value:float ->
            unit -> [> input ] elt
(** Creates a checkbox [<input>] tag that will have a float value.
   Thus you can do several checkboxes with the same name
   (and different values).
   The service must declare a parameter of type [set].
 *)


    val string_checkbox :
        ?a:input_attrib attrib list -> ?checked:bool ->
          name:[ `Set of string ] param_name -> value:string ->
            unit -> [> input ] elt
(** Creates a checkbox [<input>] tag that will have a string value.
   Thus you can do several checkboxes with the same name
   (and different values).
   The service must declare a parameter of type [set].
 *)


    val user_type_checkbox :
        ?a:input_attrib attrib list -> ?checked:bool ->
          name:[ `Set of 'a ] param_name -> value:'a ->
            ('a -> string) -> [> input ] elt
(** Creates a checkbox [<input>] tag that will have a "user type" value.
   Thus you can do several checkboxes with the same name
   (and different values).
   The service must declare a parameter of type [set].
 *)


    val raw_checkbox :
        ?a:input_attrib attrib list -> ?checked:bool ->
          name:string -> value:string -> unit -> [> input ] elt
(** Creates a checkbox [<input>] tag with untyped content.
   Thus you can do several checkboxes with the same name
   (and different values).
   The service must declare a parameter of type [any].
 *)




  val string_radio : ?a:(input_attrib attrib list ) -> ?checked:bool ->
    name:[ `Radio of string ] param_name -> value:string -> unit -> [> input ] elt
(** Creates a radio [<input>] tag with string content *)

  val int_radio : ?a:(input_attrib attrib list ) -> ?checked:bool ->
     name:[ `Radio of int ] param_name -> value:int -> unit -> [> input ] elt
(** Creates a radio [<input>] tag with int content *)

  val int32_radio : ?a:(input_attrib attrib list ) -> ?checked:bool ->
     name:[ `Radio of int32 ] param_name -> value:int32 -> unit -> [> input ] elt
(** Creates a radio [<input>] tag with int32 content *)

  val int64_radio : ?a:(input_attrib attrib list ) -> ?checked:bool ->
     name:[ `Radio of int64 ] param_name -> value:int64 -> unit -> [> input ] elt
(** Creates a radio [<input>] tag with int64 content *)

  val float_radio : ?a:(input_attrib attrib list ) -> ?checked:bool ->
     name:[ `Radio of float ] param_name -> value:float -> unit -> [> input ] elt
(** Creates a radio [<input>] tag with float content *)

  val user_type_radio : ?a:(input_attrib attrib list ) -> ?checked:bool ->
    name:[ `Radio of 'a ] param_name -> value:'a -> ('a -> string) -> [> input ] elt
(** Creates a radio [<input>] tag with user_type content *)

  val raw_radio : ?a:(input_attrib attrib list ) -> ?checked:bool ->
    name:string -> value:string -> unit -> [> input ] elt
(** Creates a radio [<input>] tag with untyped string content (low level) *)


  type button_type =
      [ `Button | `Reset | `Submit ]

  val string_button : ?a:button_attrib attrib list ->
    name:[< string setone ] param_name -> value:string ->
      button_content elt list -> [> button ] elt
(** Creates a [<button>] tag with string content *)

  val int_button : ?a:button_attrib attrib list ->
    name:[< int setone ] param_name -> value:int ->
      button_content elt list -> [> button ] elt
(** Creates a [<button>] tag with int content *)

  val int32_button : ?a:button_attrib attrib list ->
    name:[< int32 setone ] param_name -> value:int32 ->
      button_content elt list -> [> button ] elt
(** Creates a [<button>] tag with int32 content *)

  val int64_button : ?a:button_attrib attrib list ->
    name:[< int64 setone ] param_name -> value:int64 ->
      button_content elt list -> [> button ] elt
(** Creates a [<button>] tag with int64 content *)

  val float_button : ?a:button_attrib attrib list ->
    name:[< float setone ] param_name -> value:float ->
      button_content elt list -> [> button ] elt
(** Creates a [<button>] tag with float content *)

  val user_type_button : ?a:button_attrib attrib list ->
    name:[< 'a setone ] param_name -> value:'a -> ('a -> string) ->
      button_content elt list -> [> button ] elt
(** Creates a [<button>] tag with user_type content *)

  val raw_button : ?a:button_attrib attrib list ->
    button_type:[< button_type ] ->
      name:string -> value:string ->
        button_content elt list -> [> button ] elt
(** Creates a [<button>] tag with untyped string content *)

  val button : ?a:button_attrib attrib list ->
    button_type:[< button_type ] ->
      button_content elt list -> [> button ] elt
(** Creates a [<button>] tag with no value. No value is sent. *)



  val textarea :
      ?a:textarea_attrib attrib list ->
        name:[< string setoneradio ] param_name ->
          ?value:Xhtmltypes.pcdata XHTML.M.elt ->
            rows:int -> cols:int ->
              unit -> [> textarea ] elt
(** Creates a [<textarea>] tag *)

  val raw_textarea :
      ?a:textarea_attrib attrib list ->
        name:string ->
          ?value:Xhtmltypes.pcdata XHTML.M.elt ->
            rows:int -> cols:int ->
              unit -> [> textarea ] elt
(** Creates a [<textarea>] tag for untyped form *)

  type 'a soption =
      Xhtmltypes.option_attrib XHTML.M.attrib list
        * 'a (* Value to send *)
        * pcdata elt option (* Text to display (if different from the latter) *)
        * bool (* selected *)

  type 'a select_opt =
    | Optgroup of
        [ common | `Disabled ] XHTML.M.attrib list
          * string (* label *)
          * 'a soption
          * 'a soption list
    | Option of 'a soption

  (** The type for [<select>] options and groups of options.
     - The field of type 'a in [soption] is the value that will be sent
     by the form.
     - If the [pcdata elt option] is not present it is also the
     value displayed.
     - The string in [select_opt] is the label
   *)

  val int_select :
      ?a:select_attrib attrib list ->
        name:[< `One of int ] param_name ->
          int select_opt ->
            int select_opt list ->
              [> select ] elt
(** Creates a [<select>] tag for int values. *)

  val int32_select :
      ?a:select_attrib attrib list ->
        name:[< `One of int32 ] param_name ->
          int32 select_opt ->
            int32 select_opt list ->
              [> select ] elt
(** Creates a [<select>] tag for int32 values. *)

  val int64_select :
      ?a:select_attrib attrib list ->
        name:[< `One of int64 ] param_name ->
          int64 select_opt ->
            int64 select_opt list ->
              [> select ] elt
(** Creates a [<select>] tag for int64 values. *)

  val float_select :
      ?a:select_attrib attrib list ->
        name:[< `One of float ] param_name ->
          float select_opt ->
            float select_opt list ->
              [> select ] elt
(** Creates a [<select>] tag for float values. *)

  val string_select :
      ?a:select_attrib attrib list ->
        name:[< `One of string ] param_name ->
          string select_opt ->
            string select_opt list ->
              [> select ] elt
(** Creates a [<select>] tag for string values. *)

  val user_type_select :
      ?a:select_attrib attrib list ->
        name:[< `One of 'a ] param_name ->
          'a select_opt ->
            'a select_opt list ->
              ('a -> string) ->
                [> select ] elt
(** Creates a [<select>] tag for user type values. *)

  val raw_select :
      ?a:select_attrib attrib list ->
        name:string ->
          string select_opt ->
            string select_opt list ->
              [> select ] elt
(** Creates a [<select>] tag for any (untyped) value. *)


  val int_multiple_select :
      ?a:select_attrib attrib list ->
        name:[< `Set of int ] param_name ->
          int select_opt ->
            int select_opt list ->
              [> select ] elt
(** Creates a [<select>] tag for int values. *)

  val int32_multiple_select :
      ?a:select_attrib attrib list ->
        name:[< `Set of int32 ] param_name ->
          int32 select_opt ->
            int32 select_opt list ->
              [> select ] elt
(** Creates a [<select>] tag for int32 values. *)

  val int64_multiple_select :
      ?a:select_attrib attrib list ->
        name:[< `Set of int64 ] param_name ->
          int64 select_opt ->
            int64 select_opt list ->
              [> select ] elt
(** Creates a [<select>] tag for int64 values. *)

  val float_multiple_select :
      ?a:select_attrib attrib list ->
        name:[< `Set of float ] param_name ->
          float select_opt ->
            float select_opt list ->
              [> select ] elt
(** Creates a [<select>] tag for float values. *)

  val string_multiple_select :
      ?a:select_attrib attrib list ->
        name:[< `Set of string ] param_name ->
          string select_opt ->
            string select_opt list ->
              [> select ] elt
(** Creates a [<select>] tag for string values. *)

  val user_type_multiple_select :
      ?a:select_attrib attrib list ->
        name:[< `Set of 'a ] param_name ->
          'a select_opt ->
            'a select_opt list ->
              ('a -> string) ->
                [> select ] elt
(** Creates a [<select>] tag for user type values. *)

  val raw_multiple_select :
      ?a:select_attrib attrib list ->
        name:string ->
          string select_opt ->
            string select_opt list ->
              [> select ] elt
(** Creates a [<select>] tag for any (untyped) value. *)


end


module Xhtmlforms : XHTMLFORMSSIG = struct

  open XHTML.M
  open Xhtmltypes
  include Xhtmlforms'

(* As we want -> [> a ] elt and not -> [ a ] elt (etc.),
   we define a new module: *)
  let a = (a :
      ?https:bool ->
      ?a:a_attrib attrib list ->
        service:('get, unit, [< get_service_kind ],
         [< suff ], 'gn, 'pn,
         [< registrable ]) service ->
           sp:server_params -> ?fragment:string ->
             a_content elt list -> 'get ->
             a XHTML.M.elt :>
      ?https:bool ->
      ?a:a_attrib attrib list ->
        service:('get, unit, [< get_service_kind ],
         [< suff ], 'gn, 'pn,
         [< registrable ]) service ->
           sp:server_params -> ?fragment:string ->
             a_content elt list -> 'get ->
             [> a] XHTML.M.elt)

  let css_link = (css_link :
                    ?a:(link_attrib attrib list) ->
                      uri:uri -> unit -> link elt :>
                    ?a:(link_attrib attrib list) ->
                      uri:uri -> unit -> [> link ] elt)

  let js_script = (js_script :
                     ?a:(script_attrib attrib list) ->
                       uri:uri -> unit -> script elt :>
                     ?a:(script_attrib attrib list) ->
                       uri:uri -> unit -> [> script ] elt)

  let make_uri = (make_uri :
      ?https:bool ->
      service:('get, unit, [< get_service_kind ],
       [< suff ], 'gn, unit,
       [< registrable ]) service ->
         sp:server_params -> ?fragment:string -> 'get -> uri)

  let get_form = (get_form :
      ?https:bool ->
      ?a:form_attrib attrib list ->
        service:('get, unit, [< get_service_kind ],
         [<suff ], 'gn, 'pn,
         [< registrable ]) service ->
           sp:server_params -> ?fragment:string ->
             ('gn -> form_content elt list) -> form elt :>
      ?https:bool ->
      ?a:form_attrib attrib list ->
        service:('get, unit, [< get_service_kind ],
         [<suff ], 'gn, 'pn,
         [< registrable ]) service ->
           sp:server_params -> ?fragment:string ->
             ('gn -> form_content elt list) -> [> form ] elt)

  let post_form = (post_form :
                     ?https:bool ->
                    ?a:form_attrib attrib list ->
                    service:('get, 'post, [< post_service_kind ],
                             [< suff ], 'gn, 'pn,
                             [< registrable ]) service ->
                    sp:server_params ->
                    ?fragment:string ->
                    ?keep_get_na_params:bool ->
                    ('pn -> form_content elt list) -> 'get -> form elt :>
                    ?https:bool ->
                    ?a:form_attrib attrib list ->
                    service:('get, 'post, [< post_service_kind ],
                             [< suff ], 'gn, 'pn,
                             [< registrable ]) service ->
                    sp:server_params ->
                    ?fragment:string ->
                    ?keep_get_na_params:bool ->
                    ('pn -> form_content elt list) -> 'get -> [> form ] elt)

  type basic_input_type =
      [
    | `Hidden
    | `Password
    | `Submit
    | `Text ]

  type full_input_type =
    [ `Button
    | `Checkbox
    | `File
    | `Hidden
    | `Image
    | `Password
    | `Radio
    | `Reset
    | `Submit
    | `Text ]

  let int_input = (int_input :
      ?a:input_attrib attrib list -> input_type:full_input_type ->
        ?name:'a -> ?value:int -> unit -> input elt :>
      ?a:input_attrib attrib list -> input_type:[< basic_input_type] ->
        ?name:'a -> ?value:int -> unit -> [> input ] elt)

  let int32_input = (int32_input :
      ?a:input_attrib attrib list -> input_type:full_input_type ->
        ?name:'a -> ?value:int32 -> unit -> input elt :>
      ?a:input_attrib attrib list -> input_type:[< basic_input_type] ->
        ?name:'a -> ?value:int32 -> unit -> [> input ] elt)

  let int64_input = (int64_input :
      ?a:input_attrib attrib list -> input_type:full_input_type ->
        ?name:'a -> ?value:int64 -> unit -> input elt :>
      ?a:input_attrib attrib list -> input_type:[< basic_input_type] ->
        ?name:'a -> ?value:int64 -> unit -> [> input ] elt)

  let float_input = (float_input :
      ?a:input_attrib attrib list -> input_type:full_input_type ->
        ?name:'a -> ?value:float -> unit -> input elt :>
      ?a:input_attrib attrib list -> input_type:[< basic_input_type] ->
        ?name:'a -> ?value:float -> unit -> [> input ] elt)

  let string_input = (string_input :
      ?a:input_attrib attrib list -> input_type:full_input_type ->
        ?name:'a -> ?value:string -> unit -> input elt :>
      ?a:input_attrib attrib list -> input_type:[< basic_input_type] ->
        ?name:'a -> ?value:string -> unit -> [> input ] elt)

  let user_type_input = (user_type_input :
      ?a:input_attrib attrib list -> input_type:full_input_type ->
        ?name:'b -> ?value:'a -> ('a -> string) -> input elt :>
      ?a:input_attrib attrib list -> input_type:[< basic_input_type] ->
        ?name:'b -> ?value:'a -> ('a -> string) -> [> input ] elt)

  let raw_input = (raw_input :
      ?a:input_attrib attrib list -> input_type:full_input_type ->
        ?name:string -> ?value:string -> unit -> input elt :>
      ?a:input_attrib attrib list ->
        input_type:[< basic_input_type | `Button | `Reset ] ->
        ?name:string -> ?value:string -> unit -> [> input ] elt)

  let file_input = (file_input :
      ?a:input_attrib attrib list -> name:'a ->
        unit -> input elt :>
      ?a:input_attrib attrib list -> name:'a ->
        unit -> [> input ] elt)

  let image_input = (image_input :
      ?a:input_attrib attrib list -> name:'a ->
        ?src:uri -> unit -> input elt :>
      ?a:input_attrib attrib list -> name:'a ->
        ?src:uri -> unit -> [> input ] elt)

  let int_image_input = (int_image_input :
      ?a:input_attrib attrib list ->
        name:'a -> value:int ->
          ?src:uri -> unit -> input elt :>
      ?a:input_attrib attrib list ->
        name:'a -> value:int ->
          ?src:uri -> unit -> [> input ] elt)

  let int32_image_input = (int32_image_input :
      ?a:input_attrib attrib list ->
        name:'a -> value:int32 ->
          ?src:uri -> unit -> input elt :>
      ?a:input_attrib attrib list ->
        name:'a -> value:int32 ->
          ?src:uri -> unit -> [> input ] elt)

  let int64_image_input = (int64_image_input :
      ?a:input_attrib attrib list ->
        name:'a -> value:int64 ->
          ?src:uri -> unit -> input elt :>
      ?a:input_attrib attrib list ->
        name:'a -> value:int64 ->
          ?src:uri -> unit -> [> input ] elt)

  let float_image_input = (float_image_input :
      ?a:input_attrib attrib list ->
        name:'a -> value:float ->
          ?src:uri -> unit -> input elt :>
      ?a:input_attrib attrib list ->
        name:'a -> value:float ->
          ?src:uri -> unit -> [> input ] elt)

  let string_image_input = (string_image_input :
      ?a:input_attrib attrib list ->
        name:'a -> value:string ->
          ?src:uri -> unit -> input elt :>
      ?a:input_attrib attrib list ->
        name:'a -> value:string ->
          ?src:uri -> unit -> [> input ] elt)

  let user_type_image_input = (user_type_image_input :
      ?a:input_attrib attrib list ->
        name:'b -> value:'a ->
          ?src:uri -> ('a -> string) -> input elt :>
      ?a:input_attrib attrib list ->
        name:'b -> value:'a ->
          ?src:uri -> ('a -> string) -> [> input ] elt)

  let raw_image_input = (raw_image_input :
      ?a:input_attrib attrib list ->
        name:string -> value:string -> ?src:uri -> unit -> input elt :>
      ?a:input_attrib attrib list ->
        name:string -> value:string -> ?src:uri -> unit -> [> input ] elt)

  let bool_checkbox = (bool_checkbox :
      ?a:(input_attrib attrib list ) -> ?checked:bool ->
        name:'a -> unit -> input elt :>
      ?a:(input_attrib attrib list ) -> ?checked:bool ->
        name:'a -> unit -> [> input ] elt)

  let int_checkbox = (int_checkbox :
      ?a:input_attrib attrib list -> ?checked:bool ->
        name:[ `Set of int ] param_name -> value:int -> unit -> input elt :>
      ?a:input_attrib attrib list -> ?checked:bool ->
        name:[ `Set of int ] param_name -> value:int -> unit -> [> input ] elt)

  let int32_checkbox = (int32_checkbox :
      ?a:input_attrib attrib list -> ?checked:bool ->
        name:[ `Set of int32 ] param_name -> value:int32 -> unit -> input elt :>
      ?a:input_attrib attrib list -> ?checked:bool ->
        name:[ `Set of int32 ] param_name -> value:int32 -> unit -> [> input ] elt)

  let int64_checkbox = (int64_checkbox :
      ?a:input_attrib attrib list -> ?checked:bool ->
        name:[ `Set of int64 ] param_name -> value:int64 -> unit -> input elt :>
      ?a:input_attrib attrib list -> ?checked:bool ->
        name:[ `Set of int64 ] param_name -> value:int64 -> unit -> [> input ] elt)

  let float_checkbox = (float_checkbox :
      ?a:input_attrib attrib list -> ?checked:bool ->
        name:[ `Set of float ] param_name -> value:float -> unit -> input elt :>
      ?a:input_attrib attrib list -> ?checked:bool ->
        name:[ `Set of float ] param_name -> value:float -> unit -> [> input ] elt)

  let string_checkbox = (string_checkbox :
      ?a:input_attrib attrib list -> ?checked:bool ->
        name:[ `Set of string ] param_name -> value:string -> unit -> input elt :>
      ?a:input_attrib attrib list -> ?checked:bool ->
        name:[ `Set of string ] param_name -> value:string -> unit -> [> input ] elt)

  let user_type_checkbox = (user_type_checkbox :
      ?a:input_attrib attrib list -> ?checked:bool ->
        name:[ `Set of 'a ] param_name -> value:'a -> ('a -> string) -> input elt :>
      ?a:input_attrib attrib list -> ?checked:bool ->
        name:[ `Set of 'a ] param_name -> value:'a -> ('a -> string) -> [> input ] elt)

  let raw_checkbox = (raw_checkbox :
      ?a:input_attrib attrib list -> ?checked:bool ->
        name:string -> value:string -> unit -> input elt :>
      ?a:input_attrib attrib list -> ?checked:bool ->
        name:string -> value:string -> unit -> [> input ] elt)


  let string_radio = (string_radio :
    ?a:(input_attrib attrib list ) -> ?checked:bool ->
      name:'a -> value:string -> unit -> input elt :>
    ?a:(input_attrib attrib list ) -> ?checked:bool ->
      name:'a -> value:string -> unit -> [> input ] elt)

  let int_radio = (int_radio :
                     ?a:(input_attrib attrib list ) -> ?checked:bool ->
     name:'a -> value:int -> unit -> input elt :>
                     ?a:(input_attrib attrib list ) -> ?checked:bool ->
     name:'a -> value:int -> unit -> [> input ] elt)

  let int32_radio = (int32_radio :
                     ?a:(input_attrib attrib list ) -> ?checked:bool ->
     name:'a -> value:int32 -> unit -> input elt :>
                     ?a:(input_attrib attrib list ) -> ?checked:bool ->
     name:'a -> value:int32 -> unit -> [> input ] elt)

  let int64_radio = (int64_radio :
                     ?a:(input_attrib attrib list ) -> ?checked:bool ->
     name:'a -> value:int64 -> unit -> input elt :>
                     ?a:(input_attrib attrib list ) -> ?checked:bool ->
     name:'a -> value:int64 -> unit -> [> input ] elt)

  let float_radio = (float_radio :
                       ?a:(input_attrib attrib list ) -> ?checked:bool ->
     name:'a -> value:float -> unit -> input elt :>
                       ?a:(input_attrib attrib list ) -> ?checked:bool ->
     name:'a -> value:float -> unit -> [> input ] elt)

  let user_type_radio = (user_type_radio :
                           ?a:(input_attrib attrib list ) -> ?checked:bool ->
    name:'b -> value:'a -> ('a -> string) -> input elt :>
                           ?a:(input_attrib attrib list ) -> ?checked:bool ->
    name:'b -> value:'a -> ('a -> string) -> [> input ] elt)

  let raw_radio = (raw_radio :
                     ?a:(input_attrib attrib list ) -> ?checked:bool ->
    name:string -> value:string -> unit -> input elt :>
                     ?a:(input_attrib attrib list ) -> ?checked:bool ->
    name:string -> value:string -> unit -> [> input ] elt)

  let textarea = (textarea :
        ?a:textarea_attrib attrib list ->
          name:'a -> ?value:Xhtmltypes.pcdata XHTML.M.elt ->
            rows:int -> cols:int ->
              unit -> textarea elt :>
        ?a:textarea_attrib attrib list ->
          name:'a -> ?value:Xhtmltypes.pcdata XHTML.M.elt ->
            rows:int -> cols:int ->
              unit -> [> textarea ] elt)

  let raw_textarea = (raw_textarea :
        ?a:textarea_attrib attrib list ->
          name:string -> ?value:Xhtmltypes.pcdata XHTML.M.elt ->
            rows:int -> cols:int ->
              unit -> textarea elt :>
        ?a:textarea_attrib attrib list ->
          name:string -> ?value:Xhtmltypes.pcdata XHTML.M.elt ->
            rows:int -> cols:int ->
              unit -> [> textarea ] elt)

  let raw_select = (raw_select :
        ?a:select_attrib attrib list ->
          name:string ->
            string select_opt ->
              string select_opt list -> select elt :>
       ?a:select_attrib attrib list ->
         name:string ->
           string select_opt ->
             string select_opt list -> [> select ] elt)

  let int_select = (int_select :
        ?a:select_attrib attrib list ->
          name:'a ->
            int select_opt ->
              int select_opt list -> select elt :>
       ?a:select_attrib attrib list ->
         name:'a ->
           int select_opt ->
             int select_opt list -> [> select ] elt)

  let int32_select = (int32_select :
        ?a:select_attrib attrib list ->
          name:'a ->
            int32 select_opt ->
              int32 select_opt list -> select elt :>
       ?a:select_attrib attrib list ->
         name:'a ->
           int32 select_opt ->
             int32 select_opt list -> [> select ] elt)

  let int64_select = (int64_select :
        ?a:select_attrib attrib list ->
          name:'a ->
            int64 select_opt ->
              int64 select_opt list -> select elt :>
       ?a:select_attrib attrib list ->
         name:'a ->
           int64 select_opt ->
             int64 select_opt list -> [> select ] elt)

  let float_select = (float_select :
        ?a:select_attrib attrib list ->
          name:'a ->
            float select_opt ->
              float select_opt list -> select elt :>
       ?a:select_attrib attrib list ->
         name:'a ->
           float select_opt ->
             float select_opt list -> [> select ] elt)

  let string_select = (string_select :
        ?a:select_attrib attrib list ->
          name:'a ->
            string select_opt ->
              string select_opt list -> select elt :>
       ?a:select_attrib attrib list ->
         name:'a ->
           string select_opt ->
             string select_opt list -> [> select ] elt)

  let user_type_select = (user_type_select :
        ?a:select_attrib attrib list ->
          name:'b ->
            'a select_opt ->
              'a select_opt list -> ('a -> string) -> select elt :>
       ?a:select_attrib attrib list ->
         name:'b ->
           'a select_opt ->
             'a select_opt list -> ('a -> string) -> [> select ] elt)


  let raw_multiple_select = (raw_multiple_select :
        ?a:select_attrib attrib list ->
          name:string ->
            string select_opt ->
              string select_opt list -> select elt :>
       ?a:select_attrib attrib list ->
         name:string ->
           string select_opt ->
             string select_opt list -> [> select ] elt)

  let int_multiple_select = (int_multiple_select :
        ?a:select_attrib attrib list ->
          name:'a ->
            int select_opt ->
              int select_opt list -> select elt :>
       ?a:select_attrib attrib list ->
         name:'a ->
           int select_opt ->
             int select_opt list -> [> select ] elt)

  let int32_multiple_select = (int32_multiple_select :
        ?a:select_attrib attrib list ->
          name:'a ->
            int32 select_opt ->
              int32 select_opt list -> select elt :>
       ?a:select_attrib attrib list ->
         name:'a ->
           int32 select_opt ->
             int32 select_opt list -> [> select ] elt)

  let int64_multiple_select = (int64_multiple_select :
        ?a:select_attrib attrib list ->
          name:'a ->
            int64 select_opt ->
              int64 select_opt list -> select elt :>
       ?a:select_attrib attrib list ->
         name:'a ->
           int64 select_opt ->
             int64 select_opt list -> [> select ] elt)

  let float_multiple_select = (float_multiple_select :
        ?a:select_attrib attrib list ->
          name:'a ->
            float select_opt ->
              float select_opt list -> select elt :>
       ?a:select_attrib attrib list ->
         name:'a ->
           float select_opt ->
             float select_opt list -> [> select ] elt)

  let string_multiple_select = (string_multiple_select :
        ?a:select_attrib attrib list ->
          name:'a ->
            string select_opt ->
              string select_opt list -> select elt :>
       ?a:select_attrib attrib list ->
         name:'a ->
           string select_opt ->
             string select_opt list -> [> select ] elt)

  let user_type_multiple_select = (user_type_multiple_select :
        ?a:select_attrib attrib list ->
          name:'b ->
            'a select_opt ->
              'a select_opt list -> ('a -> string) -> select elt :>
       ?a:select_attrib attrib list ->
         name:'b ->
           'a select_opt ->
             'a select_opt list -> ('a -> string) -> [> select ] elt)

  type button_type =
      [ `Button
    | `Reset
    | `Submit
      ]

  let string_button = (string_button :
       ?a:button_attrib attrib list ->
           name:'a -> value:string ->
             button_content elt list -> button elt :>
       ?a:button_attrib attrib list ->
           name:'a -> value:string ->
             button_content elt list -> [> button ] elt)

  let int_button = (int_button :
       ?a:button_attrib attrib list ->
           name:'a -> value:int ->
             button_content elt list -> button elt :>
       ?a:button_attrib attrib list ->
           name:'a -> value:int ->
             button_content elt list -> [> button ] elt)

  let int32_button = (int32_button :
       ?a:button_attrib attrib list ->
           name:'a -> value:int32 ->
             button_content elt list -> button elt :>
       ?a:button_attrib attrib list ->
           name:'a -> value:int32 ->
             button_content elt list -> [> button ] elt)

  let int64_button = (int64_button :
       ?a:button_attrib attrib list ->
           name:'a -> value:int64 ->
             button_content elt list -> button elt :>
       ?a:button_attrib attrib list ->
           name:'a -> value:int64 ->
             button_content elt list -> [> button ] elt)

  let float_button = (float_button :
       ?a:button_attrib attrib list ->
           name:'a -> value:float ->
             button_content elt list -> button elt :>
       ?a:button_attrib attrib list ->
           name:'a -> value:float ->
             button_content elt list -> [> button ] elt)

  let user_type_button = (user_type_button :
       ?a:button_attrib attrib list ->
           name:'b -> value:'a ->
             ('a -> string) ->
               button_content elt list -> button elt :>
       ?a:button_attrib attrib list ->
           name:'b -> value:'a ->
             ('a -> string) ->
               button_content elt list -> [> button ] elt)

  let raw_button = (raw_button :
       ?a:button_attrib attrib list ->
         button_type:button_type ->
           name:string -> value:string ->
             button_content elt list -> button elt :>
       ?a:button_attrib attrib list ->
         button_type:[< button_type ] ->
           name:string -> value:string ->
             button_content elt list -> [> button ] elt)

  let button = (button :
       ?a:button_attrib attrib list ->
         button_type:button_type ->
           button_content elt list -> button elt :>
       ?a:button_attrib attrib list ->
         button_type:[< button_type ] ->
           button_content elt list -> [> button ] elt)
end


module Xhtml = struct
  include Xhtmlforms
  include Xhtmlreg
end

module Xhtmlcompact = struct
  include Xhtmlforms
  include Xhtmlcompactreg
end

(****************************************************************************)
(****************************************************************************)
module SubXhtml = functor(T : sig type content end) ->
  (struct
(*    module Old_Cont_content =
      (* Pasted from ocsigen_senders.ml and modified *)
      struct
        type t = T.content XHTML.M.elt list

        let get_etag_aux x =
          Some (Digest.to_hex (Digest.string x))

        let get_etag c =
          let x = (Xhtmlpretty.ocsigen_xprint c) in
          get_etag_aux x

        let result_of_content c =
          let x = Xhtmlpretty.ocsigen_xprint c in
          let md5 = get_etag_aux x in
          let default_result = default_result () in
          Lwt.return
            {default_result with
             res_content_length = Some (Int64.of_int (String.length x));
             res_content_type = Some "text/html";
             res_etag = md5;
             res_headers= Http_headers.dyn_headers;
             res_stream =
             Ocsigen_stream.make
               (fun () -> Ocsigen_stream.cont x
                   (fun () -> Ocsigen_stream.empty None))
           }

      end *)

    module Cont_content =
      (* Pasted from ocsigen_senders.ml and modified *)
      struct
        type t = T.content XHTML.M.elt list

        let get_etag_aux x = None

        let get_etag c = None

        let result_of_content c =
          let x = Xhtmlpretty.xhtml_list_stream c in
          let default_result = default_result () in
          Lwt.return
            {default_result with
             res_content_length = None;
             res_content_type = Some "text/html";
             res_etag = get_etag c;
             res_headers= Http_headers.dyn_headers;
             res_stream = x
           }

      end

    module Contreg_ = struct
      open XHTML.M
      open Xhtmltypes

      type page = T.content XHTML.M.elt list

      type options = unit

      let send ?options ?(cookies=[]) ?charset ?code ~sp content =
        Cont_content.result_of_content content >>= fun r ->
        Lwt.return
            (EliomResult
               {r with
                res_cookies= Eliom_services.cookie_table_of_eliom_cookies ~sp cookies;
                res_code= code_of_code_option code;
                res_charset= (match charset with
                | None -> Some (get_config_file_charset sp)
                | _ -> charset);
              })

    end

    module Contreg = MakeRegister(Contreg_)

    include Xhtmlforms
    include Contreg

  end : sig

    include ELIOMREGSIG with type page = T.content XHTML.M.elt list
    include XHTMLFORMSSIG

  end)

module Blocks = SubXhtml(struct
  type content = Xhtmltypes.body_content
end)


(****************************************************************************)
(****************************************************************************)

module Textreg_ = struct
  open XHTML.M
  open Xhtmltypes

  type page = (string * string)

  type options = unit

  let send ?options ?(cookies=[]) ?charset ?code ~sp content =
    Ocsigen_senders.Text_content.result_of_content content >>= fun r ->
    Lwt.return
        (EliomResult
           {r with
            res_cookies= Eliom_services.cookie_table_of_eliom_cookies ~sp cookies;
            res_code= code_of_code_option code;
            res_charset= (match charset with
            | None -> Some (get_config_file_charset sp)
            | _ -> charset);
          })

end

module Text = MakeRegister(Textreg_)

(****************************************************************************)
(****************************************************************************)

module CssTextreg_ = struct
  open XHTML.M
  open Xhtmltypes

  type page = string

  type options = unit

  let send ?options ?(cookies=[]) ?charset ?code ~sp content =
    Ocsigen_senders.Text_content.result_of_content (content, "text/css") >>= fun r ->
    Lwt.return
        (EliomResult
           {r with
            res_cookies= Eliom_services.cookie_table_of_eliom_cookies ~sp cookies;
            res_code= code_of_code_option code;
            res_charset= (match charset with
            | None -> Some (get_config_file_charset sp)
            | _ -> charset);
          })

end

module CssText = MakeRegister(CssTextreg_)


(****************************************************************************)
(****************************************************************************)

module HtmlTextreg_ = struct
  open XHTML.M
  open Xhtmltypes

  type page = string

  type options = unit

  let send ?options ?(cookies=[]) ?charset ?code ~sp content =
    Ocsigen_senders.Text_content.result_of_content (content, "text/html") >>= fun r ->
    Lwt.return
        (EliomResult
           {r with
            res_cookies= Eliom_services.cookie_table_of_eliom_cookies ~sp cookies;
            res_code= code_of_code_option code;
            res_charset= (match charset with
            | None -> Some (get_config_file_charset sp)
            | _ -> charset);
          })

end

module HtmlTextforms_ = struct
  open XHTML.M
  open Xhtmltypes

  type form_content_elt = string
  type form_content_elt_list = string
  type uri = string
  type a_content_elt = string
  type a_content_elt_list = string
  type div_content_elt = string
  type div_content_elt_list = string

  type a_elt = string
  type a_elt_list = string
  type form_elt = string

  type textarea_elt = string
  type input_elt = string
  type select_elt = string
  type select_content_elt = string
  type select_content_elt_list = string
  type option_elt = string
  type option_elt_list = string
  type button_elt = string
  type button_content_elt = string
  type button_content_elt_list = string

  type link_elt = string
  type script_elt = string

  type pcdata_elt = string

  type a_attrib_t = string
  type form_attrib_t = string
  type input_attrib_t = string
  type textarea_attrib_t = string
  type select_attrib_t = string
  type link_attrib_t = string
  type script_attrib_t = string
  type optgroup_attrib_t = string
  type option_attrib_t = string
  type button_attrib_t = string

  type input_type_t = string
  type button_type_t = string

  let hidden = "hidden"
(*  let text = "text"
  let password = "password" *)
  let checkbox = "checkbox"
  let radio = "radio"
  let submit = "submit"
  let file = "file"
  let image = "image"

  let buttonsubmit = "submit"

  let uri_of_string x = x

  let empty_seq = ""
  let cons_form a l = a^l

  let map_option f =
    List.fold_left (fun d a -> d^(f a)) ""

  let map_optgroup f a l =
    ((f a), List.fold_left (fun d a -> d^(f a)) "" l)

  let select_content_of_option = id

  let make_pcdata = id

  let make_a ?(a="") ~href l : a_elt =
    "<a href=\""^href^"\""^a^">"^(* List.fold_left (^) "" l *) l^"</a>"

  let make_get_form ?(a="") ~action elt1 elts : form_elt =
    "<form method=\"get\" action=\""^(uri_of_string action)^"\""^a^">"^
    elt1^(*List.fold_left (^) "" elts *) elts^"</form>"

  let make_post_form ?(a="") ~action ?id ?(inline = false) elt1 elts
      : form_elt =
    let aa = "enctype=\"multipart/form-data\" "
        (* Always Multipart!!! How to test if there is a file?? *)
      ^(match id with
        None -> a
      | Some i -> " id="^i^" "^a)
    in
    "<form method=\"post\" action=\""^(uri_of_string action)^"\""^
    (if inline then "style=\"display: inline\"" else "")^aa^">"^
    elt1^(* List.fold_left (^) "" elts*) elts^"</form>"

  let make_hidden_field content =
    let content = match content with
      | None -> ""
      | Some c -> c
    in
    "<div style=\"display: none\""^content^"</div>"

  let remove_first l = "",l

  let make_input ?(a="") ?(checked=false) ~typ ?name ?src ?value () =
    let a2 = match value with
      None -> a
    | Some v -> " value="^v^" "^a
    in
    let a2 = match name with
      None -> a2
    | Some v -> " name="^v^" "^a2
    in
    let a2 = match src with
      None -> a2
    | Some v -> " src="^v^" "^a2
    in
    let a2 = if checked then " checked=\"checked\" "^a2 else a2 in
    "<input type=\""^typ^"\" "^a2^"/>"

  let make_button ?(a="") ~button_type ?name ?value c =
    let a2 = match value with
      None -> a
    | Some v -> " value="^v^" "^a
    in
    let a2 = match name with
      None -> a2
    | Some v -> " name="^v^" "^a2
    in
    "<button type=\""^button_type^"\" "^a2^">"^c^"</button>"

  let make_textarea ?(a="") ~name:name ?(value="") ~rows ~cols () =
    "<textarea name=\""^name^"\" rows=\""^(string_of_int rows)^
    "\" cols=\""^(string_of_int cols)^"\" "^a^">"^value^"</textarea>"

  let make_select ?(a="") ~multiple ~name elt elts =
    "<select "^(if multiple then "multiple=\"multiple\" " else "")^
    "name=\""^name^"\" "^a^">"^elt^elts^"</select>"

  let make_option ?(a="") ~selected ?value c =
    let a = match value with
      None -> a
    | Some v -> " value="^v^" "^a
    in
    "<option "^(if selected then "selected=\"selected\" " else "")^
    a^">"^c^"</option>"

  let make_optgroup ?(a="") ~label elt elts =
    "<optgroup label=\""^label^"\" "^
    a^">"^elt^elts^"</optgroup>"


  let make_css_link ?(a="") ~uri () =
    "<link href=\""^uri^" type=\"text/css\" rel=\"stylesheet\" "^a^"/>"

  let make_js_script ?(a="") ~uri () =
    "<script src=\""^uri^" contenttype=\"text/javascript\" "^a^"></script>"

end



(****************************************************************************)
(****************************************************************************)

module HtmlTextforms = MakeForms(HtmlTextforms_)
module HtmlTextreg = MakeRegister(HtmlTextreg_)

module HtmlText = struct
  include HtmlTextforms
  include HtmlTextreg
end


(****************************************************************************)
(****************************************************************************)

(** Actions are like services, but do not generate any page. The current
   page is reloaded (but if you give the optional parameter
    [~options:`NoReload] to the registration function).
 *)
module Actionreg_ = struct
  open XHTML.M
  open Xhtmltypes

  type page = exn list

  type options = [ `Reload | `NoReload ]

  let send
      ?(options = `Reload) ?(cookies=[]) ?charset ?(code = 204) ~sp content =
    if options = `NoReload
    then
      let empty_result = Ocsigen_http_frame.empty_result () in
      Lwt.return
        (EliomResult
           {empty_result with
            res_cookies=
            Eliom_services.cookie_table_of_eliom_cookies ~sp cookies;
            res_code= code;
          })
    else
      Lwt.return (EliomExn (content, cookies))

end

module Action = MakeRegister(Actionreg_)

module Actions = Action (* For backwards compatibility *)

(** Unit services are like services, do not generate any page, and do not
    reload the page. To be used carefully. Probably not usefull at all.
    (Same as {!Eliom_predefmod.Actions} with [`NoReload] option).
 *)
module Unitreg_ = struct
  open XHTML.M
  open Xhtmltypes

  type page = unit

  type options = unit

  let send ?options ?(cookies=[]) ?charset ?(code = 204) ~sp content =
    let empty_result = Ocsigen_http_frame.empty_result () in
    Lwt.return
      (EliomResult
         {empty_result with
          res_cookies=
          Eliom_services.cookie_table_of_eliom_cookies ~sp cookies;
          res_code= code;
        })

end


module Unit = MakeRegister(Unitreg_)


(** Redirection services are like services, but send a redirection instead
 of a page.

   The HTTP/1.1 RFC says:
   If the 301 status code is received in response to a request other than GET or HEAD, the user agent MUST NOT automatically redirect the request unless it can be confirmed by the user, since this might change the conditions under which the request was issued.

   Here redirections are done towards services without parameters.
   (possibly preapplied).

 *)
module String_redirreg_ = struct
  open XHTML.M
  open Xhtmltypes

  type page = XHTML.M.uri

  type options = [ `Temporary | `Permanent ]

  let send ?(options = `Permanent) ?(cookies=[]) ?charset ?code ~sp content =
    let empty_result = Ocsigen_http_frame.empty_result () in
    let code = match code with
    | Some c -> c
    | None ->
        if options = `Temporary
        then 307 (* Temporary move *)
        else 301 (* Moved permanently *)
    in
    Lwt.return
      (EliomResult
         {empty_result with
          res_cookies= Eliom_services.cookie_table_of_eliom_cookies ~sp cookies;
          res_code= code;
          res_location = Some (XHTML.M.string_of_uri content);
        })

end


module String_redirection = MakeRegister(String_redirreg_)

module Redirreg_ = struct
  open XHTML.M
  open Xhtmltypes

  type page = 
      (unit, unit, Eliom_services.get_service_kind,
       [ `WithoutSuffix ], 
       unit, unit, Eliom_services.registrable)
        Eliom_services.service

  type options = [ `Temporary | `Permanent ]

  let send ?(options = `Permanent) ?(cookies=[]) ?charset ?code ~sp content =
    let empty_result = Ocsigen_http_frame.empty_result () in
    let uri = Xhtml.make_full_string_uri ~sp ~service:content () in
    let code = match code with
    | Some c -> c
    | None ->
        if options = `Temporary
        then 307 (* Temporary move *)
        else 301 (* Moved permanently *)
    in
    Lwt.return
      (EliomResult
         {empty_result with
          res_cookies= Eliom_services.cookie_table_of_eliom_cookies ~sp cookies;
          res_code= code;
          res_location = Some uri;
        })

end


module Redirection = MakeRegister(Redirreg_)



(* Any is a module allowing to register services that decide themselves
   what they want to send.
 *)
module Anyreg_ = struct
  open XHTML.M
  open Xhtmltypes

  type page = Eliom_services.result_to_send

  type options = unit

  let send ?options ?(cookies=[]) ?charset ?code ~sp content =
    Lwt.return
      (match content with
      | EliomResult res ->
          EliomResult
            {res with
             res_cookies=
             Eliom_services.cookie_table_of_eliom_cookies
               ~oldtable:res.res_cookies
               ~sp
               cookies;
             res_charset= match charset with
             | None -> res.res_charset
             | _ -> charset
           }
      | EliomExn (e, c) ->
          EliomExn (e, cookies@c))

end

module Any = MakeRegister(Anyreg_)


(* Files is a module allowing to register services that send files *)
module Filesreg_ = struct
  open XHTML.M
  open Xhtmltypes

  type page = string

  type options = unit

  let send ?options ?(cookies=[]) ?charset ?code ~sp filename =
    let (filename, stat) =
      (try
        (* That piece of code has been pasted from staticmod.ml *)
        let stat = Unix.LargeFile.stat filename in
        let (filename, stat) =
          Ocsigen_messages.debug (fun () -> "Eliom.Files - Testing \""^filename^"\".");
          let path = get_current_sub_path sp in
          if (stat.Unix.LargeFile.st_kind = Unix.S_DIR)
          then
            if (filename.[(String.length filename) - 1]) = '/'
            then
              let fn2 = filename^"index.html" in
              Ocsigen_messages.debug (fun () -> "Eliom.Files - Testing \""^fn2^"\".");
              (fn2,(Unix.LargeFile.stat fn2))
            else
              (if (path= []) || (path = [""])
              then
                let fn2 = filename^"/index.html" in
                Ocsigen_messages.debug (fun () -> "Eliom.Files - Testing \""^fn2^"\".");
                (fn2,(Unix.LargeFile.stat fn2))
              else (Ocsigen_messages.debug
                      (fun () -> "Eliom.Files - "^filename^" is a directory");
                    raise Ocsigen_Is_a_directory))
          else (filename, stat)
        in
        Ocsigen_messages.debug
          (fun () ->
            "Eliom.Files - Looking for \""^filename^"\".");

        if (stat.Unix.LargeFile.st_kind
              = Unix.S_REG)
        then begin
          Unix.access filename [Unix.R_OK];
          (filename, stat)
        end
        else
          raise (Ocsigen_http_error (Ocsigen_http_frame.Cookies.empty, 404))(* ??? *)
      with
        (Unix.Unix_error (Unix.EACCES,_,_))
      | Ocsigen_Is_a_directory
      | Ocsigen_malformed_url as e -> raise e
      | e -> raise (Ocsigen_http_error (Ocsigen_http_frame.Cookies.empty, 404)))
    in
    Ocsigen_senders.File_content.result_of_content filename >>= fun r ->
    Lwt.return
        (EliomResult
           {r with
            res_cookies= Eliom_services.cookie_table_of_eliom_cookies ~sp cookies;
            res_code= code_of_code_option code;
            res_charset= (match charset with
            | None -> Some (get_config_file_charset sp)
            | _ -> charset);
          })


end

module Files = MakeRegister(Filesreg_)

(****************************************************************************)
(****************************************************************************)

module Streamlistreg_ = struct
  open XHTML.M
  open Xhtmltypes

  type page = (((unit -> (string Ocsigen_stream.t) Lwt.t) list) *
                 string)

  type options = unit


  let send ?options ?(cookies=[]) ?charset ?code ~sp content =
    Ocsigen_senders.Streamlist_content.result_of_content content >>= fun r ->
    Lwt.return
        (EliomResult
           {r with
            res_cookies= Eliom_services.cookie_table_of_eliom_cookies ~sp cookies;
            res_code= code_of_code_option code;
            res_charset= (match charset with
            | None -> Some (get_config_file_charset sp)
            | _ -> charset);
          })

end

module Streamlist = MakeRegister(Streamlistreg_)

