# $Id: webspace-init.tcl,v 3.1.2.1 2000/04/28 15:11:04 carsten Exp $
# File:     /users/webspace-init.tcl
# Date:     Thu Jan 13 00:09:31 EST 2000
# Location: 42ÅÅ∞21'N 71ÅÅ∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  User Content Main Page

# ------------------------------ initialization codeBlock ----

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# If the user is not registered, we need to redirect him for
# registration
if { $user_id == 0 } {
    ad_redirect_for_registration
    return
}

# ------------------------ initialDatabaseQuery codeBlock ----

# The database handle (a thoroughly useless comment)
set db [ns_db gethandle]

# This will check whether the user's top level directory exists
# or not.
set dir_p [database_to_tcl_string $db "
select count(*)
from users_files
where filename='$user_id'
and parent_id is null
and owner_id=$user_id"]

if {$dir_p==0} {
    if [catch {ns_mkdir "[ad_parameter ContentRoot users]$user_id"} errmsg] {
        # directory already exists    
        append exception_text "
        <li>directory [ad_parameter ContentRoot users]$user_id could not be created.<pre>$errmsg</pre>"
        ad_return_complaint 1 $exception_text
        return
   } else {
       ns_chmod "[ad_parameter ContentRoot users]$user_id" 0777

       ns_db dml $db "
       insert into users_files
       (file_id, filename, directory_p, file_pretty_name, file_size, owner_id)
       values
       (users_file_id_seq.nextval, '$user_id', 't', 'UserContent personalRoot', 0, $user_id)"
       ns_db dml $db "
       insert into users_homepages
       (user_id, bgcolor, maint_bgcolor, maint_unvisited_link, maint_visited_link, 
       maint_link_text_decoration, maint_link_font_weight)
       values
       ($user_id, 'white', 'white', '006699', '006699', 'none', 'bold')"
   }
}
# And off with the handle!
ns_db releasehandle $db

ad_returnredirect index.tcl





