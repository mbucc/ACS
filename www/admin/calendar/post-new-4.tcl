ad_page_contract {
    Inserts into the calendar table
    
    @author ???
    @creation-date 09/22/2000
    @cvs-id post-new-4.tcl,v 3.3.2.4 2001/01/10 16:32:01 khy Exp
} {
    calendar_id:naturalnum,notnull,verify
    category:notnull
    title:notnull
    body:allhthml
    html_p:notnull
    approved_p:notnull
    event_url
    event_email
    country_code
    usps_abbrev
    zip_code
}


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

# set_the_usual_form_variables

# calendar_id, title, body, AOLserver ns_db magic vars that can be 
# kludged together to form release_date and expiration_date

set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl"
    return
}

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
    set expire_laterthan_future_p [db_string unused "select round(1000*(to_date('$end_date  11:59:59', 'YYYY-MM-DD HH24:MI:SS')  - to_date('$start_date', 'YYYY-MM-DD')))  from dual"]
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
    ad_return_complaint $exception_count $exception_text
    return
}



set approved_p "t"

if [catch { 
    db_dml unused "
	insert into calendar (
	    calendar_id		,  
	    category		, 
	    title		, 
	    body		, 
	    html_p		, 
	    approved_p		, 
	    start_date		, 
	    end_date		, 
	    creation_date	, 
	    expiration_date	,
	    creation_user	, 
	    creation_ip_address	,
	    event_url		, 
	    event_email		, 
	    country_code	, 
	    usps_abbrev		, 
	    zip_code 
	) values (
	    :calendar_id	,
	    :category		, 
	    :title		, 
	    :body		, 
	    :html_p		,   
	    :approved_p		, 
	    :start_date		, 
	    to_date('end_date  11:59:59', 'YYYY-MM-DD HH24:MI:SS'), 
	    sysdate		, 
	    to_date('$end_date  11:59:59', 'YYYY-MM-DD HH24:MI:SS')+[ad_parameter DaysFromEndToExpiration calendar 3],
	    :user_id		,
	    :creation_ip_address,
	    :event_url		,
	    :event_email	,
	    :country_code	, 
	    :usps_abbrev text	, 
	    :zip_code) 
    } errmsg] {
    # insert failed; let's see if it was because of duplicate submission
    if {[db_string unused "select count(*) from calendar where calendar_id = :calendar_id"] == 0 } {
	ns_log Error "/calendar/post-new-3.tcl choked:  $errmsg"
	ad_return_error "Insert Failed" "The Database did not like what you typed.  This is probably a bug in our code.  Here's what the database said:
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

if { [ad_parameter ApprovalPolicy calendar] == "open"} {
    ad_returnredirect "index.tcl"
} else {
    doc_return  200 text/html "[ad_admin_header "Thank you"]

<h2>Thank you</h2>

for your submission to <a href=\"index\">[ad_parameter SystemName calendar "Calendar"]</a>

<hr>

Your submission will be reviewed by 
[ad_parameter SystemOwner calendar [ad_system_owner]].

[ad_admin_footer]"
}

