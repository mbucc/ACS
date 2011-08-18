# $Id: group-type-delete-2.tcl,v 3.0 2000/02/06 03:29:06 ron Exp $
set_the_usual_form_variables

# group_type

set db [ns_db gethandle]

set selection [ns_db 1row $db "select * from user_group_types where group_type = '$QQgroup_type'"]

set_variables_after_query

ReturnHeaders 

ns_write "[ad_admin_header "Deleting $pretty_name"]

<h2>Deleting $pretty_name</h2>

one of <a href=\"index.tcl\">the group types</a> in 
<a href=\"/admin\">[ad_system_name] administration</a> 

<hr>

"

ns_db dml $db "begin transaction"

ns_write "<ul>

<li>Deleting the user-group mappings for groups of this type...

"

# user doesn't really need to hear about this 
ns_db dml $db "delete from user_group_map_queue where group_id in (select group_id from user_groups where group_type = '$QQgroup_type')"

ns_db dml $db "delete from user_group_map where group_id in (select group_id from user_groups where group_type = '$QQgroup_type')"

ns_db dml $db "
delete from content_section_links
where from_section_id in (select section_id
                          from content_sections
                          where scope='group'
                          and user_group_group_type(group_id)='$QQgroup_type')
or to_section_id in (select section_id
                          from content_sections
                          where scope='group'
                          and user_group_group_type(group_id)='$QQgroup_type')
"

ns_db dml $db "
delete from content_files
where section_id in (select section_id
                     from content_sections
                     where scope='group'
                     and user_group_group_type(group_id)='$QQgroup_type')
"

ns_db dml $db "
delete from content_sections
where scope='group'
and user_group_group_type(group_id)='$QQgroup_type'
"

ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_write "

<li>Deleting the groups of this type...

"

ns_write "<li>Deleting groups faqs... "

ns_db dml $db "
delete from faqs
where scope='group'
and user_group_group_type(group_id)='$QQgroup_type'
"

ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_write "<li>Deleting groups logos... "

ns_db dml $db "
delete from page_logos
where scope='group'
and user_group_group_type(group_id)='$QQgroup_type'
"

ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_write "<li>Deleting groups css... "

ns_db dml $db "
delete from css_simple
where scope='group'
and user_group_group_type(group_id)='$QQgroup_type'
"
ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_write "<li>Deleting groups address books... "

ns_db dml $db "
delete from address_book
where scope='group'
and user_group_group_type(group_id)='$QQgroup_type'
"
ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_write "<li>Deleting groups downloads ... "

ns_db dml $db "
delete from downloads
where scope='group'
and user_group_group_type(group_id)='$QQgroup_type'
"
ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_db dml $db "delete from user_groups where group_type =  '$QQgroup_type'"

ns_write "[ns_ora resultrows $db] rows deleted.

<li>Deleting rows about which extra fields to store for this kind of group...
"

ns_db dml $db "delete from user_group_type_fields where group_type =  '$QQgroup_type'"

ns_write "[ns_ora resultrows $db] rows deleted."

ns_write "<li>Deleting any group type specific member fields... "

ns_db dml $db "delete from user_group_type_member_fields where group_type = '$QQgroup_type'"

ns_write "[ns_ora resultrows $db] rows deleted."

ns_write "
<li>Removing the modules associated with $pretty_name ... 
"

ns_db dml $db "
delete from user_group_type_modules_map 
where group_type='$QQgroup_type'
"

ns_write "[ns_ora resultrows $db] rows deleted."

ns_write "
<li>Deleting the row from the user_group_types table... 
"

ns_db dml $db "delete from user_group_types where group_type =  '$QQgroup_type'"

ns_write "[ns_ora resultrows $db] rows deleted.

<li>Committing changes....
"

set info_table_name "${QQgroup_type}_info"

if [ns_table exists $db [string tolower $info_table_name]] {
    ns_write "
<li>Deleting the special table to hold group info...
"
    ns_db dml $db "drop table $info_table_name"
    ns_write "done.\n"
}

ns_db dml $db "end transaction"

ns_write "

</ul>

[ad_admin_footer]
"
