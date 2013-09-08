# /www/webmail/preferences.tcl

ad_page_contract {
    Sets user's preferences.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2000-06-01
    @cvs-id preferences.tcl,v 1.5.2.3 2000/09/22 01:39:28 kevin Exp
} {
    { mailbox_id:integer "" }
}

set refresh_seconds [ad_get_client_property -browser t "webmail" "seconds_between_refresh"]

set page_content "
[ad_header "Preferences"]
<h2>Preferences</h2>
[ad_context_bar_ws [list "index?[export_url_vars mailbox_id]" "Webmail"] "Preferences"]
<hr>

<form method=post action=preferences-2>

How often should we refresh your mailbox?
<select name=refresh_seconds>
<option value=\"0\"> Never
<option value=\"300\"[util_decode $refresh_seconds 300 " selected" ""]> Every 5 minutes
<option value=\"900\"[util_decode $refresh_seconds 900 " selected" ""]> Every 15 minutes
</select>
<p>
<center>
<input type=submit value=\"Save preferences\">
</center>
</form>

[ad_footer]
"

doc_return  200 text/html $page_content
