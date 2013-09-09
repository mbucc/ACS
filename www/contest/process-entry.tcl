# /www/contest/process-entry.tcl

ad_page_contract {
    @param custom_vars  list of custom variable names
    @param custom       array that maps the custom variable names to their values

    @author Mark Dettinger <mdettinger@arsdigita.com>
    @cvs-id process-entry.tcl,v 3.5.2.8 2000/09/22 01:37:18 kevin Exp
} {
    domain_id:integer,notnull
    {custom_vars:optional [db_null]}
    {custom:array,optional [db_null]}
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# move custom variables from array into individual variables
foreach var $custom_vars {
    set $var $custom($var)
}

if { [ad_read_only_p] } {
    ad_return_read_only_maintenance_message
    return
}

if { ![db_0or1row contest_domain_info "
select entrants_table_name,
       post_entry_url,
       home_url,
       pretty_name,
       maintainer,
       notify_of_additions_p 
from contest_domains where domain_id = :domain_id"] } {
    ad_return_error "Serious problem with the previous form" "Either 
    the previous form didn't say which of the contests 
    in [ad_site_home_link] or the domain_id variable
    was set wrong or something."
    return
}

# if we got here, that means there was a domain_id in the database
# matching the input

set entry_date [db_string date_get "select sysdate from dual"]

set sql "
    insert into $entrants_table_name
    (user_id , entry_date [uncurry concat [map [lambda {v} {return ", $v"}] $custom_vars]])
    values
    (:user_id , :entry_date [uncurry concat [map [lambda {v} {return ", :$v"}] $custom_vars]])
"

if [catch { db_dml contest_entry_insert $sql } errmsg] {
    ad_return_error "Problem Adding Entry" "The database didn't accept your insert.

    <p>

    Here was the message:
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>"
} else {
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

[ad_footer [db_string maintainer_signature "
select email from users where user_id = :maintainer"]]"
        doc_return  200 text/html $the_page
    }
    # insert worked but we might still have to send email
    ns_conn close
    # we've closed the connection, so user isn't waiting
    if { $notify_of_additions_p == "t" } {
	# maintainer says he wants to know
	# wrap in a catch so that a mailer problem doesn't result in user seeing an error
	db_1row maintainer_email "select email as user_email, first_names || ' ' || last_name as name from users where user_id = :user_id"

	catch { ns_sendmail $maintainer_email $user_email "$user_email ($name) entered the $domain contest"  "$user_email ($name) entered the $domain contest" }
    }
}
