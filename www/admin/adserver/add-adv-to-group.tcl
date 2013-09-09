# /www/admin/adserver/add-adv-to-group.tcl

ad_page_contract {
    @param group_key:notnull
    @author modified 07/13/200 by mchu@arsdigita.com
    @cvs-id add-adv-to-group.tcl,v 3.1.6.5 2000/11/20 23:55:15 ron Exp
} {
    group_key:notnull
}

db_1row adv_pretty_name_query "select pretty_name from adv_groups where group_key = :group_key"

set page_content "[ad_admin_header "Add ads to group $pretty_name"]
<h2>Add ads</h2>
to Ad Group <a href=\"one-adv-group?group_key=$group_key\">$pretty_name</a>.
<hr><p>

Choose an ad to include in this Ad Group:<p>
<ul>
"

set sql_query "select adv_key from advs where adv_key NOT IN (select adv_key from adv_group_map where group_key = :group_key)"

db_foreach adv_get_key_query $sql_query {
    append page_content "<li><a href=\"add-adv-to-group-2?[export_url_vars group_key adv_key]\">$adv_key</a>\n"
}

db_release_unused_handles

append page_content "</ul>
<p>
[ad_admin_footer]
"

doc_return 200 text/html $page_content