# /www/admin/wap/view-list

ad_page_contract {
    View a list of known WAP user agents
   
    @author Andrew Grumet (aegrumet@arsdigita.com)
    @creation-date Wed Wed May 24 06:02:06 2000
    @cvs-id  view-list.tcl,v 1.2.2.4 2000/09/22 01:36:35 kevin Exp
} {

}


set page_content "[ad_admin_header "WAP User-Agents"]

<h2>WAP User-Agents</h2>

[ad_admin_context_bar [list "index" "WAP"] "WAP User-Agents"]

<hr>
"

set sql_query  "
select user_agent_id,
       name
from wap_user_agents
where deletion_date is null
order by lower(name)"

set agents_html "<ul>\n"

set counter 0
db_foreach wap_user_agents_short $sql_query {
    incr counter
    append agents_html "<li>$name (<a href=\"view?[export_url_vars user_agent_id]\">more</a>)(<a href=\"view?[export_url_vars user_agent_id]&action=delete\">delete</a>)
"
} if_no_rows {
    append agents_html "<li>Sorry, no WAP user agents in the database."
}

append page_content "<p>
Total: $counter user-agents
$agents_html<p>
<li><a href=\"add\">Add a WAP user agent by hand</a>
<li><a href=\"import\">Check for new user agent strings</a>
</ul>
[ad_admin_footer]"



doc_return  200 text/html $page_content

