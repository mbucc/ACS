# /www/gc/email-response.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id email-response.tcl,v 3.2.6.4 2000/09/22 01:37:53 kevin Exp
} {
    classified_ad_id
}

if [catch { db_1row gc_email_response_ad_data_get {
    select ca.*, ad.domain
    from classified_ads ca, ad_domains ad
    where classified_ad_id = :classified_ad_id
    and ad.domain_id = ca.domain_id
}   } errmsg ] {
    ad_return_error  "Could not find Ad $classified_ad_id" "in <a href=index>[gc_system_name]</a>

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

db_1row gc_email_response_domain_data_get {
    select maintainer_email, maintainer_name, backlink_title from ad_domains
    where domain_id = :domain_id
}

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
    doc_return  500 text/html "[gc_header "This is not your day"]

<h2>This is not your day</h2>

(re: Ad $classified_ad_id in <a href=index>[gc_system_name]</a>)

<p>

We couldn't even mail you your password!  Here's the error message we got:
<blockquote><code>
$errmsg
</blockquote></code>

[gc_footer]"
    return
}


db_release_unused_handles

doc_return 200 text/html "[gc_header "Go and read your mail now"]

<h2>Go and read your mail now</h2>

<p>

Because you'll find a message from $maintainer_email with the correct response to 
Ad $classified_ad_id ($one_line).

[gc_footer]"

