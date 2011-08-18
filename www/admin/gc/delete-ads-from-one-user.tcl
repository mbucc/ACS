# $Id: delete-ads-from-one-user.tcl,v 3.1.2.1 2000/04/28 15:09:02 carsten Exp $
set admin_id [ad_verify_and_get_user_id]
if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}

set_the_usual_form_variables

# domain_id, user_id

set db [ns_db gethandle]

set domain [database_to_tcl_string $db "select domain
from ad_domains where domain_id = $domain_id"]

set classified_ad_id [database_to_tcl_string $db "select max(classified_ad_id) from classified_ads where user_id = $user_id"]

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

of ads from 
<a href=\"/admin/users/one.tcl?user_id=$user_id\">[database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id = $user_id"]</a>
in the
 <a href=\"domain-top.tcl?domain_id=$domain\"> $domain domain of [gc_system_name]</a>

<hr>

<form method=POST action=delete-ads-from-one-user-2.tcl>
[export_form_vars domain user_id]
$member_value_section
<P>
<center>
<input type=submit value=\"Yes, delete these ads.\">
</center>
</form>

[ad_admin_footer]"
