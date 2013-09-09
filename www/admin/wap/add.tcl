# /www/admin/wap/add.tcl

ad_page_contract {
    Add a WAP user agent.

    @author Andrew Grumet aegrumet@arsdigita.com
    @creation-date Wed May 24 08:01:17 2000
    @cvs-id  add.tcl,v 1.2.2.7 2001/01/12 00:39:03 khy Exp
} {
}



set page_content "[ad_admin_header "Add a WAP User-Agent"]

<h2>Add a WAP User-Agent</h2>

[ad_admin_context_bar [list "index" "WAP"] [list "view-list" "WAP User-Agents"] "Add One"]

<hr>
"

set user_agent_id [db_string admin_wap_add_get_wap_user_agent_id  "select wap_user_agent_id_sequence.nextval from dual"]

append page_content "
<form method=POST action=\"add-2.tcl\">
[export_form_vars -sign user_agent_id]
<blockquote>
<table>
 <tr>
  <th align=right valign=top>User-Agent string:</th>
  <td valign=top><input name=name type=text size=50 maxlength=200></td>
 </tr>
 <tr>
  <th align=right valign=top>Comment:</th>
  <td valign=top><textarea wrap=hard name=creation_comment cols=50 rows=10></textarea></td>
 </tr>
</table>
</blockquote>
<center>
<input type=submit value=\"Add\">
</center>
</form>
"

append page_content "
[ad_admin_footer]"



doc_return  200 text/html $page_content

