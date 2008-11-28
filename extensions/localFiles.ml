open Ocsigen_extensions

(* Displaying of a local file or directory. Currently used in
   staticmod and eliom_predefmod*)

exception Failed_403
exception Failed_404


(* Policies for following symlinks *)
type symlink_policy =
    stat:Unix.LargeFile.stats -> lstat:Unix.LargeFile.stats -> bool

let never_follow_symlinks : symlink_policy =
  fun ~stat ~lstat -> false

let follow_symlinks_if_owner_match : symlink_policy =
  fun ~stat ~lstat ->
    stat.Unix.LargeFile.st_uid = lstat.Unix.LargeFile.st_uid


(* checks that [filename] can be followed depending on the predicate
   [policy] which must receives as argument both the results
   of calling [stat] and [lstat] on filenam.
   If supplied, [stat] must be the result of calling [Unix.stat] on
   [filename] *)
let check_symlinks_aux
    filename ?(stat=Unix.LargeFile.stat filename) (policy : symlink_policy) =
  let lstat = Unix.LargeFile.lstat filename in
  if lstat.Unix.LargeFile.st_kind = Unix.S_LNK then
    policy ~stat ~lstat
  else
    true

(* Check that there are no invalid symlinks in the directories leading to
   [filename]. *)
let rec check_symlinks_parent_directories filename (policy : symlink_policy) =
  if filename = "/" || filename = "." then
    true
  else
    let dirname = Filename.dirname filename in
    check_symlinks_aux dirname policy &&
    check_symlinks_parent_directories dirname policy


(* Check that [filename] can be reached according to the given
   symlink policy  *)
let check_symlinks filename policy =
  let aux policy =
    if filename = "/" then
      (* The root cannot be a symlink, and this avoids some degenerate
         cases later on *)
      true
    else
      let filename =
        (* [filename] should start by at least a slash, as
           [Filename.is_relative filename] should be false. Hence the length
           should be at least 1 *)
        (* We remove an eventual trailing slash, in order to avoid a
           needless recursion in check_symlinks_parent_directories, and so
           that Unix.lstat returns the correct result (Unix.lstat "foo/" and
           Unix.lstat "foo" return two different results...)  *)
        let len = String.length filename - 1 in
        if filename.[len] = '/' then
          String.sub filename 0 len
        else
          filename
      in
      check_symlinks_aux filename policy &&
      check_symlinks_parent_directories filename policy
  in
  match policy with
    | AlwaysFollowSymlinks -> true
    | DoNotFollowSymlinks -> aux never_follow_symlinks
    | FollowSymlinksIfOwnerMatch -> aux follow_symlinks_if_owner_match


(* Return type of a request for a local file. The string argument
   represents the real file/directory to serve, eg. foo/index.html
   instead of foo *)
type resolved =
  | RFile of string
  | RDir of string


(* given [filename], we search for it in the local filesystem and
   - we return ["filename/index.html"] if [filename] corresponds to
   a directory, ["filename/index.html"] is valid, and ["index.html"]
   is one possible index (trying all possible indexes in order)
   - we raise [Failed_403] if [filename] corresponds to a directory,
   no index exists and [list_dir_content] is false
   - we raise [Failed_403] if [filename] is a symlink that must
   not be followed
   - raises [Failed_404] if [filename] does not exist, or is a special file
   - otherwise returns [filename]
*)
(* See also module Files in eliom.ml *)
let resolve ~request ~filename =
  try
    Ocsigen_messages.debug
      (fun () -> "--LocalFiles: Testing \""^filename^"\".");
    let stat = Unix.LargeFile.stat filename in
    let (filename, stat) =
      if stat.Unix.LargeFile.st_kind = Unix.S_DIR then
        if filename.[String.length filename - 1] <> '/' then begin
          (* In this case, [filename] is a directory but this is not visible in
             its name as there is no final slash. We signal this fact to
             Ocsigen, which will then issue a 301 redirection to "filename/" *)
          Ocsigen_messages.debug
            (fun () -> "--LocalFiles: "^filename^" is a directory");
          raise (Ocsigen_extensions.Ocsigen_Is_a_directory request)
        end

        else
          let rec find_index = function
            | [] ->
                (* No suitable index, we try to list the directory *)
                if request.request_config.list_directory_content then (
                  Ocsigen_messages.debug2
                    "--LocalFiles: Displaying directory content";
                  (filename, stat))
                else (
                  (* No suitable index *)
                  Ocsigen_messages.debug2
                    "--LocalFiles: No index and no listing";
                  raise Failed_403)
            | e :: q ->
                let index = filename ^ e in
                Ocsigen_messages.debug
                  (fun () -> "--LocalFiles: Testing \""^index
                     ^"\" as possible index.");
                try
                  (index, Unix.LargeFile.stat index)
                with
                  | Unix.Unix_error (Unix.ENOENT, _, _) -> find_index q
          in find_index request.request_config.default_directory_index

      else (filename, stat)
    in
    if check_symlinks filename request.request_config.follow_symlinks then
      begin
        Ocsigen_messages.debug
          (fun () -> "--LocalFiles: Returning \""^filename^"\".");
        if stat.Unix.LargeFile.st_kind = Unix.S_REG then
          RFile filename
        else if stat.Unix.LargeFile.st_kind = Unix.S_DIR then
          RDir filename
        else raise Failed_404
      end
    else (
      (* [filename] is accessed through as symlink which we should not
         follow according to the current policy *)
      Ocsigen_messages.debug
        (fun () -> "--Failed symlink check for \""^filename^"\".");
      raise Failed_403)
  with
    (* We can get an EACCESS here, if are missing some rights on a directory *)
    | Unix.Unix_error (Unix.EACCES,_,_) -> raise Failed_403
    | Unix.Unix_error (Unix.ENOENT,_,_) -> raise Failed_404


(* Given a local file or directory, we retrieve its content *)
let content ~request ~file =
  try
    match file with
      | RDir dirname ->
          Ocsigen_senders.Directory_content.result_of_content
            (dirname, request.request_info.ri_full_path)
      | RFile filename ->
          Ocsigen_senders.File_content.result_of_content
            ~options:(request.request_config.mime_assoc,
                      request.request_config.default_mime_type)
            filename
  with
    | Unix.Unix_error (Unix.EACCES,_,_) -> raise Failed_403