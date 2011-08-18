# $Id: partner-ae-2.tcl,v 3.0.4.1 2000/04/28 15:09:13 carsten Exp $
set_form_variables
# partner_id, partner_name, partner_cookie, default_font_face, default_font_color, 
# title_font_face, title_font_color, group_id, operation
# Plus more partner variables


# Check arguments
set req_vars [list "dp.ad_partner.partner_id" "dp.ad_partner.partner_cookie" "dp.ad_partner.partner_name"]
set err ""
foreach var $req_vars {
    if { ![exists_and_not_null $var] } {
	append err "  <LI> Must specify $var\n"
    }
}
if { ![empty_string_p $err] } {
    ad_partner_return_error "Missing Arguments" "<UL> $err</UL>"
    return
}

dp_process -where_clause "partner_id=${dp.ad_partner.partner_id}"

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "index.tcl?[export_url_vars partner_id]"
}

