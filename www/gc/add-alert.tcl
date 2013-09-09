# /www/gc/add-alert-2.tcl
ad_page_contract {
    get the user's Id and send user to registration if necessary

    @author xxx
    @date unknown
    @cvs-id add-alert.tcl,v 3.4.2.4 2000/09/22 01:37:50 kevin Exp
} {
    domain_id:integer
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

#check for the user cookie
set user_id [ad_get_user_id]

if {$user_id == 0} {
    ad_returnredirect /register/index.tcl?return_url=[ns_urlencode /gc/add-alert.tcl?domain_id=[ns_urlencode $domain_id]]
}

db_1row gc_query_for_domain_info [gc_query_for_domain_info $domain_id]

set page_content "[gc_header "Add Alert"]

[ad_decorate_top "<h2>Add an Alert</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Add Alert"]
" [ad_parameter AddAlertDecoration gc]]

<hr>

If you're too busy to come to them, 
<a href=\"domain-top?domain_id=[ns_urlencode $domain_id]\">$full_noun</a>
will come to you.  By filling out this form, you can
get an email notification of new ads that fit your interests.

<p>

<form method=POST action=\"add-alert-2\">
<input name=domain_id type=hidden value=\"$domain_id\">

Step 1: decide how often you'd like to have your mailbox
spammed by our server:

<P>

<blockquote>

<input name=frequency value=instant type=radio> Instant
<input name=frequency value=daily type=radio> Daily 
<input name=frequency value=monthu type=radio checked> Monday and Thursday
<input name=frequency value=weekly type=radio> Weekly

</blockquote>

<p>

Step 2: decide how much of each advertisement would you like to get in the
email message:

<P>

<blockquote>

<input name=howmuch value=one_line type=radio checked> Subject line and email address
<input name=howmuch value=everything type=radio> The whole enchilada

</blockquote>

<p>

\[Note: if you opt for subject line only, you'll also get a URL that
will bring up a page from our server with all of the ads so you can
browse the full text.\]

<p>

<center>
<input type=submit value=\"Proceed\">
</center>

</form>

<p>

<h3>Edit Previous Alerts</h3>

Found your dream?  Going on vacation?  You can put your alerts
on hold with <a href=\"edit-alerts\">the edit alert page</a>.

[gc_footer $maintainer_email]
"



doc_return  200 text/html $page_content

