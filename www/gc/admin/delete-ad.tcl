# $Id: delete-ad.tcl,v 3.1 2000/03/10 23:58:48 curtisg Exp $
ad_maybe_redirect_for_registration

set admin_id [ad_get_user_id]

set_the_usual_form_variables

# classified_ad_id

set db [ns_db gethandle]

if [catch { set selection [ns_db 1row $db "select ca.one_line, ca.full_ad, ca.domain_id, u.user_id, u.email, u.first_names, u.last_name, ad.domain
from classified_ads ca, ad_domains ad, users u
where ca.user_id = u.user_id
and ad.domain_id = ca.domain_id
and classified_ad_id = $classified_ad_id"] } errmsg ] {
    ad_return_error "Could not find Ad $classified_ad_id" "Either you are fooling around with the Location field in your browser
or my code has a serious bug.  The error message from the database was

<blockquote><code>
$errmsg
</blockquote></code>"
       return 
}

# OK, we found the ad in the database if we are here...
# the variable SELECTION holds the values from the db
set_variables_after_query

# now we know to what domain this ad belongs

if ![ad_administration_group_member $db "gc" $domain $admin_id] {
    ad_return_error "Unauthorized" "Unauthorized" 
    return
}

if [ad_parameter EnabledP "member-value"] {
    set mistake_wad [mv_create_user_charge $user_id  $admin_id "classified_ad_mistake" $classified_ad_id [mv_rate ClassifiedAdMistakeRate]]
    set spam_wad [mv_create_user_charge $user_id $admin_id "classified_ad_spam" $classified_ad_id [mv_rate ClassifiedAdSpamRate]]
    set options [list [list "" "Don't charge user"] [list $mistake_wad "Mistake of some kind, e.g., duplicate posting"] [list $spam_wad "Spam or other serious policy violation"]]
    set member_value_section "<h3>Charge this user for his sins?</h3>
<select name=user_charge>\n"
    foreach sublist $options {
	set value [lindex $sublist 0]
	set visible_value [lindex $sublist 1]
	append member_value_section "<option value=\"[philg_quote_double_quotes $value]\">$visible_value\n"
    }
    append member_value_section "</select>
<br>
<br>
Charge Comment:  <input type=text name=charge_comment size=50>
<br>
<br>
<br>"
} else {
    set member_value_section ""
}


ns_return 200 text/html "[gc_header "Confirm Deletion"]

<h2>Confirm Deletion</h2>

[ad_context_bar_ws_or_index [list "/gc/" "Classifieds"] [list "index.tcl" "Classifieds Admin"] [list "domain-top.tcl?domain_id=$domain_id" $domain] "Delete Ad #$classified_ad_id"]


<hr>

<form method=POST action=delete-ad-2.tcl>
[export_form_vars classified_ad_id]
$member_value_section
<P>
<center>
<input type=submit value=\"Yes, delete this ad.\">
</center>
</form>

<h3>$one_line</h3>

<blockquote>
$full_ad
<br>
<br>
-- <a href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name</a> 
(<a href=\"mailto:$email\">$email</a>)
</blockquote>


[ad_admin_footer]"

