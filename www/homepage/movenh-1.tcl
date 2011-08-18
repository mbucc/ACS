# $Id: movenh-1.tcl,v 3.0.4.1 2000/04/28 15:11:02 carsten Exp $
# File:     /homepage/movenh-1.tcl
# Date:     Thu Jan 27 02:44:02 EST 2000
# Location: 42ÅÅ∞21'N 71ÅÅ∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to move a neighbourhood

set_form_variables
# neighborhood_node, move_node

# ------------------------------ initialization codeBlock ----

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# If the user is not registered, we need to redirect him for
# registration
if { $user_id == 0 } {
    ad_redirect_for_registration
    return
}

# ------------------------------ htmlGeneration codeBlock ----

set db [ns_db gethandle]
set neighborhood_name [database_to_tcl_string $db "
select neighborhood_name from users_neighborhoods
where neighborhood_id=$move_node"]

set html "
Please click on the neighborhood to which<br>you would like to move `$neighborhood_name':
<br><p>
<table border=0 cellpadding=0 cellspacing=0>"

set user_root [database_to_tcl_string $db "
select hp_get_neighborhood_root_node from dual"]

set selection [ns_db select $db "
select neighborhood_id as nid, neighborhood_name, level, parent_id,
hp_neighborhood_sortkey_gen(neighborhood_id) as generated_sort_key,
hp_neighborhood_in_subtree_p($move_node, neighborhood_id) as is_child_p
from users_neighborhoods
connect by prior neighborhood_id = parent_id
start with neighborhood_id=$user_root
order by generated_sort_key asc"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    set level [expr $level - 1]
    
    if {$is_child_p} {
    } else {
    append html "<tr><td>[ad_space [expr $level * 8]]
	<a href=movenh-2.tcl?neighborhood_node=$neighborhood_node&move_node=$move_node&move_target=$nid>$neighborhood_name</a>"
    }

}

ns_db releasehandle $db

append html "</table>"

#set dialog_body "Please choose the directory to which you would like to move `$neighborhood_name'<br> \
#<table> \
#$html \
#</table>"

#  <table border=0 cellpadding=0> \
#  <tr> \
#      <td><form method=get action=index.tcl> \
#          <input type=hidden name=neighborhood_node value=$neighborhood_node> \
#          <input type=submit value=Cancel></form></td> \
#  </tr></table>"


#ad_returnredirect "dialog-class.tcl?title=Neighborhood Management&text=$dialog_body"
#return

ReturnHeaders

set title "Neighborhood Management"

# Code deactivated Mon Jan 24 21:40:52 EST 2000
#ns_write "
#[ad_header $title]
#<h2>$title</h2>
#[ad_context_bar_ws_or_index \
#        [list "index.tcl?neighborhood_node=$neighborhood_node" "Homepage Maintenance"] $title]
#<hr>
#<blockquote>
#
#$html
#
#<form method=post action=rename-2.tcl>
#  <input type=hidden name=neighborhood_node value=$neighborhood_node>
#  <input type=hidden name=move_node value=$move_node>
#  <p><br>
#  <ul> 
#  <table cellpadding=4>
#    <tr>
#      <th align=left>new name for `$neighborhood_name':
#      <td><input type=text size=16 name=new_name></tr>
#  </table>
#  <input type=submit value=Rename>
#  </ul>
#</form>
#
#</blockquote>
#[ad_footer]
#"

ns_write "
<html>

<head>
<title>$title</title>
<meta name=\"description\" content=\"Usman Y. Mobin's generic dialog class.\">
<style>
A:link {text-decoration:none; font-style:plain; font-weight:bold}
A:vlink {text-decoration:none; font-style:plain; font-weight:bold}
</style>
</head>

<body bgcolor=FFFFFF text=000000 link=000000 vlink=000000 alink=000000>
<div align=center><center>

<table border=0 
        cellspacing=0 
        cellpadding=0 
        width=100%
        height=100%>
                <tr>
                <td align=center valign=middle>

                <table border=0
                       cellspacing=0
                       cellpadding=0>
                        <tr bgcolor=000080>
                        <td>
                                <table border=0
                                       cellspacing=0
                                       cellpadding=6>
                                        <tr bgcolor=000080>
                                        <td>
                                               <font color=FFFFFF>
                                               $title
                                               </font>
                                        </td>
                                        </tr>
                                </table> 
                        </td>
                        </tr>
                        <tr bgcolor=C0C0C0>
                        <td align=center>
                                <table border=0
                                       cellspacing=0
                                       cellpadding=25>
                                         <tr align=center>
                                         <td><p>
                                                  $html
                                         </td>
                                         </tr>
                                </table>
                        </td>
                        </tr>
                </table>

                </td>
                </tr>
</table>

</center></div>
</body>
</html>
"
