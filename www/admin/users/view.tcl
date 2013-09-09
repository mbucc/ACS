# /www/admin/users/view.tcl

ad_page_contract {
    @cvs-id view.tcl,v 3.5.2.6.2.4 2000/09/22 01:36:26 kevin Exp
} {
    category_id:optional,integer
    country_code:optional 
    usps_abbrev:optional 
    intranet_user_p:optional 
    group_id:optional,integer
    last_name_starts_with:optional  
    email_starts_with:optional 
    expensive:optional 
    user_state:optional 
    sex:optional 
    age_above_years:optional  
    age_below_years:optional
    registration_during_month:optional  
    registration_before_days:optional 
    registration_after_days:optional 
    registration_after_date:optional 
    last_login_before_days:optional 
    last_login_after_days:optional 
    last_login_equals_days:optional  
    number_visits_below:optional 
    number_visits_above:optional 
    user_class_id:optional,integer
    sql_post_select:optional 
    crm_state:optional 
    curriculum_elements_completed:optional 
}

# Removed all of the code for order_by since it was broken and will
# never work the way this page is constructed.

# we get a form that specifies a class of user

set description [ad_user_class_description [ns_conn form]]

append whole_page "[ad_admin_header "Users who $description"]

<h2>Users</h2>

[ad_admin_context_bar [list "" "Users"] "View Class"]

<hr>

<p>Class description:  users who $description.

<p>
"

# we print out all the users all of the time 
append whole_page "

<ul>"

set query "
[ad_user_class_query [ns_conn form]]

order by upper(email), 
         upper(last_name),
         upper(first_names)"

if { [catch {

    set count 0
    db_foreach admin_users_view_ordered_query $query {
	incr count
	append whole_page "<li><a href=\"one?user_id=$user_id\">$first_names $last_name</a> ($email) \n"
	
	if {$user_state == "need_email_verification_and_admin_approv" || $user_state ==	"need_admin_approv"}  {
	    append whole_page "<font color=red>$user_state</font> <a href=approve?[export_url_vars user_id]>Approve</a> | <a href=reject?[export_url_vars user_id]>Reject</a>"
	}
    
    }

} err_msg] } {
    ad_return_error "Database Error" "We got the following error trying to run this query:
$err_msg<p><pre>$ordered_query</pre>\n"
    return
}


if { $count == 0 } {
    append whole_page "no users found meeting these criteria"
}

append whole_page "</ul>

[ad_admin_footer]
"



doc_return  200 text/html $whole_page
