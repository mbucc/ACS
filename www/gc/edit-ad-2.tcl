# $Id: edit-ad-2.tcl,v 3.1 2000/03/10 23:58:23 curtisg Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# domain_id

set user_id [ad_verify_and_get_user_id]

set db [gc_db_gethandle]
set selection [ns_db 1row $db [gc_query_for_domain_info $domain_id]]
set_variables_after_query

append html "[gc_header "Your Postings"]

[ad_decorate_top "<h2>Your Postings</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Review Postings"]
" [ad_parameter EditAd2Decoration gc]]

<hr>

<ul>
"

set selection [ns_db select $db "select *
from classified_ads ca
where domain_id = $domain_id
and user_id=$user_id
order by classified_ad_id desc"]

set counter 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append html "<li><a href=\"edit-ad-3.tcl?classified_ad_id=$classified_ad_id\">
$one_line
</a> (posted [util_AnsiDatetoPrettyDate $posted] in $primary_category)
"
    incr counter
} 

if { $counter == 0 } { 
    append html "<li>You have not posted any ads"
}

append html "</ul>

[gc_footer $maintainer_email]"

ns_return 200 text/html $html
