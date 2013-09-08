# /www/bboard/admin-q-and-a-all.tcl
ad_page_contract {
    @param the name of the bboard topic

    @cvs-id admin-q-and-a-all.tcl,v 3.2.2.3 2000/09/22 01:36:44 kevin Exp
} {
    topic
}

# -----------------------------------------------------------------------------

if ![msie_p] { 
    set target_window "target=admin_bboard_window" 
} else { 
    set target_window ""
}
 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

append page_content "
[bboard_header "Administer $topic by Question"]

<h2>Administer $topic</h2>

by question"

if { $backlink != "" || $backlink_title != "" } {

	append page_content " associated with
<a href=\"$backlink\" target=\"_top\">$backlink_title</a>."

}

append page_content "
<hr>
<ul>
"

db_foreach message_list "
select msg_id, 
       one_line, 
       sort_key, 
       email, 
       first_names || ' ' || last_name as name, 
       interest_level
from bboard, users
where bboard.user_id = users.user_id 
and topic_id = :topic_id
and refers_to is null
order by sort_key $q_and_a_sort_order" {

    append page_content "<li><a $target_window href=\"admin-q-and-a-fetch-msg?msg_id=$msg_id\">$one_line</a>
<br>
from $name (<a href=\"mailto:$email\">$email</a>)\n"

    if { $q_and_a_use_interest_level_p == "t" } {
	if { $interest_level == "" } { 
	    set interest_level "NULL" 
	}
	append page_content " -- interest level $interest_level"
    }
}

append page_content "
</ul>
[bboard_footer]
"


doc_return  200 text/html $page_content
