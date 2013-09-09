# /www/admin/comments/delete-2.tcl

ad_page_contract {
    
    @param comment_id
    @param page_id
    @user_charge

    @cvs-id delete-2.tcl,v 3.1.2.4 2000/09/22 01:34:32 kevin Exp
} {
    comment_id
    page_id
    user_charge:optional
}

if {[ad_administrator_p [ad_maybe_redirect_for_registration]] == 0} {
    ad_return_complaint 1 "You are not an administrator"
}

db_1row comment_title "select url_stub,nvl(page_title, url_stub) page_title
from static_pages
where static_pages.page_id = :page_id"

db_dml delete_comment "update comments set deleted_p = 't' where comment_id=:comment_id"

db_release_unused_handles

set html  "[ad_admin_header "Comment Deleted"]

<h3>Comment Deleted</h3>

<hr>

"

if { [info exists user_charge] && ![empty_string_p $user_charge] } {
    if { [info exists charge_comment] && ![empty_string_p $charge_comment] } {
	# insert separately typed comment
	set user_charge [mv_user_charge_replace_comment $user_charge $charge_comment]
    }
    append html "<p> ... adding a user charge:
<blockquote>
[mv_describe_user_charge $user_charge]
</blockquote>
... "
    mv_charge_user $user_charge
    append html "Done."
}

append html "

<p>
Go to <a href=\"$url_stub\">$page_title</a>
<p>
[ad_admin_footer]
"

doc_return  200 text/html $html


