# www/calendar/admin/post-new-3.tcl
ad_page_contract {
    Step 3/3 in adding a new calendar item - Insert
    There is no confirmation step for the admin pages

    Number of queries: 2

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id post-new-3.tcl,v 3.2.2.8 2001/01/10 16:38:07 khy Exp
    
} {
    category_id:naturalnum,notnull
    calendar_id:naturalnum,notnull,verify
    title
    body:allhtml
    html_p
    event_url
    event_email
    country_code
    {usps_abbrev ""}
    {zip_code ""}
    {scope public}
    {user_id:naturalnum ""}
    {group_id:naturalnum ""}
    {on_what_id:naturalnum ""}
    {on_which_group:naturalnum ""}
}

# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

# calendar_id, title, body, AOLserver ns_db magic vars that can be 
# kludged together to form release_date and expiration_date
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check

set user_id [ad_scope_authorize $scope admin group_admin none]


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


set creation_ip_address [ns_conn peeraddr]


## Check for Naughty Input
if { $html_p && ![empty_string_p [ad_check_for_naughty_html $body]] } {

    set naughty_tag_list [ad_parameter_all_values_as_list NaughtyTag antispam]
    set naughty_tag_string [join $naughty_tag_list " "]
    ad_scope_return_complaint 1 "You attempted to submit one of these forbidden HTML tags: $naughty_tag_string"
    return
}



set exception_count 0
set exception_text ""

if [catch  { 

    ns_dbformvalue [ns_conn form] start_date date start_date
    ns_dbformvalue [ns_conn form] end_date date end_date 

} errmsg] {
    
    incr exception_count
    append exception_text "<li>Please make sure your dates are valid."

} else {

    # we assume that the event ends at the very end of the end_date
    # we have to do the bogus 1000* and then rounding because of Stupid Oracle
    # driver truncation errors (doesn't like big fractions)

    set end_date_with_time "$end_date  11:59:59"

    set query_expire "select round(1000*(to_date(:end_date_with_time, 'YYYY-MM-DD HH24:MI:SS')  - to_date('$start_date', 'YYYY-MM-DD')))  from dual"

    set expire_laterthan_future_p [db_string expire $query_expire]
    if {$expire_laterthan_future_p <= 0} {
	incr exception_count
	append exception_text "<li>Please make sure the end date is later than the start date."
    }
}

# now start_date and end_date are set


## Verify that the category_id exists
## and that it has the proper scope -MJS
if { ![db_0or1row query_category_id "
select category_id 
from calendar_categories 
where category_id = :category_id
and [ad_scope_sql]" ] } {
    incr exception_count
    append exception_text "<li>We couldn't locate the category you chose."
}


if { ![info exists title] || $title == ""} {
    incr exception_count
    append exception_text "<li>Please enter a title."
}


if { ![info exists body] || $body == "" } {
    incr exception_count
    append exception_text "<li>Please enter the full event description."
}


if { [info exists event_email] && ![empty_string_p $event_email] && ![philg_email_valid_p $event_email] } {
    incr exception_count
    append exception_text "<li>The event contact email address that you typed doesn't look right to us.  Examples of valid email addresses are 
    <ul>
    <li>Alice1234@aol.com
    <li>joe_smith@hp.com
    <li>pierre@inria.fr
    </ul>
    "
}


if { [info exists event_url] && ![philg_url_valid_p $event_url] } {
    set event_url ""
}


if {$exception_count > 0} { 
    ad_scope_return_complaint $exception_count $exception_text
    return
}

set approved_p "t"

set end_date_with_time "$end_date  11:59:59"

set param_DaysFromEndToExpiration [ad_parameter DaysFromEndToExpiration calendar 3]

set dml_item_insert "insert into calendar
(calendar_id, category_id, title, body, html_p, approved_p, 
start_date, end_date, 
creation_date, expiration_date,
creation_user, creation_ip_address,
event_url, event_email, 
country_code, usps_abbrev, zip_code)
values
(:calendar_id, :category_id, :title, :body, :html_p, :approved_p, 
:start_date, to_date(:end_date_with_time, 'YYYY-MM-DD HH24:MI:SS'), 
sysdate, to_date(:end_date_with_time, 'YYYY-MM-DD HH24:MI:SS') + :param_DaysFromEndToExpiration,
:user_id, :creation_ip_address,
:event_url, :event_email,
:country_code, :usps_abbrev, :zip_code)
"

if [catch { db_dml item_insert $dml_item_insert} errmsg] {

    # insert failed; let's see if it was because of duplicate submission

    set query_count_this_id "select count(*) from calendar where calendar_id = :calendar_id"

    if { [db_string count_this_id $query_count_this_id] == 0 } {

	ns_log Error "/calendar/post-new-3.tcl choked:  $errmsg"
	
	ad_scope_return_error "Insert Failed" "The Database did not like what you typed.  
	This is probably a bug in our code.  Here's what the database said:
	<blockquote>
	<pre>
	$errmsg
	</pre>
	</blockquote>
	"
        return
    }

    # we don't bother to handle the cases where there is a dupe submission
    # because the user should be thanked or redirected anyway
}

db_release_unused_handles

ad_returnredirect "item.tcl?[export_url_scope_vars calendar_id]"

## END FILE post-new-3.tcl



