#/www/dw/query-new.tcl

ad_page_contract {
    Create new query
 
    @author Philip Greenspun (philg@mit.edu)
    @creation-date ?
    @cvs-id query-new.tcl,v 1.1.2.2 2000/09/22 01:34:46 kevin Exp

} {
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_maybe_redirect_for_registration

set page_content "
[ad_header "Define New Query"]

<h2>Define New Query</h2>

for <a href=index>the query section</a> of [dw_system_name]

<hr>

<form method=POST action=\"query-new-2\">
<table>
<tr><th>Query Name<td><input type=text name=query_name size=30>
</table>

<br>

<center>
<input type=submit value=\"Define\">
</center>
</form>

[ad_footer]
"


doc_return  200 text/html $page_content


