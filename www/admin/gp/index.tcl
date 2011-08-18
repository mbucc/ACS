#
# /admin/gp/index.tcl
#
# markc@ciccarello.com
# February 2000
#

ReturnHeaders


set whole_page "[ad_admin_header "General Permissions Administration"]
<h2>General Permissions Administration</h2>
[ad_admin_context_bar "General Permissions"]
<hr>
<p>
Please select an object type on which to administer permissions:
<ul>
"


set db [ns_db gethandle]

set selection [ns_db select $db "
    select 
        table_name, 
        pretty_table_name_plural 
    from 
        general_table_metadata
    order by
        pretty_table_name_plural
"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append whole_page "<li><a href=\"one-table.tcl?[export_url_vars table_name]\">$pretty_table_name_plural</a></li>"
}


append whole_page "
</ul>
[ad_admin_footer]"

ns_db releasehandle $db
ns_write $whole_page

