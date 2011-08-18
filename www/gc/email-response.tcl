# $Id: email-response.tcl,v 3.1 2000/03/10 23:58:26 curtisg Exp $
set_form_variables

# classified_ad_id

set db [gc_db_gethandle]
if [catch { set selection [ns_db 1row $db "select ca.*, ad.domain
from classified_ads ca, ad_domains ad
where classified_ad_id = $classified_ad_id
and ad.domain_id = ca.domain_id"] } errmsg ] {
    ad_return_error  "Could not find Ad $classified_ad_id" "in <a href=index.tcl>[gc_system_name]</a>

<p>

Either you are fooling around with the Location field in your browser
or my code has a serious bug.  The error message from the database was

<blockquote><code>
$errmsg
</blockquote></code>

[gc_footer]
"
       return 
}

# OK, we found the ad in the database if we are here...
# the variable SELECTION holds the values from the db
set_variables_after_query

set selection [ns_db 1row $db "select maintainer_email, maintainer_name, backlink_title from ad_domains
where domain_id = $domain_id"]
set_variables_after_query

set subject "Response (password) for ad $classified_ad_id"

regexp {(.*/)[^/]*$} [ns_conn url] match just_the_dir

append come_back_url [ns_conn location] $just_the_dir "edit-ad-3.tcl?classified_ad_id=$classified_ad_id"

set body "Here's what I know about ad $classified_ad_id:

Challenge:  $challenge
Response:   $response
One Line:   $one_line

Come back to the $backlink_title Classifieds and edit your ad.

The URL is $come_back_url
"

if [catch { ns_sendmail $poster_email "$maintainer_name <$maintainer_email>" $subject $body } errmsg] {
    # couldn't send email
    ns_return 500 text/html "[gc_header "This is not your day"]

<h2>This is not your day</h2>

(re: Ad $classified_ad_id in <a href=index.tcl>[gc_system_name]</a>)

<p>

We couldn't even mail you your password!  Here's the error message we got:
<blockquote><code>
$errmsg
</blockquote></code>

[gc_footer]"
    return
} else {
    ns_return 200 text/html "[gc_header "Go and read your mail now"]

<h2>Go and read your mail now</h2>

<p>

Because you'll find a message from $maintainer_email with the correct response to 
Ad $classified_ad_id ($one_line).

[gc_footer]"

}

