# /www/gc/admin/delete-ads-from-one-user.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id delete-ads-from-one-user.tcl,v 3.5.2.7 2000/09/22 01:37:59 kevin Exp

    @param domain_id
    @param user_id

} {
    domain_id:integer
    user_id:integer
}


set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}


set classified_ad_id [db_string classified_ad_id_get "select max(classified_ad_id) from classified_ads where user_id = :user_id"]

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

set domain [db_string gc_admin_delete_one_user_domain_get "select domain from ad_domains
                                  where domain_id = :domain_id"]

set user_name [db_string gc_admin_delete_one_user_name_get "select first_names || ' ' || last_name from users where user_id = :user_id"]


db_release_unused_handles
doc_return  200 text/html "[gc_header "Confirm Deletion"]

<h2>Confirm Deletion</h2>

of ads from 
<a href=\"/admin/users/one?user_id=$user_id\">$user_name</a>
in the
 <a href=\"domain-top?domain_id=$domain_id\"> $domain domain of [gc_system_name]</a>

<hr>

<form method=POST action=delete-ads-from-one-user-2>
[export_form_vars domain_id user_id]
$member_value_section
<P>
<center>
<input type=submit value=\"Yes, delete these ads.\">
</center>
</form>

[ad_admin_footer]"
