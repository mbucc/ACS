# /www/admin/adserver/all-adv-groups.tcl

ad_page_contract {
    @param none
    @author modified 07/13/200 by mchu@arsdigita.com
    @cvs-id all-adv-groups.tcl,v 3.1.6.5 2000/11/20 23:55:16 ron Exp
} {
    
}

set page_content "[ad_admin_header "Manage Ad Groups"]
<h2>Manage Ad Groups</h2>
at <A href=\"index\">AdServer Administration</a>
<hr><p>

<ul>
<li> <a href=\"add-adv-group\">Add</a> a new ad group.
<p>
"

set sql_query "select group_key, pretty_name from adv_groups"

db_foreach adv_keyname_query $sql_query {
    append page_content "<li> <a href=\"one-adv-group?[export_url_vars group_key]\">$pretty_name</a>\n"
}

db_release_unused_handles

append page_content "</ul>
<p>
[ad_admin_footer]
"

doc_return 200 text/html $page_content