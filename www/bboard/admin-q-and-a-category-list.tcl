# $Id: admin-q-and-a-category-list.tcl,v 3.0 2000/02/06 03:32:58 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic, topic_id required

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
<title>Question Categories</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Question Categories</h2>

in the <a href=\"admin-q-and-a.tcl?[export_url_vars topic topic_id]\">$topic Q&A forum</a>

<hr>

<ul>

"

# may someday need "and category <> ''" 

set selection [ns_db select $db "select category, count(*) as n_threads
from bboard 
where refers_to is null
and topic_id = $topic_id
and category is not null
and category <> 'Don''t Know'
group by category 
order by 1"]
    
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><a href=\"admin-q-and-a-one-category.tcl?[export_url_vars topic topic_id category]\">$category</a> ($n_threads)\n"
}

ns_write "
<p>
<li><a href=\"admin-q-and-a-one-category.tcl?[export_url_vars topic topic_id]&category=uncategorized\">Uncategorized</a>
</ul>

[bboard_footer]
"
