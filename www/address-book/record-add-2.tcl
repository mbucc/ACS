# /www/address-book/record-add-2.tcl

ad_page_contract {

    adds an address book record

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
    @param phone_cell
    @param phone_other
    @param country
    @param birthday
    @param birthmonth 
    @param birthyear
    @param days_in_advance_to_remind
    @param days_in_advance_to_remind_2
    @param notes
    @param return_url 

    @cvs-id record-add-2.tcl,v 3.2.2.22 2001/01/09 22:07:33 khy Exp
    @creation-date 12/24/99
    @author teadams@arsdigita.com
    @author tarik@arsdigita.com
} {
    scope:optional
    user_id:optional,integer
    group_id:optional,integer
    address_book_id:verify,integer,notnull
    first_names:trim,notnull
    last_name:trim,notnull
    {email [db_null]}
    {email2 [db_null]}
    {line1 [db_null]}
    {line2 [db_null]}
    {city [db_null]}
    {usps_abbrev [db_null]}
    {zip_code [db_null]}
    {phone_home [db_null]}
    {phone_work [db_null]}
    {phone_cell [db_null]}
    {phone_other [db_null]}
    {country [db_null]}
    {birthday ""}
    {birthmonth ""}
    {birthyear ""}
    {days_in_advance_to_remind:naturalnum [db_null]}
    {days_in_advance_to_remind_2:naturalnum [db_null]}
    {notes [db_null]}
    {return_url "index?[export_url_scope_vars]"}
} -validate {

    day_month_check -requires {birthday birthmonth} {
	if { ![empty_string_p $birthmonth] && ![empty_string_p $birthday] } {
	    if { [catch { db_string date_verify "
	    select to_date('$birthmonth-$birthday','MM-DD') from dual
	    " } errmsg ] } {
		ad_complain "Your date \"$birthmonth-$birthday\" was invalid."
		return 0
	    }
	}
	return 1
    }

    year_check -requires {day_month_check} {
	if { [exists_and_not_null birthyear] } {
	    if { [catch { db_string date_verify "select to_date('$birthmonth-$birthday-$birthyear','MM-DD-YYYY') from dual" } errmsg ] } {
		ad_complain "Your date \"$birthmonth-$birthday-$birthyear\" was invalid."
		return 0
	    }   
	}
	return 1
    }
    
}


# -----------------------------------------------------------------------------

ad_scope_error_check user

ad_scope_authorize $scope none group_admin user

# -----------------------------------------------------------------------------

# If you aren't familiar with functional programming, the following looks
# a bit obscure.  But, you must admit, it is kinda slick and, honestly,
# more straightforward than the old procedural method.

set column_list [list address_book_id first_names \
	last_name email email2 line1 line2 city usps_abbrev zip_code \
	phone_home phone_work phone_cell phone_other country \
	birthmonth birthday birthyear days_in_advance_to_remind \
	days_in_advance_to_remind_2 notes]


set bind_vars [uncurry ad_tcl_vars_to_ns_set $column_list]

ad_dbclick_check_dml -bind $bind_vars \
	 address_book_insert_address address_book address_book_id $address_book_id $return_url "
insert into address_book 
	([join $column_list ","], [ad_scope_cols_sql]) 
values ([join [map [lambda {column} {return ":$column"}] $column_list] ","], [ad_scope_vals_sql])"


db_release_unused_handles


ad_returnredirect "$return_url"
