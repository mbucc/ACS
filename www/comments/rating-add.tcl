# $Id: rating-add.tcl,v 3.0.4.1 2000/04/28 15:09:54 carsten Exp $
set_form_variables

# page_id

# check for the user cookie
set user_id [ad_get_user_id]
set rating_list {0 1 2 3 4 5 6 7 8 9 10}

if {$user_id == 0} {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode  /comments/rating-add.tcl?[export_url_vars page_id]] 
}

set db [ns_db gethandle]

set selection [ns_db 1row $db "select static_pages.url_stub, nvl(page_title,  url_stub) as page_title 
from static_pages
where page_id = $page_id"]
set_variables_after_query

set comment_id [database_to_tcl_string $db "select
comment_id_sequence.nextval from dual"]
ns_db releasehandle $db

ns_return 200 text/html "[ad_header "Rate $page_title" ]
<h2>Rate</h2>
<a href=\"$url_stub\">$page_title</a>
<hr>
<form action=comment-add.tcl method=post>
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
