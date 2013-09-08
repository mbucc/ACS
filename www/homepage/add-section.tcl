# File:     /homepage/add-section.tcl

ad_page_contract {
    Page to create an empty subsection

    @param filesystem_node System variable for determining where redirects go
    @param section_type Name of a section type to add
    @param master_type Name of the master type to add to

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Tue Jan 25 02:26:37 EST 2000
    @cvs-id add-section.tcl,v 3.3.2.6 2000/09/15 21:09:20 kevin Exp
} {
    filesystem_node:notnull,naturalnum
    section_type:notnull,trim
    master_type:notnull,trim
}

# ------------------------------ initialization codeBlock ----

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# If the user is not registered, we need to redirect him for
# registration
if { $user_id == 0 } {
    ad_redirect_for_registration
    return
}

set section_type_2 [capitalize $section_type]

# ------------------------------ htmlGeneration codeBlock ----

set dialog_body " \
<form method=post action=mksection-1> \
  <input type=hidden name=filesystem_node value=$filesystem_node> \
  <input type=hidden name=section_type value=$section_type> \
  <table cellpadding=0 border=0> \
    <tr> \
      <td align=left> \
      Add a $section_type to this $master_type</td> \
      </tr> \
    <tr> \
      <td align=left>name: </td>\
      <td><input type=text size=16 name=section_title value=\"$section_type_2 1\">(used as a sort key)</tr> \
    <tr> \
      <td align=left>$section_type title: </td>\
      <td><input type=text size=40 name=section_desc></tr> \
  </table> \
  <table border=0 cellpadding=0> \
  <tr><td><input type=submit value=Okay></form></td> \
      <td><form method=get action=index> \
          <input type=hidden name=filesystem_node value=$filesystem_node> \
          <input type=submit value=Cancel></form></td> \
  </tr></table>"

ad_returnredirect "dialog-class?title=Content Management&text=$dialog_body"
return













