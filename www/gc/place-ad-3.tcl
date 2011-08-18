# $Id: place-ad-3.tcl,v 3.1 2000/03/10 23:58:29 curtisg Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables


# domain_id, primary_category, html_p, lots of others

set user_id [ad_verify_and_get_user_id]

set db [gc_db_gethandle]

set selection [ns_db 1row $db [gc_query_for_domain_info $domain_id]]
set_variables_after_query

# OK, let's check the input

set exception_text ""
set exception_count 0

if { ![info exists primary_category] || [empty_string_p $primary_category] } {
    append exception_text "<li>Category is NULL.  It looks like your browser isn't passing through all the variables."
    incr exception_count
}


if [catch  { ns_dbformvalue [ns_conn form] expires date expires } errmsg] {
    incr exception_count
    append exception_text "<li>Please make sure your expiration date is valid."
}


if { ![info exists expires] || $expires == "" } {
    append exception_text "<li>Please type in an expiration date."
    incr exception_count
}

if { [info exists full_ad] && ([empty_string_p $full_ad] || ![regexp {[A-Za-z]} $full_ad]) } {
    append exception_text "<li>You forget to type anything for your ad"
    incr exception_count
}


if { [info exists full_ad] && [string length $full_ad] > 3600} {
    append exception_text "<li>Please limit your ad to 3600 characters"
    incr exception_count
}

if { [info exists one_line] && [string match "*<*" $one_line] } {
    append exception_text "<li>Please don't put any &lt; or &gt; characters in the subject line; you risk screwing up the entire forum by adding HTML tags to the subject.\n"
    incr exception_count
}

if { [info exists one_line] && ([empty_string_p $one_line] || ![regexp {[A-Za-z]} $one_line]) } {
    append exception_text "<li>You forget to type anything for your one-line summary.  So your ad won't be viewable from the main page."
    incr exception_count
}

set disallow_uppercase_p [ad_parameter DisallowAllUppercase gc 1]

if { $disallow_uppercase_p && [info exists full_ad] && $full_ad != "" && ![regexp {[a-z]} $full_ad] } {
    append exception_text "<li>Your ad appears to be all uppercase.  ON THE INTERNET THIS IS CONSIDERED SHOUTING.  IT IS ALSO MUCH HARDER TO READ THAN MIXED CASE TEXT.  So we don't allow it, out of decorum and consideration for people who may be visually impaired."
    incr exception_count
}

if { $disallow_uppercase_p && [info exists one_line] && $one_line != "" && ![regexp {[a-z]} $one_line] } {
    append exception_text "<li>Your one line summary appears to be all uppercase.  ON THE INTERNET THIS IS CONSIDERED SHOUTING.  IT IS ALSO MUCH HARDER TO READ THAN MIXED CASE TEXT.  So we don't allow it, out of decorum and consideration for people who may be visually impaired."
    incr exception_count
}

if { [ad_parameter DisallowReducedInSubject gc 0] && [info exists one_line] && [string first "reduced" [string tolower $one_line]] != -1 } {
    append exception_text "<li>Your ad contains the word \"reduced\" in the subject line.  Since you're posting an ad for the first time, it is difficult to see how the price could have been reduced.  Also, it is unclear as to why any buyer would care.  The price is either fair or not fair.  Whether you were at one time asking a higher price doesn't matter."
    incr exception_count
}

if { [ad_parameter DisallowExclamationPointInSubject gc 0] && [info exists one_line] && [string first "!" [string tolower $one_line]] != -1 } {
    append exception_text "<li>Your ad contains an exclamation point.  That isn't really consistent with the design of this Web service, which is attempting to be subtle."
    incr exception_count
}

set ebay_note "<li>You ad contains the string \"ebay\".  We assume that you're talking about the eBay auction Web service.  That's a wonderful service and we're very happy that you're using it.  But presumably the other people using [gc_system_name] are doing so because they aren't thrilled with eBay."

if { [ad_parameter DisalloweBay gc 0] && [info exists one_line] && ([string first "ebay" [string tolower $one_line]] != -1) } {
    append exception_text $ebay_note
    incr exception_count
}

if { [ad_parameter DisalloweBay gc 0] && [info exists full_ad] && ([string first "ebay" [string tolower $full_ad]] != -1) } {
    append exception_text $ebay_note
    incr exception_count
}

set selection [ns_db select $db "select * from ad_integrity_checks where domain_id = $domain_id"]
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    # the interesting ones are $check_code (a piece of Tcl to be
    # executed) and $error_message, in case the code returns true
    if $check_code {
	append exception_text $error_message
	incr exception_count
    }
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}


append html "[gc_header "Approve Ad"]

<h2>Approve Ad</h2>


[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Place Ad, Step 3"]

<hr>


<h3>One-line Summary</h3>

This is the only thing that someone looking at a listing of ads will
see.  It really needs to contain the product and the price and a \"WTB\"
out front if this is a wanted to buy ad.

<p>

Here's what folks will see:  
<blockquote>
<b>$one_line</b>
</blockquote>

<h3>The Full Ad</h3>

<blockquote>

[util_maybe_convert_to_html $full_ad $html_p]

</blockquote>"


if { [info exists html_p] && $html_p == "t" } {

    append html "Note: if the story has lost all of its paragraph breaks then you
probably should have selected \"Plain Text\" rather than HTML.  Use
your browser's Back button to return to the submission form.
"

} else {
    append html " Note: if the story has a bunch of visible HTML tags then you probably should have selected \"HTML\" rather than \"Plain Text\".  Use your browser's Back button to return to the submission form.  " 
}


append html "<p>"

if {$geocentric_p == "t"} {
    append html "<h3>Location</h3>
    <blockquote>"
    
    if {[string length $state] > 0} {
	append html "State: [ad_state_name_from_usps_abbrev $db $state] <br>"
    }
    
    if {[string length $country] > 0} {
	append html "Country: [ad_country_name_from_country_code $db $country] <br>"
    }
}

append html "</blockquote>
<h3>Option 1:  \"I don't like this!\"</h3>

If you don't like the way this ad looks, if the information isn't
correct, if the information isn't sufficient (especially in the
one-line summary), then just use the Back button on your browser to go
back.

<h3>Option 2:  \"This looks fine\"</h3>

If everything looks ok, then just press the big button below and your ad
will be placed.

<p>
<center>

<form method=post action=\"place-ad-4.tcl\">

"

# generate ad_id here so that we can trap double submissions
set classified_ad_id [database_to_tcl_string $db "select classified_ad_id_sequence.nextval from dual"]

append html "
<input type=hidden name=classified_ad_id value=\"$classified_ad_id\">
[export_form_vars expires]
[export_entire_form]

<input type=submit value=\"Place Ad\">
</form>

</center>

[gc_footer $maintainer_email]
"

ns_return 200 text/html $html
