# /www/bboard/usgeospatial-search-form.tcl

ad_page_contract {
    usgeospatial-search-form
    @author unknown
    @creation-date unknown
    @cvs-id usgeospatial-search-form.tcl,v 3.3.2.3 2000/09/22 01:36:58 kevin Exp
} {
    topic:trim
    topic_id:integer
} 

if {[bboard_get_topic_info] == -1} {
    return
}

set search_submit_button ""
if { [msie_p] == 1 } {
    set search_submit_button "<input type=submit value=\"Submit Query\">"
}

set page_content "[bboard_header "Search $topic forum"]

<h2>Search</h2>

the <a href=\"usgeospatial?[export_url_vars topic topic_id]\">$topic forum</a> in <a href=\"[ad_pvt_home]\">[ad_system_name]</a>

<hr>
<form method=GET action=usgeospatial-search>
[export_form_vars topic topic_id]
Full Text Search:  <input type=text name=query_string size=40>
$search_submit_button
</form>

<p>

(separate keywords by spaces)

[bboard_footer]
"

doc_return  200 text/html $page_content

















