# /www/admin/users/view-verbose.tcl

ad_page_contract {

    Displays an HTML page with a list of the users in a class

    @author teadams@mit.edu
    @author philg@mit.edu
    @cvs-id view-verbose.tcl,v 3.4.2.5.2.4 2000/09/22 01:36:25 kevin Exp
    
} {
    {order_by ""}
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

# we get a form that specifies a class of user, plus maybe an order_by
# spec

set description [ad_user_class_description [ns_conn form]]

append whole_page "[ad_admin_header "Users who $description"]

<h2>Users</h2>

who $description among <a href=\"index\">all users of [ad_system_name]</a>

<hr>

"

if { $order_by == "email" } {
    set order_by_clause "order by upper(email),upper(last_name),upper(first_names)"
    set option "<a href=\"view?order_by=name&[export_entire_form_as_url_vars]\">sort by name</a>"
} else {
    set order_by_clause "order by upper(last_name),upper(first_names), upper(email)"
    set option "<a href=\"view?order_by=email&[export_entire_form_as_url_vars]\">sort by email address</a>"
}



# we print out all the users all of the time 
append whole_page "

$option

<ul>"

set new_set [ns_set copy [ns_conn form]]
ns_set put $new_set include_contact_p 1
ns_set put $new_set include_demographics_p 1
set query [ad_user_class_query $new_set]
append ordered_query $query "\n" $order_by_clause

set count 0
db_foreach admin_users_view_verbose_ordered_query $ordered_query {
    incr count
    append whole_page "<li><a href=\"one?user_id=$user_id\">$first_names $last_name</a> ($email)"
    if ![empty_string_p $demographics_summary] {
	append whole_page ", $demographics_summary"
    }
    if ![empty_string_p $contact_summary] {
	append whole_page ", $contact_summary"
    }
    append whole_page "\n"
}

if { $count == 0 } {
    append whole_page "no users found meeting these criteria"
}

append whole_page "</ul>
[ad_admin_footer]
"

doc_return  200 text/html $whole_page
