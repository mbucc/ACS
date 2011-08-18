# $Id: define-new-category-2.tcl,v 3.1.2.3 2000/04/28 15:10:30 carsten Exp $
# we get here when user is placing ad

set_form_variables
set_form_variables_string_trim_DoubleAposQQ

# category_id, domain_id, primary_category, ad_placement_blurb

if { $primary_category == "" || $ad_placement_blurb == "" } {
    ns_return 200 text/html "Please back up and fill in the form completely"
    return
}

# we have full data

set insert_sql "insert into ad_categories (category_id, domain_id, primary_category, ad_placement_blurb)
values ($category_id, $domain_id, '$QQprimary_category', '$QQad_placement_blurb')"

set db [gc_db_gethandle]
ns_db dml $db $insert_sql

ad_returnredirect "place-ad-2.tcl?domain_id=[ns_urlencode $domain_id]&primary_category=[ns_urlencode $primary_category]"
