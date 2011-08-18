# $Id: post-new-3.tcl,v 3.0.4.1 2000/04/28 15:09:49 carsten Exp $
# File:     /calendar/admin/post-new-3.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  adds new calendar item
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_get_user_id]

set_the_usual_form_variables 0
# calendar_id, title, body, AOLserver ns_db magic vars that can be 
# kludged together to form release_date and expiration_date
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check
set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none

set creation_ip_address [ns_conn peeraddr]

set exception_count 0
set exception_text ""

if [catch  { ns_dbformvalue [ns_conn form] start_date date start_date
             ns_dbformvalue [ns_conn form] end_date date end_date } errmsg] {
    incr exception_count
    append exception_text "<li>Please make sure your dates are valid."
} else {

    # we assume that the event ends at the very end of the end_date
    # we have to do the bogus 1000* and then rounding because of Stupid Oracle
    # driver truncation errors (doesn't like big fractions)
    set expire_laterthan_future_p [database_to_tcl_string $db "select round(1000*(to_date('$end_date  11:59:59', 'YYYY-MM-DD HH24:MI:SS')  - to_date('$start_date', 'YYYY-MM-DD')))  from dual"]
    if {$expire_laterthan_future_p <= 0} {
	incr exception_count
	append exception_text "<li>Please make sure the end date is later than the start date."
    }
}

# now start_date and end_date are set

if { ![info exists title] || $title == ""} {
    incr exception_count
    append exception_text "<li>Please enter a title."
}
if { ![info exists body] || $body == "" } {
    incr exception_count
    append exception_text "<li>Please enter the full story."
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
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

set approved_p "t"

set category_id [database_to_tcl_string $db "
select category_id 
from calendar_categories 
where category='$QQcategory'
and [ad_scope_sql] "]

if [catch { ns_db dml $db "insert into calendar
(calendar_id, category_id, title, body, html_p, approved_p, 
start_date, end_date, 
creation_date, expiration_date,
creation_user, creation_ip_address,
event_url, event_email, 
country_code, usps_abbrev, zip_code)
values
($calendar_id, $category_id, '$QQtitle', '$QQbody', '$html_p', '$approved_p', 
'$start_date', to_date('$end_date  11:59:59', 'YYYY-MM-DD HH24:MI:SS'), 
sysdate, to_date('$end_date  11:59:59', 'YYYY-MM-DD HH24:MI:SS')+[ad_parameter DaysFromEndToExpiration calendar 3],
$user_id, '$creation_ip_address',
[ns_dbquotevalue $event_url text],[ns_dbquotevalue $event_email text],
[ns_dbquotevalue $country_code text],[ns_dbquotevalue $usps_abbrev text],[ns_dbquotevalue $zip_code text])" } errmsg] {
    # insert failed; let's see if it was because of duplicate submission
    if {[database_to_tcl_string $db "select count(*) from calendar where calendar_id = $calendar_id"] == 0 } {
	ns_log Error "/calendar/post-new-3.tcl choked:  $errmsg"
	ad_scope_return_error "Insert Failed" "The Database did not like what you typed.  This is probably a bug in our code.  Here's what the database said:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
" $db
        return
    }
    # we don't bother to handle the cases where there is a dupe submission
    # because the user should be thanked or redirected anyway
}


ad_returnredirect "item.tcl?[export_url_scope_vars calendar_id]"

