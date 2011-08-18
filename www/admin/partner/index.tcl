# $Id: index.tcl,v 3.0 2000/02/06 03:26:33 ron Exp $

set page_title "Partner Manager"
set context_bar [ad_context_bar_ws "Partner manager"]

set page_body "
<b>Partners</b>
<UL>
"

set db [ns_db gethandle]
set selection [ns_db select $db \
	"select distinct partner_id, partner_name 
           from ad_partner 
          order by upper(partner_name)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append page_body "  <LI><A HREF=\"partner-view.tcl?[export_url_vars partner_id]\">$partner_name</a>\n"
} 
ns_db releasehandle $db

append page_body "

<P>
  <LI><A HREF=\"partner-ae.tcl\">Add a partner</a>
</UL>
"

ns_return 200 text/html [ad_partner_return_template]
