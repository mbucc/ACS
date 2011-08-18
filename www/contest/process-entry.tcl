# $Id: process-entry.tcl,v 3.3.2.1 2000/04/28 15:09:54 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# domain_id then possibly a bunch of user-defined stuff 

set db [ns_db gethandle]

if { ![info exists domain_id] && [info exists domain] } {
    set domain_id [database_to_tcl_string_or_null $db "select domain_id from contest_domains where domain='$QQdomain'"]
    set QQdomain_id [DoubleApos $domain_id]
}

# test for integrity

if { ![info exists domain_id] || $domain_id == "" || [set selection [ns_db 0or1row $db "select * from contest_domains where domain_id = '$QQdomain_id'"]] == "" } {
    ad_return_error "Serious problem with the previous form" "Either the previous form didn't say which of the contests in [ad_site_home_link]
or the domain_id variable
was set wrong or something."
    return
}

set user_id [ad_get_user_id]

if {$user_id == 0} {
   ad_returnredirect "/register.tcl?return_url=[ns_urlencode "/contest/entry-form.tcl?[export_url_vars domain_id]"]"
    return
}

# if we got here, that means there was a domain_id in the database
# matching the input

set_variables_after_query

set exception_text ""
set exception_count 0

# put in some from the user-defined forms maybe

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# if we got here, it means that the user input mostly checked

# we have to add the entry_date and user_id to the ns_set 

ns_set put [ns_conn form] entry_date [database_to_tcl_string $db "select sysdate from dual"]
ns_set put [ns_conn form] user_id $user_id

# we have to take out domain because we used it to figure out which table

ns_set delkey [ns_conn form] domain_id
ns_set delkey [ns_conn form] domain

set sql [util_prepare_insert_no_primary_key $db $entrants_table_name [ns_conn form]]

if [catch { ns_db dml $db $sql } errmsg] {
    ad_return_error "Problem Adding Entry" "The database didn't accept your insert.

<p>

Here was the message:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"} else {
    # insert was successful 
    if { ![empty_string_p $post_entry_url] } {
	ad_returnredirect $post_entry_url
    } else {
	# no custom page
	set the_page "[ad_header "Entry Successful"]

<h2>Entry Successful</h2>
to  <a href=\"$home_url\">$pretty_name</a>
<hr>

The information that you typed has been recorded in the database.
Note that while this software will be happy to accept further
submissions from you, in the end winners are chosen from
<em>distinct</em> entrants.  For example, if the drawing is held
monthly, entering N more times during the same month will not improve
your odds of winning a prize.  You'd have to wait until the next month
to enter again if you want your entry to have any effect.
"
       set maintainer_email [database_to_tcl_string $db "select email from users where user_id = $maintainer"]
       append the_page [ad_footer $maintainer_email]
       ns_return 200 text/html $the_page
    }
    # insert worked but we might still have to send email
    ns_conn close
    # we've closed the connection, so user isn't waiting
    if { $notify_of_additions_p == "t" } {
	# maintainer says he wants to know
	# wrap in a catch so that a mailer problem doesn't result in user seeing an error
	set selection [ns_db 1row $db "select email as user_email, first_names || ' ' || last_name as name from users where user_id = $user_id"]
	set_variables_after_query
	catch { ns_sendmail $maintainer_email $user_email "$user_email ($name) entered the $domain contest"  "$user_email ($name) entered the $domain contest" }
    }
}
