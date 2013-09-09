# /www/gc/place-ad-3.tcl

ad_page_contract {
    @cvs_id place-ad-3.tcl,v 3.3.2.10 2001/01/10 19:03:10 khy Exp
} {
    domain_id:naturalnum
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

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


set user_id [ad_verify_and_get_user_id]

# This selects domain, full_noun, domain_type, auction_p, geocentric_p,
# wtb_common_p, primary_maintainer_id, maintainer_email

db_1row domain_info_get [gc_query_for_domain_info $domain_id]

set sql "select * from ad_integrity_checks where domain_id = :domain_id"

set exception_count 0
set exception_text ""
db_foreach integrity_check $sql -bind [ad_tcl_vars_to_ns_set domain_id] {
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
	append html "State: [ad_state_name_from_usps_abbrev $state] <br>"
    }
    
    if {[string length $country] > 0} {
	append html "Country: [ad_country_name_from_country_code $country] <br>"
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

<form method=post action=\"place-ad-4\">

"

# generate ad_id here so that we can trap double submissions
set classified_ad_id [db_string ad_id_get "select classified_ad_id_sequence.nextval from dual"]

set expires.month $expires(month)
set expires.year $expires(year)
set expires.day $expires(day)

append html "
[export_form_vars -sign classified_ad_id]
[export_form_vars domain_id primary_category one_line full_ad html_p manufacturer model item_size color us_citizen_p state country wanted_p ad_auction_p expires.month expires.year expires.day]

<input type=submit value=\"Place Ad\">
</form>

</center>

[gc_footer $maintainer_email]
"

doc_return  200 text/html $html

