# $Id: add-adv-to-group.tcl,v 3.0 2000/02/06 02:46:08 ron Exp $
set_the_usual_form_variables
# group_key

set db [ns_db gethandle]

set selection [ns_db 1row $db "select pretty_name from adv_groups where group_key='$QQgroup_key'"]
set_variables_after_query

ReturnHeaders
ns_write "[ad_admin_header "Add ads to group $pretty_name"]
<h2>Add ads</h2>
to Ad Group <a href=\"one-adv-group.tcl?group_key=$group_key\">$pretty_name</a>.
<hr><p>

Choose an ad to include in this Ad Group:<p>
<ul>
"

set selection [ns_db select $db "select adv_key from advs where adv_key NOT IN (select adv_key from adv_group_map where group_key='$QQgroup_key')"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    ns_write "<li><a href=\"add-adv-to-group-2.tcl?group_key=$group_key&adv_key=$adv_key\">$adv_key</a>\n"
}

ns_write "</ul>
<p>
[ad_admin_footer]
"