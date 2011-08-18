# $Id: edit-2.tcl,v 3.0.4.1 2000/04/28 15:08:56 carsten Exp $
set_the_usual_form_variables

# the variables will be of the form ${usps_abbrev}_tax_rate and ${usps_abbrev}_shipping_p,
# in addition to usps_abbrev_list (which tells us which of the above we're expecting)

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]
# error checking (must have a tax rate and shipping_p for each state)
set exception_count 0
set exception_text ""
foreach usps_abbrev $usps_abbrev_list {

    if { ![info exists ${usps_abbrev}_tax_rate] || [empty_string_p [set ${usps_abbrev}_tax_rate]] } {
	incr exception_count
	append exception_text "<li>You forgot to enter the tax rate for [ad_state_name_from_usps_abbrev $db $usps_abbrev]"
    } 

    if { ![info exists ${usps_abbrev}_shipping_p] || [empty_string_p [set ${usps_abbrev}_shipping_p]] } {
	incr exception_count
	append exception_text "<li>You forgot to specify whether tax is charged for shipping in [ad_state_name_from_usps_abbrev $db $usps_abbrev]"
    }

}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
}

set old_states_with_taxes_set [database_to_tcl_list $db "select usps_abbrev from ec_sales_tax_by_state"]

ns_db dml $db "begin transaction"

foreach usps_abbrev $usps_abbrev_list {
    if { [database_to_tcl_string $db "select count(*) from ec_sales_tax_by_state where usps_abbrev='$usps_abbrev'"] > 0 } {
	ns_db dml $db "update ec_sales_tax_by_state set tax_rate=[ec_percent_to_decimal [set ${usps_abbrev}_tax_rate]], shipping_p='[set ${usps_abbrev}_shipping_p]', last_modified=sysdate, last_modifying_user='$user_id', modified_ip_address='[DoubleApos [ns_conn peeraddr]]' where usps_abbrev='$usps_abbrev'"
    } else {
	ns_db dml $db "insert into ec_sales_tax_by_state
(usps_abbrev, tax_rate, shipping_p, last_modified, last_modifying_user, modified_ip_address)
values
('$usps_abbrev', [ec_percent_to_decimal [set ${usps_abbrev}_tax_rate]], '[set ${usps_abbrev}_shipping_p]',sysdate, '$user_id', '[DoubleApos [ns_conn peeraddr]]')"
    }
}

# get rid of rows for states where tax is no longer being collected
foreach old_state $old_states_with_taxes_set {
    if { [lsearch $usps_abbrev_list $old_state] == -1 } {
	# then this state is no longer taxable
	ns_db dml $db "delete from ec_sales_tax_by_state where usps_abbrev='$old_state'"
	ad_audit_delete_row $db [list $old_state] [list usps_abbrev] ec_sales_tax_by_state_audit
    }
}

ns_db dml $db "end transaction"

ad_returnredirect index.tcl

