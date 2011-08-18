# $Id: admin-q-and-a-prompt-for-new-category.tcl,v 3.0 2000/02/06 03:33:07 ron Exp $
set_form_variables

# msg_id

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

set selection [ns_db 0or1row $db "select unique t.topic, b.topic_id, b.one_line from bboard b, bboard_topics t where b.topic_id=t.topic_id and b.msg_id = '$msg_id'"]

if { $selection == "" } {
    # message was probably deleted
    ns_return 200 text/html "Couldn't find message $msg_id.  Probably it was deleted by the forum maintainer."
    return
}

set_variables_after_query

ns_log Notice "--$topic_id $topic $msg_id"

if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return
}


ReturnHeaders
ns_write "<html>
<head>
<title>Add a new category</title>
</head>

<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>
<h2>Add a new category</h2>

to the <a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">$topic</a> forum

<p>
(for $one_line)

<hr>

<form target=admin_sub method=POST action=q-and-a-update-category.tcl>
<input type=hidden name=msg_id value=\"$msg_id\">
<input type=hidden name=new_category_p value=t>
New Category Name: <input type=text name=category size=20>
</form>

For reference, here are the existing categories:
<ul>
"

set categories [database_to_tcl_list $db "select distinct category, upper(category) from bboard_q_and_a_categories where topic_id = $topic_id order by 2"]
foreach choice $categories {
    ns_write "<li>$choice\n"
}

ns_write "</ul>

[bboard_footer]"
