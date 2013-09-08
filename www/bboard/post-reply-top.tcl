# /www/bboard/post-reply-top.tcl
ad_page_contract {
    @cvs_id post-reply-top.tcl,v 3.0.12.5 2000/09/22 01:36:52 kevin Exp
} {
    refers_to
}

# -----------------------------------------------------------------------------

db_1row user_info "
select first_names || ' ' || last_name as name, 
       email, 
       one_line,
       message,
       html_p
from   bboard, 
       users
where  bboard.user_id = users.user_id
and    msg_id = :refers_to"

# now variables like $message are defined

doc_return  200 text/html "
[bboard_header $one_line]

<h3>$one_line</h3>

from $name (<a href=\"mailto:$email\">$email</a>)

<hr>

[ad_convert_to_html -html_p $html_p -- $message]

[bboard_footer]
"
