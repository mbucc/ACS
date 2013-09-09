# edit-ad-2.tcl

ad_page_contract {
    @cvs-id edit-ad-2.tcl,v 3.2.6.4 2000/09/22 01:37:52 kevin Exp
} {
    domain_id:integer
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]

db_1row domain_info_get [gc_query_for_domain_info $domain_id]

append html "[gc_header "Your Postings"]

[ad_decorate_top "<h2>Your Postings</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Review Postings"]
" [ad_parameter EditAd2Decoration gc]]

<hr>

<ul>
"

set sql "select *
from classified_ads ca
where domain_id = :domain_id
and user_id= :user_id
order by classified_ad_id desc"

set counter 0

db_foreach gc_edit_ad_2_ads_list $sql -bind [ad_tcl_vars_to_ns_set domain_id user_id] {
    append html "<li><a href=\"edit-ad-3?classified_ad_id=$classified_ad_id\">
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

doc_return  200 text/html $html
