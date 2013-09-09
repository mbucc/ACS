# /www/bboard/urgent-requests.tcl
ad_page_contract {
    Lists urgent messages

    @param skip_first
    @param archived_p included archived messages or not?

    @cvs-id urgent-requests.tcl,v 3.0.12.4 2000/09/22 01:36:56 kevin Exp
} {
    {skip_first:integer 0}
    {archived_p "f"}
}

# -----------------------------------------------------------------------------

if {$archived_p == "t"} {
    set title "Archived Urgent Requests"
} else {
    set title "Urgent Requests"
}

set user_id [ad_verify_and_get_user_id]

append page_content "
[bboard_header $title]

<h2>$title</h2>

[ad_context_bar_ws $title]

<hr>
[ad_decorate_side]

"

# let's do the urgent messages first, if necessary 

set urgent_items [bboard_urgent_message_items $archived_p 3 50000 $skip_first]
if ![empty_string_p $urgent_items] {
    append page_content "<ul>$urgent_items</ul>\n"
}

append page_content "

<br clear=right>
<p>
[bboard_footer]
"



doc_return  200 text/html