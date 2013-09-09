# /www/admin/comments/find.tcl

ad_page_contract {
    find.tcl 
by philg@mit.edu on July 18, 1999
improved on January 21, 2000 to quote the string, display the whole comment
a system for an administrator to find an exact string match in a comment

    @param query_string what we're searching for

    @cvs-id find.tcl,v 3.1.6.4 2000/09/22 01:34:32 kevin Exp
} {
    query_string
}

if {[ad_administrator_p [ad_maybe_redirect_for_registration]] == 0} {
    ad_return_complaint 1 "You are not an administrator"
}

set safely_printable_query_string [philg_quote_double_quotes $query_string]


set html "[ad_admin_header "Comments matching \"$safely_printable_query_string\""]

<h2>Comments matching \"$safely_printable_query_string\"</h2>

[ad_admin_context_bar [list "index" "Comments"] "Search Results"]

<hr>

<ul>

"

set like_query_string "%$query_string%"

set comment_retrieve_sql "select comments.comment_id, comments.message, comments.html_p, comments.rating, comments.comment_type, posting_time, comments.originating_ip, users.user_id, first_names || ' ' || last_name as name, comments.page_id, sp.url_stub, sp.page_title
from static_pages sp, comments_not_deleted comments, users
where sp.page_id = comments.page_id
and users.user_id = comments.user_id
and (dbms_lob.instr(comments.message,:query_string) > 0
     or
     upper(last_name) like upper(:like_query_string)
     or 
     upper(first_names) like upper(:like_query_string))
order by comment_type, posting_time desc"

set items ""
set last_comment_type ""

db_foreach comment_retrieve $comment_retrieve_sql {
    if { $last_comment_type != $comment_type } {
	append items "<h4>$comment_type</h4>"
	set last_comment_type $comment_type
    }
    append items "<li>[util_AnsiDatetoPrettyDate $posting_time]: "
    if { ![empty_string_p $rating] } {
	append items "$rating -- "
    }
    append items "[util_maybe_convert_to_html $message $html_p] 
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
 
if ![empty_string_p $items] {
    append html $items
} else {
    append html "No comments found"
}

append html "
</ul>

Due to the brain-damaged nature of Oracle's CLOB datatype, this search
is case-sensitive when searching through the bodies of comments (i.e.,
a query for \"greyhound\" won't match \"Greyhound\").

[ad_admin_footer]
"



doc_return  200 text/html $html