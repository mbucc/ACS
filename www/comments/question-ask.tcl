# $Id: question-ask.tcl,v 3.0.4.1 2000/04/28 15:09:53 carsten Exp $
set_form_variables

# page_id
#check for the user cookie
set user_id [ad_get_user_id]

if {$user_id == 0} {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode  /comments/question-ask.tcl?[export_url_vars page_id]] 
}

set db [ns_db gethandle]
set selection [ns_db 1row $db "select static_pages.url_stub, nvl(page_title,  url_stub) as page_title
from static_pages
where page_id = $page_id"]

set_variables_after_query
set comment_id [database_to_tcl_string $db "select
comment_id_sequence.nextval from dual"]

ns_db releasehandle $db

ns_return 200 text/html "[ad_header "Document a question about $page_title" ]

<h2>Document a question</h2>

about <a href=\"$url_stub\">about $page_title</a>

<hr>
What unanswered question were you expecting this page to answer?<br>
<form action=comment-add.tcl method=post>
<input type=hidden name=comment_type value=unanswered_question>
<textarea name=message cols=50 rows=5 wrap=soft></textarea><br>
[export_form_vars page_id comment_id]
<p>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
</form>
[ad_footer]
"
