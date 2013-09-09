# /www/gc/define-new-category-2.tcl
ad_page_contract {
    We get here when user is placing ad.

    @author xxx
    @date unknown
    @cvs-id define-new-category-2.tcl,v 3.3.6.4 2000/09/22 01:37:51 kevin Exp
} {
    category_id:integer
    domain_id:integer
    primary_category:trim
    ad_placement_blurb:trim
}

if { $primary_category == "" || $ad_placement_blurb == "" } {
    doc_return  200 text/html "Please back up and fill in the form completely"
    return
}

# we have full data

db_dml define_new_category_dml "insert into ad_categories (category_id, domain_id, primary_category, ad_placement_blurb)
values (:category_id, :domain_id, :primary_category, :ad_placement_blurb)
" -bind [ad_tcl_vars_to_ns_set category_id domain_id primary_category ad_placement_blurb]

db_release_unused_handles
ad_returnredirect "place-ad-2.tcl?domain_id=[ns_urlencode $domain_id]&primary_category=[ns_urlencode $primary_category]"
