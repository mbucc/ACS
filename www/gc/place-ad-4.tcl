# $Id: place-ad-4.tcl,v 3.1 2000/03/10 23:58:30 curtisg Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

proc philg_ns_set_to_tcl_string_cat_values {set_id} {
    set result_list [list]
    for {set i 0} {$i<[ns_set size $set_id]} {incr i} {
	lappend result_list "[ns_set value $set_id $i]"
    }
    return [join $result_list " "]
}

set_the_usual_form_variables


# classified_ad_id, domain_id, primary_category, html_p, expires
# plus whatever stuff we have that is custom for each domain

set user_id [ad_verify_and_get_user_id]


# we have to do a bunch of simple integrity tests here because 
# an AOL-type browser might have dropped the hidden vars

set exception_text ""
set exception_count 0

if { ![info exists primary_category] || [empty_string_p $primary_category] } {
    append exception_text "<li>Category is NULL.  It looks like your browser isn't passing through all the variables.  The AOL browser has been known to screw up like this.  Probably it is time to get Netscape...\n"
    incr exception_count
}


if { ![info exists expires] || $expires == "" } {
    append exception_text "<li>Expiration Date is missing.  It looks like your browser isn't passing through all the variables.  Probably time to switch to Netscape Navigator.\n"
    incr exception_count
}


if { ![info exists one_line] || [empty_string_p $one_line] } {
    append exception_text "<li>Your browser dropped your one-line ad summary.\n"
    incr exception_count
}


if { ![info exists full_ad] || [empty_string_p $full_ad] } {
    append exception_text "<li>Your browser dropped your ad.  You need to upgrade to Netscape."
    incr exception_count
}


if { [info exists full_ad] && [string length $full_ad] > 3600} {
    append exception_text "<li>Please limit your ad to 3600 characters"
    incr exception_count
}


if { $exception_count > 0 } {
    ns_log Notice "Ad posting failed at place-ad-5.tcl because of dropped field.  Browser was [util_GetUserAgentHeader]"
    ad_return_complaint $exception_count $exception_text
    return
}


ns_set put [ns_conn form] user_id $user_id
set poster_user_id $user_id

# to provide some SPAM-proofing, we record the IP address
set originating_ip [ns_conn peeraddr]

set db [gc_db_gethandle]

set selection [ns_db 1row $db [gc_query_for_domain_info $domain_id]]
set_variables_after_query

set poster_email [database_to_tcl_string $db "select email
from users where user_id = $poster_user_id"]

set form [ns_conn form]

# add stuff that wasn't just in the form

ns_set cput $form originating_ip $originating_ip

# we don't need to add the posted time because an Oracle trigger
# will do that

# remove stuff that shouldn't be in the INSERT

ns_set delkey $form ColValue.expires.month
ns_set delkey $form ColValue.expires.day
ns_set delkey $form ColValue.expires.year

set insert_sql [util_prepare_insert $db classified_ads classified_ad_id $classified_ad_id $form]


if [catch { ns_db dml $db $insert_sql } errmsg] {
    # something went a bit wrong
    if { [database_to_tcl_string $db "select count(*) from classified_ads where classified_ad_id = $classified_ad_id"] >= 0 } {
	# user hit submit twice, use this to suppress email alerts
	set user_hit_submit_twice_p 1
    } else {
	# not just the user hitting submit twice
	ad_return_error "Error placing $primary_category Ad" "Tried the following SQL:

<pre>
$insert_sql
</pre>

and got back the following:

<blockquote><code>
$errmsg
</blockquote></code>
"
       return
    }
}

# everything went nicely and/or it is a duplicate submission but who cares

append html "[gc_header "Success"]

<h2>Success!</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Ad Placed"]

<hr>

OK, you got your new ad in (#$classified_ad_id).  
You might want to take a moment 
to <a href=\"edit-ad-2.tcl?domain_id=$domain_id\">review your older ads</a> (of which there are [database_to_tcl_string $db "select count(*) from classified_ads 
where domain_id = $domain_id
and user_id = $user_id"], including this one)

"

# Go ahead and write out the HTML,
# so they will have something to look at while we do the emailing.

ReturnHeaders
ns_write $html
set html {}

if { [info exists user_hit_submit_twice_p] && $user_hit_submit_twice_p } {
    # don't bother emailing
    ns_write "[gc_footer $maintainer_email]\n"
} else {
    ns_write "

<p>

Now we're going to look for people who've said that they wanted to be
instantly alerted of new classified ads....

<ul>

"

set selection [ns_db select $db "select classified_email_alerts.alert_id, domain_id, frequency, users_alertable.user_id as alert_user_id, alert_type, category, keywords, expires, email as alert_email
from classified_email_alerts, users_alertable
where classified_email_alerts.user_id= users_alertable.user_id
and domain_id = $domain_id
and frequency = 'instant'
and valid_p = 't'
and sysdate < expires
order by users_alertable.user_id"]

# mush together everything in the form, separated by spaces

set stuff_to_search [philg_ns_set_to_tcl_string_cat_values [ns_conn form]]

set counter 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter
    # ns_log Notice "processing instant classified alert ($alert_email, $domain, $alert_type, category: $category, keywords: $keywords)"

    if { $alert_type == "all" || ( $alert_type == "category" && $category == $primary_category) || ($alert_type == "keywords" && [philg_keywords_match $keywords $stuff_to_search]) } {
	ns_write "<li>sending email to $alert_email ... "
	# ns_log Notice "sending email to $alert_email"

	if [catch {
	    ns_sendmail $alert_email   $poster_email $one_line "[ns_striphtml $full_ad]

Note:  this message was sent to you because you have 
an instant alert in the $domain classifieds.  If you 
want to disable the alert that generated this message,
visit

[gc_system_url]alert-disable.tcl?alert_id=[ns_urlencode $alert_id]

Here are the parameters for this alert:

domain:      $domain
alert type   $alert_type
category     $category
keywords     $keywords
expires      $expires

" } errmsg] {
    ns_write "<p>
Something is horribly wrong with the email handler on this 
computer so we're giving up on sending any email
notifications. Your posting will be enshrined in the database, of course. 

<blockquote>
$errmsg
</blockquote>

</ul>

[ad_footer]"

        ns_return 200 text/html $html
        return
        }
        append html "...  success\n"
    }
}

ns_write "

</ul>

"

if { $counter == 0 } {
    ns_write "<p>Nobody has an alert whose parameters match this ad."
} else {
    ns_write "<p>Note that if any of these people have changed
their email address (or typed it wrong in the first place), you'll get a 
bounce from my mail server.  Ignore it.  Your ad still went into the database.
The reason the bounce comes to you instead of me is that this server forges
email from \"$poster_email\" so that if the potential buyer hits Reply 
the message will go to you and not [gc_system_owner]. "
}

ns_write "

[gc_footer $maintainer_email]" 
}

