# /www/admin/partner/index.tcl

ad_page_contract {
    Lists all partners, with links to partner-view.tcl and a link to 
    add partners (partner-ae.tcl) 

    @author mbryzek@arsdigita.com
    @creation-date 10/1999

    @cvs-id index.tcl,v 3.2.2.4 2000/09/22 01:35:44 kevin Exp
} {}


set page_title "Partner Manager"
set context_bar [ad_context_bar_ws "Partner manager"]

set page_body "
<b>Partners</b>
<UL>
"

db_foreach partner_id_name_list "
select p.partner_id, p.partner_name 
from ad_partner p
order by upper(p.partner_name)
" {
    append page_body "  <LI><A HREF=\"partner-view?[export_url_vars partner_id]\">$partner_name</a>\n"
} 

append page_body "

<P>
<LI><A HREF=\"partner-ae\">Add a partner</a>
</UL>
"

# ad_partner_return_template releases the db handles
doc_return 200 text/html [ad_partner_return_template]


