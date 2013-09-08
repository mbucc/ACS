# /www/admin/wap/import

ad_page_contract {

    Display parameters and show summary results for importing WAP agents.

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @creation-date  Wed May 24 10:03:51 2000
    @cvs-id import.tcl,v 1.3.2.5 2000/09/22 01:36:34 kevin Exp
} {

}


set new_agents_list [wap_import_agent_list]

set old_agents_list [db_list wap_user_agent_names "
    select name from wap_user_agents where deletion_date is null"]

set agents_to_add [list]

foreach agent $new_agents_list {
    if { [lsearch $old_agents_list $agent] < 0 } {
	lappend agents_to_add $agent
    }
}

set page_content "[ad_admin_header "Import WAP User-Agent Strings"]

<h2>Import WAP User-Agents</h2>

[ad_admin_context_bar [list "index" "WAP"] [list "view-list" "WAP User-Agents"] "Import"]

<hr>
<blockquote>
<strong>Totals:</strong> <a href=\"import-view?view=all\">[llength $new_agents_list] found</a>; "

if [llength $agents_to_add] {
    append page_content "
<a href=\"import-view?view=new\">[llength $agents_to_add] new</a>

<center>
<form method=GET action=\"import-actually\">
<input type=submit value=\"Import New Strings\">
</form>
</center>

"
} else {
    append page_content "0 new"
}

append page_content "
</blockquote>

<p>

<blockquote>

<p>

<strong>Import Site URL:&nbsp;<a href=\"[wap_import_site_url]\"></strong>&nbsp;[wap_import_site_url]</a>

<p>

<strong>Import Parsing Procedure:</strong><a href=\"/api-doc/proc-view?proc=[ns_urlencode [wap_import_parse_proc]]\">[wap_import_parse_proc]</a>

</blockquote>

[ad_admin_footer]"



doc_return  200 text/html $page_content











