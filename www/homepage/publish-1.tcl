# $Id: publish-1.tcl,v 3.0.4.1 2000/04/28 15:11:02 carsten Exp $
# File:     /homepage/mkdir-1.tcl
# Date:     Fri Jan 14 18:48:26 EST 2000
# Location: 42ÅÅ∞21'N 71ÅÅ∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to create a folder

set_form_variables
# filesystem_node

# ------------------------------ initialization codeBlock ----

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# If the user is not registered, we need to redirect him for
# registration
if { $user_id == 0 } {
    ad_redirect_for_registration
    return
}

set db [ns_db gethandle]
set new_type_id [database_to_tcl_string $db "
select users_type_id_seq.nextval from dual"]

# ------------------------------ htmlGeneration codeBlock ----

set dialog_body "Provide characteristics of the new content:<br><form method=post action=publish-2.tcl> \
  <input type=hidden name=filesystem_node value=$filesystem_node> \
  <input type=hidden name=new_type_id value=$new_type_id> \
  <table border=0 cellpadding=15> \
    <tr> \
      <th align=left>Content type: </td> \
      <td><input type=text size=16 name=content_type><br>(e.g. book)</td></tr> \
    <tr> \
      <th align=left>Very short name: </td> \
      <td><input type=text size=16 name=very_short_name><br>(e.g. nerdguide)</td></tr> \
    <tr> \
      <th align=left>Full name: </td> \
      <td><input type=text size=30 name=full_name><br>(e.g. Mobin's Guide to Becoming a Better Nerd)</td></tr> \
    <tr> \
      <th align=left>Subsections: </td> \
      <td><input type=text size=30 name=sub_section><br>(e.g. for a book, this should be `chapter')</td></tr> \
  </table> \
  <table border=0 cellpadding=0> \
  <tr> \
  <td><input type=submit value=Okay></form></td> \
  <td><form method=get action=index.tcl> \
  <input type=hidden name=filesystem_node value=$filesystem_node> \
  <input type=submit value=Cancel></form></td> \
  </tr> \
  </table>"

ad_returnredirect "dialog-class.tcl?title=Content Management&text=$dialog_body"
return



