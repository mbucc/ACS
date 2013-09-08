# canned-responses.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id canned-responses.tcl,v 3.1.6.4 2000/09/22 01:34:51 kevin Exp
} {
}





append doc_body "[ad_admin_header "Canned Responses"]
<h2>Canned Responses</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] "Canned Responses"]

<hr>

<h3>Defined Responses</h3>
<ul>
"

set sql "select response_id, one_line, response_text
from ec_canned_responses
order by one_line"

set count 0

db_foreach get_canned_responses $sql {
    

    append doc_body "<li><a href=\"canned-response-edit?response_id=$response_id\">$one_line</a>
<blockquote>
[ec_display_as_html $response_text] <a href=\"canned-response-delete?response_id=$response_id\">Delete</a>
</blockquote>
"

    incr count
}

if { $count == 0 } {
    append doc_body "<li>No defined canned responses.\n"
}

append doc_body "<p>
<a href=\"canned-response-add\">Add a new canned response</a>
</ul>

[ad_admin_footer]
"



doc_return  200 text/html $doc_body
