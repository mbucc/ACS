# /www/gc/place-ad-4.tcl
ad_page_contract {
    @cvs_id place-ad-4.tcl,v 3.4.2.10 2001/01/10 19:03:38 khy Exp
} {
    domain_id:naturalnum
    classified_ad_id:naturalnum,notnull,verify
    primary_category
    one_line:notnull,nohtml
    full_ad:html,notnull
    html_p
    expires:array,date
    {state ""}
    {country ""}
    {wanted_p ""}
    {ad_auction_p ""}
    {manufacturer ""}
    {model "" }
    {item_size "" }
    {color "" }
    {us_citizen_p "" }
} -validate {
    full_ad_3600 -requires { full_ad } {
	if {[string length $full_ad] > 3600} {
	    ad_complain 
	}
    }

    full_ad_uppercase -requires { full_ad } {
	if {[ad_parameter DisallowAllUppercase gc 1] && [gc_shouting_p $full_ad] } {
	    ad_complain 
	}
    }

    one_line_uppercase -requires { one_line } {
	if {[ad_parameter DisallowAllUppercase gc 1] && [gc_shouting_p $one_line] } {
	    ad_complain 
	}
    }

    one_line_reduced -requires { one_line } {
	if { [ad_parameter DisallowReducedInSubject gc 0] && [string first "reduced" [string tolower $one_line]] != -1 } {
	    ad_complain 
	}
    }

    one_line_exclamation_point -requires { one_line } {
	if { [ad_parameter DisallowExclamationPointInSubject gc 0] && [string first "!" [string tolower $one_line]] != -1 } {
	    ad_complain 
	}
    }

    one_line_ebay -requires { one_line } {
	if { [ad_parameter DisalloweBay gc ] && ([string first "ebay" [string tolower $one_line]] != -1) } {
	    ad_complain 
	}
    }

    full_ad_ebay -requires { full_ad } {
	if { [ad_parameter DisalloweBay gc ] && ([string first "ebay" [string tolower $one_line]] != -1) } {
	    ad_complain 
	}
    }
} -errors {
    primary_category {Category is NULL.  It looks like your browser isn't passing through all the variables.  The AOL browser has been known to screw up like this.  Probably it is time to get Netscape...}
    one_line {Your ad must contain a one line summary.}
    one_line:notnull {Your ad must contain a one line summary.}
    full_ad {The ad must contain description text.}
    full_ad:notnull {The ad must contain description text.}
    full_ad_3600 {Please limit your ad to 3600 characters.}
    expires {You must indicate an expiration date.}
    one_line:nohtml {Please don't put any &lt; or &gt; characters in the subject line; you risk screwing up the entire forum by adding HTML tags to the subject.}
    full_ad_uppercase {Your ad appears to be all uppercase.  ON THE INTERNET THIS IS CONSIDERED SHOUTING.  IT IS ALSO MUCH HARDER TO READ THAN MIXED CASE TEXT.  So we don't allow it, out of decorum and consideration for people who may be visually impaired.}
    one_line_uppercase {Your one line appears to be all uppercase.  ON THE INTERNET THIS IS CONSIDERED SHOUTING.  IT IS ALSO MUCH HARDER TO READ THAN MIXED CASE TEXT.  So we don't allow it, out of decorum and consideration for people who may be visually impaired.}
    one_line_reduced {Your ad contains the word "reduced" in the subject line.  Since you're posting an ad for the first time, it is difficult to see how the price could have been reduced.  Also, it is unclear as to why any buyer would care.  The price is either fair or not fair.  Whether you were at one time asking a higher price doesn't matter}
    one_line_exclamation_point {Your ad contains an exclamation point.  That isn't really consistent with the design of this Web service, which is attempting to be subtle.}
    one_line_ebay {Your one line description contains the string "ebay".  We assume that you're talking about the eBay auction Web service.  That's a wonderful service and we're very happy that you're using it.  But presumably the other people using this service are doing so because they aren't thrilled with eBay.} 
    full_ad_ebay {Your ad contains the string "ebay".  We assume that you're talking about the eBay auction Web service.  That's a wonderful service and we're very happy that you're using it.  But presumably the other people using this service are doing so because they aren't thrilled with eBay.}   
}


set user_id [ad_verify_and_get_user_id]
set poster_user_id $user_id
set originating_ip [ns_conn peeraddr]
set page_content ""

# This selects domain, full_noun, domain_type, auction_p, geocentric_p,
# wtb_common_p, primary_maintainer_id, maintainer_email

db_1row domain_info_get [gc_query_for_domain_info $domain_id]

# Unfortunately, we really wanted auction_p to be the user's choice
# about whether to accept bids.  Guess that wasn't such a good idea 
# after all

set auction_p $ad_auction_p

set poster_email [db_string email_from_users {
    select email
    from users where user_id = :poster_user_id
}]
		  
set form_set [ns_set create]
ns_set put $form_set user_id $user_id
ns_set put $form_set originating_ip $originating_ip
ns_set put $form_set expires $expires(date)

foreach form_var {primary_category classified_ad_id domain_id one_line full_ad html_p state country wanted_p auction_p manufacturer model item_size color us_citizen_p} {
    if { [exists_and_not_null $form_var] } {
	ns_set put $form_set $form_var [set $form_var]
    }
}

set sql_statement_and_bind_vars [util_prepare_insert classified_ads $form_set]
set sql_statement [lindex $sql_statement_and_bind_vars 0]
set bind_vars [lindex $sql_statement_and_bind_vars 1]

if [catch { db_dml gc_place_ad_4_insert $sql_statement -bind $bind_vars} errmsg] {
    # something went a bit wrong
    if { [db_string unused "select count(*) from classified_ads where classified_ad_id = $classified_ad_id"] >= 1 } {
	# user hit submit twice, use this to suppress email alerts
	set user_hit_submit_twice_p 1
    } else {
	# not just the user hitting submit twice
	ad_return_error "Error placing $primary_category Ad" "Tried the following SQL:

<pre>
$sql_statement
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

append page_content "[gc_header "Success"]

<h2>Success!</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Ad Placed"]

<hr>

OK, you got your new ad in (#$classified_ad_id).  
You might want to take a moment 
to <a href=\"edit-ad-2?domain_id=$domain_id\">review your older ads</a> (of which there are [db_string unused "select count(*) from classified_ads 
where domain_id = $domain_id
and user_id = $user_id"], including this one)

"

# Go ahead and write out the HTML,
# so they will have something to look at while we do the emailing.


if { [info exists user_hit_submit_twice_p] && $user_hit_submit_twice_p } {
    # don't bother emailing
    append page_content "[gc_footer $maintainer_email]\n"
} else {
    append page_content "

<p>

Now we're going to look for people who've said that they wanted to be
instantly alerted of new classified ads....

<ul>

"

# mush together everything in the form, separated by spaces

set stuff_to_search [philg_ns_set_to_tcl_string_cat_values [ns_conn form]]

set counter 0
set ora_date $expires(date)

if { [info exists column_value] } {
    unset column_value   
}

unset expires
db_foreach gc_place_ad_4_alert_info {
    select classified_email_alerts.alert_id, domain_id, frequency, users_alertable.user_id as alert_user_id, alert_type, category, keywords, expires, email as alert_email
    from classified_email_alerts, users_alertable
    where classified_email_alerts.user_id= users_alertable.user_id
    and domain_id = :domain_id
    and frequency = 'instant'
    and valid_p = 't'
    and sysdate < to_date(:ora_date,'YYYY-MM-DD')
    order by users_alertable.user_id
} {  incr counter
    ns_log Notice "OK!"
    if { $alert_type == "all" || ( $alert_type == "category" && $category == $primary_category) || ($alert_type == "keywords" && [philg_keywords_match $keywords $stuff_to_search]) } {
	append page_content "<li>sending email to $alert_email ... "
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
    append page_content "<p>
Something is horribly wrong with the email handler on this 
computer so we're giving up on sending any email
notifications. Your posting will be enshrined in the database, of course. 

<blockquote>
$errmsg
</blockquote>

</ul>

[ad_footer]"

        doc_return  200 text/html $page_content
        return
        }
        append page_content "...  success\n"
    }
} if_no_rows {


} 

append page_content "

</ul>

"

if { $counter == 0 } {
    append page_content "<p>Nobody has an alert whose parameters match this ad."
} else {
    append page_content "<p>Note that if any of these people have changed
their email address (or typed it wrong in the first place), you'll get a 
bounce from my mail server.  Ignore it.  Your ad still went into the database.
The reason the bounce comes to you instead of me is that this server forges
email from \"$poster_email\" so that if the potential buyer hits Reply 
the message will go to you and not [gc_system_owner]. "
}

append page_content "

[gc_footer $maintainer_email]" 
}

doc_return  200 text/html $page_content

