# /www/admin/adserver/all-advs.tcl

ad_page_contract {
    @param none
    @author modified 07/13/200 by mchu@arsdigita.com
    @cvs-id all-advs.tcl,v 3.1.6.5 2000/11/20 23:55:17 ron Exp
} {
    
}


set page_content "[ad_admin_header "Manage Ads"]
<h2>Manage Ads</h2>
at <A href=\"index\">AdServer Administration</a>
<hr><p>

<ul>
<li> <a href=\"add-adv\">Add</a> a new ad.
<p>
"

set sql_query "select adv_key
from advs
order by upper(adv_key)"

db_foreach adv_select_advs_query $sql_query {
    append page_content "<li> <a href=\"one-adv?[export_url_vars adv_key]\">$adv_key</a>\n"
}

db_release_unused_handles

append page_content "</ul>
<p>
[ad_admin_footer]
"

doc_return 200 text/html $page_content
