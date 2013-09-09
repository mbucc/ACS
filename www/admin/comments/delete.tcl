# /www/admin/comments/delete.tcl

ad_page_contract {
    @param comment_id
    @param page_id 

    @cvs-id delete.tcl,v 3.2.2.4 2000/09/22 01:34:32 kevin Exp
} {
    comment_id:integer
    page_id:integer
    
}

if {[ad_administrator_p [ad_maybe_redirect_for_registration]] == 0} {
    ad_return_complaint 1 "You are not an administrator"
}

set admin_id [ad_verify_and_get_user_id]


db_1row get_title "select static_pages.url_stub, nvl(page_title, url_stub) as page_title 
from static_pages
where page_id = :page_id"

db_1row get_message  "select message, html_p, user_id
from comments 
where comment_id = :comment_id"

if [mv_enabled_p] {
    set mistake_wad [mv_create_user_charge $user_id  $admin_id "comment_dupe" $comment_id [mv_rate CommentDupeRate]]
    set spam_wad [mv_create_user_charge $user_id $admin_id "comment_spam" $comment_id [mv_rate CommentSpamRate]]
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




doc_return  200 text/html "[ad_admin_header "Verify comment deletion on <i>$page_title</i>" ]

<h2>Verify comment deletion</h2>

on <a href=\"$url_stub\">$page_title</a>
<hr>

Are you sure that you want to delete this comment on <a href=\"$url_stub\">$url_stub</a> (<i>$page_title</i>)?
<p>

<blockquote>
[util_maybe_convert_to_html $message $html_p]
</blockquote>

<form action=delete-2 method=post>
[export_form_vars comment_id page_id]

<center>
<input type=submit name=submit value=\"I'm Sure; Delete Comment\">
</center>

<p>

$member_value_section

</form>

[ad_admin_footer]
"
