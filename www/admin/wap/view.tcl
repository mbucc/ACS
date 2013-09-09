#/www/admin/wap/view.tcl

ad_page_contract {
    View a list of known WAP user agents
    
    @param user_agent_id A list of user agent id's.
    @param action A string which drives the UI; can be "view" or "delete"
    @author Andrew Grumet (aegrumet@arsdigita.com)
    @creation-date Wed May 24 06:02:06 2000
    @cvs-id  view.tcl,v 1.2.2.4 2000/09/22 01:36:36 kevin Exp
} {
    user_agent_id:multiple,integer,optional
    { action view }
}

if ![info exists user_agent_id] {
    ad_returnredirect view-list
    return
}

switch $action {
    delete { set pretty_action Delete }
    default { set pretty_action View }
}


set page_content "[ad_admin_header "WAP User-Agents"]

<h2>WAP User-Agents</h2>

[ad_admin_context_bar [list "index" "WAP"] [list "view-list" "WAP User-Agents"] $pretty_action]

<hr>

<blockquote>\n"

# if we've reached here, user_agent_id contains at least one element
set user_agent_id_set ([join $user_agent_id ,])

set sql_query "
select user_agent_id,
       name,
       creation_comment,
       creation_date
from wap_user_agents
where deletion_date is null
and user_agent_id in $user_agent_id_set
order by lower(name)"

# Sadly the if_no_rows clause of db_foreach won't cut it here.
set counter 0
db_foreach wap_user_agents_long $sql_query {
    incr counter
    append page_content "<table><tr><th align=right>Name:</th><td>$name</td></tr>
<tr><th align=right>Creation Date:</th><td>[util_AnsiDatetoPrettyDate $creation_date]</td></tr>
<tr><th align=right>Comment:</th><td>$creation_comment</td></tr></table>
<br>
<br>
"
}

if !$counter {
    append page_content "Sorry, no matching WAP user agents in the database.
</blockquote>"
} else {
    append page_content "</blockquote>\n"
    if { [string compare $action delete] == 0 } {
	append page_content "
<form action=\"delete\" method=POST>
[export_entire_form]
<center>
<strong>Really delete?</strong><br>
<input type=button value=\"OK\" onclick=\"form.submit()\">&nbsp;<input value=\"Go back\" type=button onclick=\"history.back()\"></center>
</form>
"
    } else {
	append page_content "<p>
<ul>
<li><a href=\"view?[export_ns_set_vars url [list action]]&action=delete\">Delete</a>
<li><a href=\"view-list\">Back to list</a>
</ul>"
   }
}

append page_content "
[ad_admin_footer]"



doc_return  200 text/html $page_content








