# /www/bboard/admin-q-and-a-one-category.tcl
ad_page_contract {
    Look at postings in one category

    @param topic the name of the bboard topic
    @param topic_id the ID of the bboard topic
    @param category the name of the category to restrict to

    @cvs-id admin-q-and-a-one-category.tcl,v 3.2.2.3 2000/09/22 01:36:45 kevin Exp
} {
    topic
    topic_id:notnull,integer
    category:trim,notnull
}

# -----------------------------------------------------------------------------
 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

append page_content "
[bboard_header "$category threads in $topic"]

<h2>$category Threads</h2>

in the <a href=\"admin-home?[export_url_vars topic topic_id]\">$topic question and answer forum</a>

<hr>

"

if { $category != "uncategorized" } {
    set category_clause "and category = :category"
} else {
    set category_clause "and (category is NULL or category = '' or category = 'Don''t Know')"
}

append page_content "<ul>\n"

set uninteresting_header_written 0

db_foreach messages "
select msg_id, 
       one_line, 
       sort_key, 
       email, 
       first_names || ' ' || last_name as name, 
       interest_level, 
       bboard_uninteresting_p(interest_level) as uninteresting_p
from   bboard, 
       users
where  bboard.user_id = users.user_id 
and    topic_id = :topic_id
$category_clause
and    refers_to is null
order by uninteresting_p, sort_key $q_and_a_sort_order" {

    if { $uninteresting_p == "t" && $uninteresting_header_written == 0 } {
	set uninteresting_header_written 1
	append page_content "</ul>
<h3>Uninteresting Threads</h3>

<ul>
"
    }
    append page_content "<li><a target=admin_bboard_window href=\"admin-q-and-a-fetch-msg?msg_id=$msg_id\">$one_line</a>
<br>
from $name (<a href=\"mailto:$email\">$email</a>)\n"
    if { $q_and_a_use_interest_level_p == "t" } {
	if { $interest_level == "" } { set interest_level "NULL" }
	append page_content " -- interest level $interest_level"
    }
}

# let's assume there was at least one posting

append page_content "

</ul>

[bboard_footer]
"

doc_return  200 text/html $page_content