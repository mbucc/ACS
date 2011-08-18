# $Id: q-and-a-update-category.tcl,v 3.0.4.1 2000/04/28 15:09:43 carsten Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# msg_id, category, maybe new_category_p

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

set topic_id [database_to_tcl_string $db "select unique topic_id from bboard where msg_id = '$msg_id'"]


if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return
}



# cookie checks out; user is authorized

if { $category == "Define New Category" } {
    ad_returnredirect "admin-q-and-a-prompt-for-new-category.tcl?msg_id=$msg_id"
    return 
}

if { [info exists new_category_p] && $new_category_p == "t" } {
    if [catch {ns_db dml $db "insert into bboard_q_and_a_categories (topic_id, category) values ($topic_id,'$QQcategory')"} errmsg] {
	# something went wrong
	ns_return 200 text/html "<html>
<head>
<title>New Category Not Updated</title>
</head>

<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>
<h2>New Category Not Updated</h2>

<hr>

The database rejected the addition of the new category \"$category\".
Here was the error message:

<pre>
$errmsg
</pre>

If you see \"integrity constraint\" somewhere in the message, it
probably means that topic_id $topic already has a category called \"$category\"
and you did not need to add it.

<hr>
<a href=\"mailto:[bboard_system_owner]\"><address>[bboard_system_owner]</address></a>

</body>
</html>"
       return
}
}

# if we got here, it means the new category was added successfully
# and/or there was no need to add a category

if [catch {ns_db dml $db "update bboard set category = '$QQcategory' where msg_id = '$msg_id' "} errmsg] {
    # something went wrong
    ns_return 500 text/html "<html>
<head>
<title>Update Failed</title>
</head>

<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>
<h2>Update Failed</h2>

<hr>

The database rejected the categorization of msg $msg_id.
Here was the error message:

<pre>
$errmsg
</pre>

This is probably some kind of bug in this software.

<hr>
<a href=\"mailto:[bboard_system_owner]\"><address>[bboard_system_owner]</address></a>

</body>
</html>"
       return
}
# if we got here, it means that we did everything right


ns_return 200 text/html "<html>
<head>
<title>Done</title>
</head>

<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>
<h2>Done</h2>

<hr>

Message $msg_id categorized.

[bboard_footer]"
