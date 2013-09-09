# /www/bboard/admin-delete-and-view-threads.tcl
ad_page_contract {
    shows bboard threads with the option to delete them.

    @cvs-id admin-delete-and-view-threads.tcl,v 3.2.2.4 2000/09/22 01:36:43 kevin Exp
} {
    topic:notnull
    topic_id:notnull,integer
}

# -----------------------------------------------------------------------------
 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

# -----------------------------------------------------------------------------

proc compute_msg_level { sort_key } {

    set period_pos [string first "." $sort_key]

    if { $period_pos == -1 } {

	# no period, primary level

	return 0

    } else {

	set n_more_levels [expr ([string length $sort_key] - ($period_pos + 1))/2]

	return $n_more_levels

    }

}

# -----------------------------------------------------------------------------


append page_content "
[bboard_header "Delete and View Threads for $topic"]

<h2>Delete and View Threads for \"$topic\"</h2>

a discussion group in <a href=\"index\">[bboard_system_name]</a>

<p>

Personally, I don't find this interface as useful as the 

<a href=\"admin-q-and-a?[export_url_vars topic topic_id]\">admin Q&A</a>

but to each his own...

<hr>

<h3>Those Threads</h3>

<pre>"

db_foreach messages "
select msg_id,
       one_line, 
       sort_key 
from   bboard
where  topic_id = :topic_id
order by sort_key desc" {

    set n_spaces [expr 3 * [compute_msg_level $sort_key]]

    if { $n_spaces == 0 } {

	set pad ""

    } else {

	set pad [format "%*s" $n_spaces " "]

    }

    append page_content "<a target=admin_bboard_window href=\"delete-msg?msg_id=$msg_id\">DELETE</a> $pad<a target=admin_bboard_window href=\"admin-edit-msg?msg_id=$msg_id\">$one_line</a>\n"

}

append page_content "</pre>
[bboard_footer]
"

doc_return  200 text/html $page_content