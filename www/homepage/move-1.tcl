# /homepage/move-1.tcl

ad_page_contract {
    Allow to move a file or directory.

    @param filesystem_node The top directory the directory will be moved in.
    @param move_node The directory to move.

    @creation-date Jan 24 22:03:59 EST 2000
    @author mobin@mit.edu
    @cvs-id move-1.tcl,v 3.3.2.5 2000/09/22 01:38:17 kevin Exp

} {
    filesystem_node:notnull,naturalnum
    move_node:notnull,naturalnum
}

# ------------------------------ initialization codeBlock ----

set user_id [ad_maybe_redirect_for_registration]

# ------------------------------ htmlGeneration codeBlock ----

set filename [db_string file_name {
    select filename from users_files
    where file_id=:move_node
}]

set html "
Please click on the directory to which<br>you would like to move `$filename':
<br><p>
<table border=0 cellpadding=0 cellspacing=0>"

set user_root [db_string user_root {
    select hp_get_filesystem_root_node(:user_id) from dual
}]


db_foreach dir_listing {
    select file_id as fid, filename, level, parent_id,
           hp_filesystem_node_sortkey_gen(f.file_id) as generated_sort_key
    from users_files f
    where owner_id=:user_id
      and directory_p='t'
      and managed_p='f'
    connect by prior file_id = parent_id
    start with file_id=:user_root
    order by generated_sort_key asc
} {
    set level [expr $level - 1]
    if {$level == 0} {
	append html "<tr><td>[ad_space [expr $level * 8]]<img src=dir.gif>
	<a href=move-2?filesystem_node=$filesystem_node&move_node=$move_node&move_target=$fid>Your root directory</a>"
    } else {
	append html "<tr><td>[ad_space [expr $level * 8]]<img src=dir.gif>
	<a href=move-2?filesystem_node=$filesystem_node&move_node=$move_node&move_target=$fid>$filename</a>"
    }
}

db_release_unused_handles

append html "</table>"

#set dialog_body "Please choose the directory to which you would like to move `$filename'<br> \
#<table> \
#$html \
#</table>"

#  <table border=0 cellpadding=0> \
#  <tr> \
#      <td><form method=get action=index> \
#          <input type=hidden name=filesystem_node value=$filesystem_node> \
#          <input type=submit value=Cancel></form></td> \
#  </tr></table>"

#ad_returnredirect "dialog-class.tcl?title=Filesystem Management&text=$dialog_body"
#return

set title "Filesystem Management"
# Code deactivated Mon Jan 24 21:40:52 EST 2000
#ns_write "
#[ad_header $title]
#<h2>$title</h2>
#[ad_context_bar_ws_or_index \
#        [list "index.tcl?filesystem_node=$filesystem_node" "Homepage Maintenance"] $title]
#<hr>
#<blockquote>
#
#$html
#
#<form method=post action=rename-2>
#  <input type=hidden name=filesystem_node value=$filesystem_node>
#  <input type=hidden name=move_node value=$move_node>
#  <p><br>
#  <ul> 
#  <table cellpadding=4>
#    <tr>
#      <th align=left>new name for `$filename':
#      <td><input type=text size=16 name=new_name></tr>
#  </table>
#  <input type=submit value=Rename>
#  </ul>
#</form>
#
#</blockquote>
#[ad_footer]
#"

set document "
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
doc_return  200 text/html $document