# /www/admin/comments/by-user.tcl

ad_page_contract {
    
    @param none
    @cvs-id by-user.tcl,v 3.2.2.4 2000/09/22 01:34:31 kevin Exp
} {
    
}

if {[ad_administrator_p [ad_maybe_redirect_for_registration]] == 0} {
    ad_return_complaint 1 "You are not an administrator"
}

set html "[ad_admin_header "Comments by user"]

<h2>Comments by user</h2>

[ad_admin_context_bar [list "index" "Comments"] "By Page"]

<hr>
 
<ul>
"



set display_comments_sql "select comments.user_id,  first_names, last_name, count(comments.page_id) as n_comments, sum(decode(comments.deleted_p,'t',1,0)) as n_deleted
from comments, users
where comments.user_id = users.user_id
group by comments.user_id, first_names, last_name
order by n_comments desc, upper(last_name), upper(first_names)"

set items ""
db_foreach display_comments $display_comments_sql {
    append items "<li><a href=\"/admin/users/one?user_id=$user_id\">$first_names $last_name</a> ($n_comments"
    if { $n_deleted > 0 } {
	append items "; <font color=red>$n_deleted deleted</font>"
    }
    append items ")\n"
}
 
append html "$items
</ul>

[ad_admin_footer]
"



doc_return  200 text/html $html
