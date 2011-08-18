# $Id: partner-view.tcl,v 3.0 2000/02/06 03:26:52 ron Exp $
set_the_usual_form_variables
# partner_id

set db [ns_db gethandle]

set return_url "partner-view.tcl?[export_url_vars partner_id]"

set selection [ns_db 0or1row $db \
	"select * from ad_partner where partner_id=$partner_id"]

if { [empty_string_p $selection] } {
    ad_partner_return_error "Partner doesn't exist" \
	    "There is no partner with a partner_id of $partner_id"
    return
}

set_variables_after_query

set page_title $partner_name
set context_bar [ad_context_bar_ws [list "index.tcl" "Partner manager"] "One partner"]

set url_string ""
set selection [ns_db select $db "select distinct url_stub, url_id
		                 from ad_partner_url
                                 where partner_id='$QQpartner_id'
                                 order by upper(url_stub)"]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append url_string "  <LI>$url_stub | 
<a href=\"partner-url.tcl?[export_url_vars url_id]\">View</a> | 
<a href=\"partner-url-ae.tcl?[export_url_vars url_id]\">Edit</a> | 
<a href=\"partner-url-delete.tcl?[export_url_vars url_id]\">Delete</a> |
<a href=\"partner-url-sample.tcl?[export_url_vars url_id]\">Preview</a>
"
} 

if { [empty_string_p $url_string] } {
    set url_string "  <LI> There are no registered urls"
}

append page_body "

<b>Registered URL's</b>
<UL>
 $url_string
<P>
  <LI><a href=\"partner-url-ae.tcl?[export_url_vars partner_id]\">Add a url</a>
</UL>
<p> 

<b>Variables | <a href=\"partner-ae.tcl?[export_url_vars partner_id return_url]\">Edit</A></b>
<UL> 
"

if { ![empty_string_p $group_id] } {
    set user_groups_name [database_to_tcl_string $db \
	    "select group_name from user_groups where group_id=$group_id"]
} else {
    set user_groups_name ""
}
set partner_vars [ad_partner_list_all_vars]       

foreach pair $partner_vars {
    set variable [lindex $pair 0]
    set text [lindex $pair 1]
    append page_body "  <li> <b>$text ($variable)</b>: [set $variable]\n"
}

append page_body " 
  <li> <b>Group</b>: $user_groups_name
</ul>
"

ns_return 200 text/html [ad_partner_return_template]