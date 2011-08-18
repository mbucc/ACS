# $Id: place-bid-2.tcl,v 3.1 2000/03/10 23:58:31 curtisg Exp $
set_the_usual_form_variables

# bid_id, location, bid, currency

set user_id [ad_get_user_id]

# strip the dollar sign out of the bid

regsub -all {\$} $bid "" sanitized_bid
set bid [string trim $sanitized_bid]

set exception_text ""
set exception_count 0


if { ![info exists bid] || $bid == "" } {
    append exception_text "<li>You did not enter your bid.  This makes an auction kind of tough.\n"
    incr exception_count
}

if { ![info exists bid] || [regexp {[^0-9.]} $bid] } { 
    append exception_text "<li>A bid should just be a number, e.g., \"50\" or \"325.95\".  Do not put any kind of currency symbol, e.g., a dollar sign, in front, or any spaces in the middle.  Otherwise the database is going to reject the bid.\n"
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set db [gc_db_gethandle]

# get stuff for user interface

set selection [ns_db 1row $db "select domain_id, days_since_posted(posted), users.email as poster_email, users.first_names || ' ' || users.last_name as poster_name, one_line, posted, full_ad, auction_p, users.user_id as poster_user_id
from classified_ads, users
where classified_ads.user_id = users.user_id
and classified_ad_id = $classified_ad_id"]

set_variables_after_query

# now domain_id is set, so we'll get info for a backlink

set selection [ns_db 1row $db [gc_query_for_domain_info $domain_id]]
set_variables_after_query

set insert_sql "insert into classified_auction_bids (bid_id, classified_ad_id,bid,currency,bid_time,location,user_id)
values
($bid_id, $classified_ad_id,$bid,'$QQcurrency',sysdate,'$QQlocation',$user_id)"

if [catch { ns_db dml $db $insert_sql } errmsg] {
    # something went a bit wrong
    ns_return 200 text/html "[gc_header "Error placing Bid"]

<h2>Error Placing Bid</h2>

in <a href=\"domain-top.tcl?domain_id=$domain_id\">$full_noun Classifieds</a>

<p>

Tried the following SQL:

<pre>
$insert_sql
</pre>

and got back the following:

<blockquote><code>
$errmsg
</blockquote></code>

[gc_footer $maintainer_email]"
    return 0
}


# insert went OK

ad_get_user_info

if [catch { ns_sendmail $poster_email $email "Bid for $bid $currency on $one_line" "$first_names $last_name placed a bid of $bid $currency on

$one_line

Come back to 

[ad_url]/gc/view-one.tcl?classified_ad_id=$classified_ad_id 

to see all of the bids on this item.

This message was sent by a robot, though if you reply you will be doing
so to the bidder.

"} errmsg] {
    # we couldn't send email
    set email_blurb "We were unable to send email to $poster_email:

$errmsg
"} else {
    set email_blurb "We notified <A HREF=\"/shared/community-member.tcl?user_id=$poster_user_id\">$poster_name</a> of your bid."
}


ns_return 200 text/html "[gc_header "Success"]

<h2>Success!</h2>

<hr>
placing a bid on ad number $classified_ad_id in the <a href=\"domain-top.tcl?domain_id=$domain_id\">$full_noun Classifieds</a>

<p>

$email_blurb

<p>

There isn't really a whole lot more to say...  You might want to 
have a look at <a href=\"view-one.tcl?classified_ad_id=$classified_ad_id\">the 
ad page</a> to see how your bid looks.


[gc_footer $maintainer_email]"
