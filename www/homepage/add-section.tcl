# $Id: add-section.tcl,v 3.0.4.1 2000/04/28 15:11:00 carsten Exp $
# File:     /homepage/add-section.tcl
# Date:     Tue Jan 25 02:26:37 EST 2000
# Location: 42ÅÅ∞21'N 71ÅÅ∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to create an empty subsection

set_form_variables
# filesystem_node, section_type, master_type

# ------------------------------ initialization codeBlock ----

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# If the user is not registered, we need to redirect him for
# registration
if { $user_id == 0 } {
    ad_redirect_for_registration
    return
}

set first_letter [string toupper [string range $section_type 0 0]]
set others [string range $section_type 1 [expr [string length $section_type] - 1]]
set section_type_2 "$first_letter$others"

# ------------------------------ htmlGeneration codeBlock ----

set dialog_body " \
<form method=post action=mksection-1.tcl> \
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
      <td><form method=get action=index.tcl> \
          <input type=hidden name=filesystem_node value=$filesystem_node> \
          <input type=submit value=Cancel></form></td> \
  </tr></table>"


ad_returnredirect "dialog-class.tcl?title=Content Management&text=$dialog_body"
return




