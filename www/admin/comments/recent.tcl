# $Id: recent.tcl,v 3.0 2000/02/06 03:15:00 ron Exp $
set_the_usual_form_variables

# num_days (could be "all")

if { $num_days == "all" } {
    set title "All comments"
    set subtitle ""
    set posting_time_clause "" 
} else {
    set title "Recent comments"
    set subtitle "added over the past $num_days day(s)"
    set posting_time_clause "\nand posting_time > (SYSDATE - $num_days)" 
}

ReturnHeaders

ns_write "[ad_admin_header $title]

<h2>Comments</h2>

$subtitle

<p>

[ad_admin_context_bar [list "index.tcl" "Comments"] "Listing"]

<hr>
 
<ul>
"

set db [ns_db gethandle]


set selection [ns_db select $db "select comments.comment_id, dbms_lob.substr(comments.message,750,1) as message_intro, comments.rating, comments.comment_type, posting_time, comments.originating_ip, users.user_id, first_names || ' ' || last_name as name, comments.page_id, sp.url_stub, sp.page_title, client_file_name, html_p, file_type, original_width, original_height, caption
from static_pages sp, comments_not_deleted comments, users
where sp.page_id = comments.page_id $posting_time_clause
and users.user_id = comments.user_id
order by comment_type, posting_time desc"]

set items ""
set last_comment_type ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
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
-- <a href=\"/admin/users/one.tcl?user_id=$user_id\">$name</a> 
from $originating_ip
on <a href=\"/admin/static/page-summary.tcl?[export_url_vars page_id]\">$url_stub</a>"
    if ![empty_string_p $page_title] {
	append items " ($page_title) "
    }
    append items "&nbsp; &nbsp; <a href=\"persistent-edit.tcl?[export_url_vars comment_id]\" target=working>edit</a> &nbsp; &nbsp;  <a href=\"delete.tcl?[export_url_vars comment_id page_id]\" target=working>delete</a>
<br>
<br>
"

}
 
ns_write $items

ns_write "
</ul>

[ad_admin_footer]
"
