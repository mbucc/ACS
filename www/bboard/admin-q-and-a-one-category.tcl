# $Id: admin-q-and-a-one-category.tcl,v 3.0 2000/02/06 03:33:04 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic, topic_id, category required

# we're just looking at the uninteresting postings now

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}



ReturnHeaders

ns_write "<html>
<head>
<title>$category threads in $topic</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>$category Threads</h2>

in the <a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">$topic question and answer forum</a>

<hr>


"

if { $category != "uncategorized" } {
    set category_clause "and category = '$QQcategory'"
} else {
    set category_clause "and (category is NULL or category = '' or category = 'Don''t Know')"
}


set sql "select msg_id, one_line, sort_key, email, first_names || ' ' || last_name as name, interest_level, bboard_uninteresting_p(interest_level) as uninteresting_p
from bboard, users
where bboard.user_id = users.user_id 
and topic_id = $topic_id
$category_clause
and refers_to is null
order by uninteresting_p, sort_key $q_and_a_sort_order"

set selection [ns_db select $db $sql]

ns_write "<ul>\n"

set uninteresting_header_written 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if { $uninteresting_p == "t" && $uninteresting_header_written == 0 } {
	set uninteresting_header_written 1
	ns_write "</ul>
<h3>Uninteresting Threads</h3>


<ul>
"
    }
    ns_write "<li><a target=admin_bboard_window href=\"admin-q-and-a-fetch-msg.tcl?msg_id=$msg_id\">$one_line</a>
<br>
from $name (<a href=\"mailto:$email\">$email</a>)\n"
    if { $q_and_a_use_interest_level_p == "t" } {
	if { $interest_level == "" } { set interest_level "NULL" }
	ns_write " -- interest level $interest_level"
    }
}

# let's assume there was at least one posting

ns_write "

</ul>


[bboard_footer]
"
