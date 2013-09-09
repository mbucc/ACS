# /www/admin/wap/add-2.tcl

ad_page_contract {
    Target for add.tcl -- check input prior to insert.
 
    @param user_agent_id
    @param name
    @param creation_commnet
    @author Andrew Grumet (aegrumet@arsdigita.com)
    @creation-date   Wed May 24 08:01:17 2000
    @cvs-id  add-2.tcl,v 1.2.2.6 2001/01/12 00:37:09 khy Exp
} {
    user_agent_id:naturalnum,notnull,verify
    name
    {creation_comment {}}
}



page_validation {validate_integer "User Agent Id" $user_agent_id} \
	{ 
            if [empty_string_p $name] {
                error "The User Agent field cannot be left empty."
            }
        } \
        {
            if { [string length $name] > 200 } {
		error "The User Agent name must be 200 characters or less."
	    }
	}
    
# User input looks relatively good.

if [llength [wap_user_agent_collisions [list $name]]] {
    set name_maybe_highlighted "<font color=\"red\">[ns_quotehtml $name]</font>"
    set warning_text "<font color=\"red\"><strong>BEWARE: The user agent string you entered looks a lot like an HTML browser to us.  Proceed at your own risk!</strong></font>"
} else {
    set name_maybe_highlighted [ns_quotehtml $name]
    set warning_text {}
}

set page_content "[ad_admin_header "Add a WAP User-Agent"]

<h2>Add a WAP User-Agent</h2>

[ad_admin_context_bar [list "index" "WAP"] [list "view-list" "WAP User-Agents"] "Add One"]

<hr>

<form method=POST action=\"add-3\">
[export_form_vars name creation_comment]
[export_form_vars -sign user_agent_id]
<blockquote>
<table>
 <tr>
  <th align=right valign=top>User-Agent string:</th>
  <td valign=top>$name_maybe_highlighted</td>
 </tr>
 <tr>
  <th align=right valign=top>Comment:</th>
  <td valign=top>[ns_quotehtml $creation_comment]</td>
 </tr>
</table>
<p>
$warning_text
</blockquote>

<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]"

doc_return  200 text/html $page_content


