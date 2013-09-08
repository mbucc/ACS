# File:     /homepage/movenh-1.tcl

ad_page_contract {
    Purpose:  Page to move a neighbourhood

    @param neighborhood_node The neighborhood node one came from
    @param move_node The node to move from

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Thu Jan 27 02:44:02 EST 2000
    @cvs-id movenh-1.tcl,v 3.3.2.10 2000/09/22 01:38:17 kevin Exp
} {
    neighborhood_node:notnull,naturalnum
    move_node:notnull,naturalnum
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

# ------------------------------ htmlGeneration codeBlock ----


set neighborhood_name [db_string select_neighborhood_name "
select neighborhood_name from users_neighborhoods
where neighborhood_id=:move_node"]

set page_content "
Please click on the neighborhood to which<br>you would like to move `$neighborhood_name':
<br><p>
<table border=0 cellpadding=0 cellspacing=0>"

set user_root [db_string select_user_root "
select hp_get_neighborhood_root_node from dual"]

set neighborhood_qry  "
select neighborhood_id as nid, neighborhood_name, level, parent_id,
hp_neighborhood_sortkey_gen(neighborhood_id) as generated_sort_key,
hp_neighborhood_in_subtree_p(:move_node, neighborhood_id) as is_child_p
from users_neighborhoods
connect by prior neighborhood_id = parent_id
start with neighborhood_id=:user_root
order by generated_sort_key asc"

db_foreach get_neighborhoods $neighborhood_qry {
    set level [expr $level - 1]

    if {$is_child_p} {
    } else {
    append page_content "<tr><td>[ad_space [expr $level * 8]]
	<a href=movenh-2?neighborhood_node=$neighborhood_node&move_node=$move_node&move_target=$nid>$neighborhood_name</a>"
    }
}

db_release_unused_handles

append page_content "</table>"

set title "Neighborhood Management"

#set dialog_body "Please choose the directory to which you would like to move `$neighborhood_name'<br> \
#<table> \
#$page_content \
#</table>"

#  <table border=0 cellpadding=0> \
#  <tr> \
#      <td><form method=get action=index> \
#          <input type=hidden name=neighborhood_node value=$neighborhood_node> \
#          <input type=submit value=Cancel></form></td> \
#  </tr></table>"

#ad_returnredirect "dialog-class?title=Neighborhood Management&text=$dialog_body"
#return


# Code deactivated Mon Jan 24 21:40:52 EST 2000
#ns_write "
#[ad_header $title]
#<h2>$title</h2>
#[ad_context_bar_ws_or_index \
#        [list "index?neighborhood_node=$neighborhood_node" "Homepage Maintenance"] $title]
#<hr>
#<blockquote>
#
#$page_content
#
#<form method=post action=rename-2>
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

set page_content "
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
                                                  $page_content
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

doc_return  200 text/html $page_content


