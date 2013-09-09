ad_page_contract {
    let's test out our spamming system to remind people who've placed ads
    
    @author xxx
    @date unknown
    @cvs-id test.tcl,v 3.2.6.5 2000/09/22 01:35:23 kevin Exp
}

append html "<ul>"

set generic_preamble "

In the interests of having a well-groomed classified ad system for
everyone, we're sending you this robotically generated message to
remind you to

1) delete ads for items that have sold
2) consider updating the price on items that haven't sold
3) delete duplicate ads

It is effort like this on the part of the users that makes it possible
to offer this service for free.

Here are the ads you've placed to date:

"

set generic_postamble "

Thank you for using [gc_system_name]
(at [gc_system_url]).
"

db_foreach classified_ads_report "
     select
       max(email) as email,
       max(domain_id) as domain_id,
       max(last_modified) as most_recent_visit,
       min(last_modified) as least_recent_visit,
       count(*) as n_ads
     from classified_ads c, users u
     where c.user_id = u.user_id
     and (sysdate <= expires or expires is null)
     and (wanted_p <> 't' or sysdate > (last_modified + 30))
     and sysdate > last_modified + 6
     group by email
" {
    
    append html "<li>$email has $n_ads, most recent edit was $most_recent_visit; oldest ad hasn't been touched since $least_recent_visit.  URL:  <a href=\"[gc_system_url]edit-ad-2?poster_email=[ns_urlencode $email]&domain_id=$domain_id\">edit them</a>\n"

    if { $n_ads == 1 } {
	set subject_line "your ad in [gc_system_name]"
    } else {
	set subject_line "your $n_ads ads in [gc_system_name]"
    }
    set body $generic_preamble
    set expired_section_started_yet_p 0
    
    db_foreach your_classified_ads {
	select
	classified_ad_id,
	posted,
	last_modified,
	one_line,
	expired_p(expires) as expired_p
	from classified_ads c, users u
	where c.user_id = u.user_id
	and email = :email
	order by expired_p, classified_ad_id desc
    } {
	if { $last_modified == $posted || $last_modified == "" } {
	    set modified_phrase ""
	} else {
	    set modified_phrase "(modified $last_modified)"
	}
	if { $expired_p == "t" } {
	    if { !$expired_section_started_yet_p } {
		append body "\n    -- expired ads --  \n\n"
		set expired_section_started_yet_p 1
	    }
	    set expired_phrase "(EXPIRED)"
	} else {
	    set expired_phrase ""
	}
        append body "${posted}${expired_phrase} : $one_line $modified_phrase [gc_system_url]edit-ad-3.tcl?classified_ad_id=$classified_ad_id
        "
    }
    if { $expired_p == "t" } {
	# there was at least one expired ad
	append body "\n\nNote:  you can revive an expired ad by going to the edit URL (above)
and changing the expiration date."
    }
    append body $generic_postamble
    append html "<pre>
Subject: $subject_line
Body:
$body
</pre>
"
}

append html "</ul>"

doc_return  200 text/html $html



