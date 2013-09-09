ad_page_contract {
    @param page_id
    @cvs-id question-ask.tcl,v 3.3.2.6 2000/09/22 01:37:17 kevin Exp
} {
    {page_id:naturalnum,notnull}
}


#check for the user cookie
set user_id [ad_get_user_id]

if {$user_id == 0} {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode  /comments/question-ask.tcl?[export_url_vars page_id]] 
}


set selection [db_0or1row comments_question_ask_page_data_get "
select static_pages.url_stub, nvl(page_title,  url_stub) as page_title
from static_pages
where page_id = :page_id"]

if {$selection == 0} {
    ad_return_complaint "Invalid page id" "Page id could not be found"
    db_release_unused_handles
    return
}

set comment_id [db_string comments_get_next_comment_id "select
comment_id_sequence.nextval from dual"]

doc_return  200 text/html "[ad_header "Document a question about $page_title" ]

<h2>Document a question</h2>

about <a href=\"$url_stub\">about $page_title</a>

<hr>
What unanswered question were you expecting this page to answer?<br>
<form action=comment-add method=post>
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
