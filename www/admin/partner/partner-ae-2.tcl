# /www/admin/partner/partner-ae-2.tcl

ad_page_contract {

    Writes partner info to database. Note that we cannot use the
    ad_page_contract here for all the fields because the exact fields we
    expect can change at runtime

    @param dp.ad_partner.partner_id primary key
    @param dp.ad_partner.partner_name name of the partner
    @param dp.ad_partner.partner_cookie unique key to use as an identifier
    @param dp.ad_partner.default_font_face 
    @param dp.ad_partner.default_font_color 
    @param dp.ad_partner.title_font_face 
    @param dp.ad_partner.title_font_color 
    @param dp.ad_partner.group_id what group do they belong to
    @param return_url 

    @author mbryzek@arsdigita.com
    @creation-date 10/1999

    @cvs-id partner-ae-2.tcl,v 3.2.2.5 2000/07/30 19:03:03 mbryzek Exp
} {
    partner_id:naturalnum,notnull,verify
    partner_cookie:trim,notnull
    partner_name:trim,notnull
    { group_id:naturalnum "" }
    { return_url "" }
}

set bind_vars [ns_set create]
ns_set put $bind_vars partner_id $partner_id
ns_set put $bind_vars dp.ad_partner.partner_id $partner_id
ns_set put $bind_vars dp.ad_partner.group_id $group_id

set form [ns_getform]
# get the list of variables
foreach var_triplet [ad_partner_list_all_vars] {
    set variable_name [lindex $var_triplet 0]
    ns_set update $bind_vars dp.ad_partner.$variable_name [ns_set get $form $variable_name]
}

# Use the -set_id tag to bypass the ad_page_contract check
dp_process -set_id $bind_vars -where_clause "partner_id=:partner_id"

ns_set free $bind_vars

db_release_unused_handles

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "index"
}

