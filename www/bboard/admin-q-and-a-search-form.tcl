# $Id: admin-q-and-a-search-form.tcl,v 3.0 2000/02/06 03:33:05 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic required

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}


set search_submit_button ""
if { [msie_p] == 1 } {
    set search_submit_button "<input type=submit value=\"Submit Query\">"
}

set_variables_after_query

ns_return 200 text/html "<html>
<head>
<title>Search $topic Q&A</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Search</h2>

the <a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">$topic Q&A forum</a>

<hr>
<form method=POST action=admin-q-and-a-search.tcl target=\"_top\">
<input type=hidden name=topic value=\"$topic\">
<input type=hidden name=topic_id value=\"$topic_id\">
Full Text Search:  <input type=text name=query_string size=40>
$search_submit_button
</form>

[bboard_footer]"
