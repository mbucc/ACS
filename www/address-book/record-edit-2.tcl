# /www/address-book/record-edit-2.tcl

ad_page_contract {

    address book main page

    @param scope
    @param user_id
    @param group_id
    @param address_book_id
    @param first_names
    @param last_name
    @param email
    @param email2
    @param line1
    @param line2
    @param city
    @param usps_abbrev
    @param zip_code
    @param phone_home
    @param phone_work
    @param  phone_cell
    @param phone_other
    @param country
    @param birthmonth
    @param birthday
    @param birthyear
    @param days_in_advance_to_remind
    @param days_in_advance_to_remind_2
    @param notes
    @param return_url

    @cvs-id record-edit-2.tcl,v 3.2.2.16 2000/10/14 00:46:29 bcalef Exp
    @creation-date 12/24/99
    @author teadams@arsdigita.com
    @author tarik@arsdigita.com

} {
    scope:optional
    user_id:optional,integer
    group_id:optional,integer
    address_book_id:integer
    first_names:trim,notnull
    last_name:trim,notnull
    email
    email2
    line1
    line2
    city
    usps_abbrev
    zip_code
    phone_home
    phone_work
    phone_cell
    phone_other
    country
    { birthmonth:naturalnum,optional "" }
    { birthday:naturalnum,optional "" }
    { birthyear:optional "" }
    days_in_advance_to_remind:naturalnum,optional
    days_in_advance_to_remind_2:naturalnum,optional
    notes
    return_url:optional
} -validate {
    is_valid_date {
    if { [exists_and_not_null birthmonth] && [exists_and_not_null birthday] } {
	if { [catch { db_string date_verify "select to_date('$birthmonth-$birthday','MM-DD') from dual" } errmsg ] } {
	    ad_complain "Your date \"$birthmonth-$birthday\" was invalid."
	}
	if { [exists_and_not_null birthyear] } {
	    if { [catch { db_string date_verify "select to_date('$birthmonth-$birthday-$birthyear','MM-DD-YYYY') from dual" } errmsg ] } {
		ad_complain "Your date \"$birthmonth-$birthday-$birthyear\" was invalid."
	    }   
	}
    }   
return 1
}
}

ad_scope_error_check user

ad_scope_authorize  $scope none group_admin user

set column_list [list first_names last_name email email2 line1 line2 city usps_abbrev zip_code phone_home phone_work phone_cell phone_other country birthmonth birthday birthyear days_in_advance_to_remind days_in_advance_to_remind_2 notes]

foreach column $column_list {
    lappend column_and_value_list "$column = :$column"
}

db_dml address_book_update "
update address_book 
set    [join $column_and_value_list ,] 
where  address_book_id= :address_book_id"


db_release_unused_handles

if [info exists return_url] {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "record?[export_url_scope_vars address_book_id]"
}
