# $Id: delete-2.tcl,v 3.0 2000/02/06 03:14:54 ron Exp $
set_the_usual_form_variables

# comment_id, page_id
# maybe user_charge

set db [ns_db gethandle]

set selection [ns_db 1row $db "select url_stub,nvl(page_title, url_stub) page_title
from static_pages
where static_pages.page_id = $page_id"]

set_variables_after_query


ns_db dml $db "update comments set deleted_p = 't' where comment_id=$comment_id"

ReturnHeaders
ns_write "[ad_admin_header "Comment Deleted"]

<h3>Comment Deleted</h3>

<hr>

"

if { [info exists user_charge] && ![empty_string_p $user_charge] } {
    if { [info exists charge_comment] && ![empty_string_p $charge_comment] } {
	# insert separately typed comment
	set user_charge [mv_user_charge_replace_comment $user_charge $charge_comment]
    }
    ns_write "<p> ... adding a user charge:
<blockquote>
[mv_describe_user_charge $user_charge]
</blockquote>
... "
    mv_charge_user $db $user_charge
    ns_write "Done."
}

ns_write "

<p>
Go to <a href=\"$url_stub\">$page_title</a>
<p>
[ad_admin_footer]
"




