ad_page_contract {
    @cvs-id view-csv.tcl,v 3.2.2.3.2.2 2000/09/22 01:36:25 kevin Exp

    view-csv.tcl
 
    by philg@mit.edu on October 30, 1999
 
    returns a comma-separated values file where each row is one
    user in a class (designated by the args); this CSV file is 
    suitable for importation into any standard spreadsheet program
} {
} 

ad_maybe_redirect_for_registration

set admin_user_id [ad_verify_and_get_user_id]

# we get a form that specifies a class of user, plus maybe an order_by
# spec

set description [ad_user_class_description [ns_conn form]]



set new_set [ns_set copy [ns_conn form]]
ns_set put $new_set include_contact_p 1
ns_set put $new_set include_demographics_p 1

set query [ad_user_class_query $new_set]
append ordered_query $query "\n" "order by upper(last_name),upper(first_names), upper(email)"


# put a db_with_handle around this until the csv functions updated!!!

db_with_handle db {
    set selection [ns_db select $db $ordered_query]
    set count 0
    set csv_rows ""
    while { [ns_db getrow $db $selection] } {
	set_csv_variables_after_query
	incr count
	# make sure not to put any spaces after the commas or Excel
	# will treat the " as part of the field!
	append csv_rows "$QEQQemail,$QEQQlast_name,$QEQQfirst_names\n"
    }
}

append whole_page $csv_rows



doc_return  200 text/plain $whole_page
