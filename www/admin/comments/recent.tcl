# /www/admin/comments/recent.tcl

ad_page_contract {
    
    @param num_days could be 'all'

    @cvs-id recent.tcl,v 3.2.2.4 2000/09/22 01:34:32 kevin Exp
} {
    
    num_days
}


if {[ad_administrator_p [ad_maybe_redirect_for_registration]] == 0} {
    ad_return_complaint 1 "You are not an administrator"
}

if { $num_days == "all" } {
    set title "All comments"
    set subtitle ""
    set posting_time_clause "" 
} else {
    set title "Recent comments"
    set subtitle "added over the past $num_days day(s)"
    set posting_time_clause "\nand posting_time > (SYSDATE - $num_days)" 
}


set html "[ad_admin_header $title]

<h2>Comments</h2>

$subtitle

<p>

[ad_admin_context_bar [list "index" "Comments"] "Listing"]

<hr>
 
<ul>
"


# the $posting_time_clause is not a sql-smugglable var
set comment_details_sql "select comments.comment_id, dbms_lob.substr(comments.message,750,1) as message_intro, comments.rating, comments.comment_type, posting_time, comments.originating_ip, users.user_id, first_names || ' ' || last_name as name, comments.page_id, sp.url_stub, sp.page_title, client_file_name, html_p, file_type, original_width, original_height, caption
from static_pages sp, comments_not_deleted comments, users
where sp.page_id = comments.page_id $posting_time_clause
and users.user_id = comments.user_id
order by comment_type, posting_time desc"

set items ""
set last_comment_type ""

db_foreach comment_details $comment_details_sql {
    if { $last_comment_type != $comment_type } {
	append items "<h4>$comment_type</h4>"
	set last_comment_type $comment_type
    }
    append items "<li>[util_AnsiDatetoPrettyDate $posting_time]: "
    if { ![empty_string_p $rating] } {
	append items "$rating -- "
    }
    append items "[format_static_comment $comment_id $client_file_name $file_type $original_width $original_height $caption "$message_intro ..." $html_p]
<br>
-- <a href=\"/admin/users/one?user_id=$user_id\">$name</a> 
from $originating_ip
on <a href=\"/admin/static/page-summary?[export_url_vars page_id]\">$url_stub</a>"
    if ![empty_string_p $page_title] {
	append items " ($page_title) "
    }
    append items "&nbsp; &nbsp; <a href=\"persistent-edit?[export_url_vars comment_id]\" target=working>edit</a> &nbsp; &nbsp;  <a href=\"delete?[export_url_vars comment_id page_id]\" target=working>delete</a>
<br>
<br>
"

}
 
append html $items

append html "
</ul>

[ad_admin_footer]
"



doc_return  200 text/html $html






