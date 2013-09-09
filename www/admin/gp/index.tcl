ad_page_contract {
    General permisssions index page.

    @author mark@ciccarello.com
    @creation-date February 2000
    @cvs-id index.tcl,v 3.4.2.5 2000/09/22 01:35:27 kevin Exp
} {
}

set whole_page "[ad_admin_header "General Permissions Administration"]
<h2>General Permissions Administration</h2>
[ad_admin_context_bar "General Permissions"]
<hr>
<p>
Please select an object type on which to administer permissions:
<ul>
"

db_foreach table_name_select "select table_name, pretty_table_name_plural
                              from general_table_metadata
                              order by pretty_table_name_plural" {
    append whole_page "<li><a href=\"one-table?[export_url_vars table_name]\">$pretty_table_name_plural</a></li>"
}

append whole_page "
</ul>
[ad_admin_footer]"

doc_return  200 text/html $whole_page

