ad_page_contract {
    @param page_id
    @cvs-id  rating-add.tcl,v 3.3.2.5 2000/09/22 01:37:17 kevin Exp
} {
    {page_id:naturalnum,notnull}
}

# check for the user cookie
set user_id [ad_get_user_id]
set rating_list {0 1 2 3 4 5 6 7 8 9 10}

if {$user_id == 0} {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode  /comments/rating-add.tcl?[export_url_vars page_id]] 
}


set selection [db_0or1row comments_rating_add_page_data_get "
select static_pages.url_stub, nvl(page_title,  url_stub) as page_title 
from static_pages
where page_id = :page_id"]

if {$selection == 0} {
    ad_return_complaint "Invalid page id" "Page id could not found"
    db_release_unused_handles
    return
}

set comment_id [db_string comment_id_get "select
comment_id_sequence.nextval from dual"]


doc_return  200 text/html "[ad_header "Rate $page_title" ]

<h2>Rate</h2>
<a href=\"$url_stub\">$page_title</a>
<hr>
<form action=comment-add method=post>
[export_form_vars page_id comment_id]
Rating:
<select name=rating>
[ad_generic_optionlist $rating_list $rating_list]
</select><p>
Why did you give it this rating?<br>
<textarea name=message cols=50 rows=5 wrap=soft></textarea><br>
<input type=submit name=submit value=\"Submit Rating\">
<input type=hidden name=comment_type value=rating>
</form>
[ad_footer]
"
