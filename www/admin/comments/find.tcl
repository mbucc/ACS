# $Id: find.tcl,v 3.0 2000/02/06 03:14:56 ron Exp $
# find.tcl 
#
# by philg@mit.edu on July 18, 1999
# 
# improved on January 21, 2000 to quote the string, display the whole comment
#
# a system for an administrator to find an exact string match in a comment
#

set_the_usual_form_variables

# query_string

# the query string might contain HTML so let's quote it

set safely_printable_query_string [philg_quote_double_quotes $query_string]

ReturnHeaders

ns_write "[ad_admin_header "Comments matching \"$safely_printable_query_string\""]

<h2>Comments matching \"$safely_printable_query_string\"</h2>

[ad_admin_context_bar [list "index.tcl" "Comments"] "Search Results"]

<hr>

<ul>

"

set db [ns_db gethandle]

set selection [ns_db select $db "select comments.comment_id, comments.message, comments.html_p, comments.rating, comments.comment_type, posting_time, comments.originating_ip, users.user_id, first_names || ' ' || last_name as name, comments.page_id, sp.url_stub, sp.page_title
from static_pages sp, comments_not_deleted comments, users
where sp.page_id = comments.page_id
and users.user_id = comments.user_id
and (dbms_lob.instr(comments.message,'$QQquery_string') > 0
     or
     upper(last_name) like upper('%$QQquery_string%')
     or 
     upper(first_names) like upper('%$QQquery_string%'))
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
    append items "[util_maybe_convert_to_html $message $html_p] 
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
 
if ![empty_string_p $items] {
    ns_write $items
} else {
    ns_write "No comments found"
}

ns_write "
</ul>

Due to the brain-damaged nature of Oracle's CLOB datatype, this search
is case-sensitive when searching through the bodies of comments (i.e.,
a query for \"greyhound\" won't match \"Greyhound\").

[ad_admin_footer]
"
