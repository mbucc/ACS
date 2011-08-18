# $Id: usgeospatial-search-form.tcl,v 3.1 2000/02/23 01:49:39 bdolicki Exp $
set_the_usual_form_variables

# topic required

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


if {[bboard_get_topic_info] == -1} {
    return
}


set search_submit_button ""
if { [msie_p] == 1 } {
    set search_submit_button "<input type=submit value=\"Submit Query\">"
}

set_variables_after_query

ns_return 200 text/html "[bboard_header "Search $topic forum"]

<h2>Search</h2>

the <a href=\"usgeospatial.tcl?[export_url_vars topic topic_id]\">$topic forum</a> in <a href=\"[ad_pvt_home]\">[ad_system_name]</a>

<hr>
<form method=GET action=usgeospatial-search.tcl>
[export_form_vars topic topic_id]
Full Text Search:  <input type=text name=query_string size=40>
$search_submit_button
</form>

<p>

(separate keywords by spaces)

[bboard_footer]
"
