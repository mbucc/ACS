# /www/bboard/admin-q-and-a-search-form.tcl
ad_page_contract {
    Form for the admin to search

    @param topic the name of the bboard topic

    @cvs-id admin-q-and-a-search-form.tcl,v 3.2.2.3 2000/09/22 01:36:45 kevin Exp
} {
    topic
}

# -----------------------------------------------------------------------------
 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

set search_submit_button ""
if { [msie_p] == 1 } {
    set search_submit_button "<input type=submit value=\"Submit Query\">"
}

doc_return  200 text/html "
[bboard_header "Search $topic Q&A"]

<h2>Search</h2>

the <a href=\"admin-home?[export_url_vars topic topic_id]\">$topic Q&A forum</a>

<hr>
<form method=POST action=admin-q-and-a-search target=\"_top\">
<input type=hidden name=topic value=\"$topic\">
<input type=hidden name=topic_id value=\"$topic_id\">
Full Text Search:  <input type=text name=query_string size=40>
$search_submit_button
</form>

[bboard_footer]"
