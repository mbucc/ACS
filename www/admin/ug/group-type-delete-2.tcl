
ad_page_contract {
    @param group_type the type of group

    @cvs-id group-type-delete-2.tcl,v 3.2.2.8 2000/09/22 01:36:14 kevin Exp
} {
    group_type:notnull
}



if { [db_0or1row get_user_group_type_nfo "select pretty_name from user_group_types where group_type = :group_type"]==0 } {
    ad_return_complaint 1 "Group Already Deleted, perhaps you doubleclicked"
    return
}

set page_html "[ad_admin_header "Deleting $pretty_name"]

<h2>Deleting $pretty_name</h2>

one of <a href=\"index\">the group types</a> in 
<a href=\"/admin\">[ad_system_name] administration</a> 

<hr>

"

db_transaction {

# user doesn't really need to hear about this 


db_dml cslinks_delete "
delete from content_section_links
where from_section_id in (select section_id
                          from content_sections
                          where scope='group'
                          and user_group_group_type(group_id)=:group_type)
or to_section_id in (select section_id
                          from content_sections
                          where scope='group'
                          and user_group_group_type(group_id)=:group_type)
"

db_dml content_files_delete "
delete from content_files
where section_id in (select section_id
                     from content_sections
                     where scope='group'
                     and user_group_group_type(group_id)=:group_type)
"

db_dml cs_delete_group "
delete from content_sections
where scope='group'
and user_group_group_type(group_id)=:group_type
"

append page_html "<ul>

<li>Deleting the user-group mappings for groups of this type...

"

db_dml ugmq_delete "delete from user_group_map_queue where group_id in (select group_id from user_groups where group_type = :group_type)"

db_dml ugm_delete "delete from user_group_map where group_id in (select group_id from user_groups where group_type = :group_type)"

append page_html "[db_resultrows] rows deleted.\n

<li>Deleting groups faqs... 
"

db_dml faq_delete_group "
delete from faqs
where scope='group'
and user_group_group_type(group_id)=:group_type
"

append page_html "[db_resultrows] rows deleted.\n"

append page_html "<li>Deleting groups news items... "

db_dml news_items_delete_group "
delete from news_items
where newsgroup_id in (select newsgroup_id
                       from newsgroups
                       where scope = 'group'
                       and user_group_group_type(group_id)=:group_type)
"

append page_html "[db_resultrows] rows deleted.\n"

append page_html "<li>Deleting groups newsgroups... "

db_dml newsgroup_group_delete "
delete from newsgroups
where scope = 'group'
and user_group_group_type(group_id)=:group_type
"

append page_html "[db_resultrows] rows deleted.\n"

append page_html "<li>Deleting groups logos... "

db_dml page_logos_delete_group "
delete from page_logos
where scope='group'
and user_group_group_type(group_id)=:group_type
"

append page_html "[db_resultrows] rows deleted.\n"

append page_html "<li>Deleting groups css... "

db_dml css_simple_delete_group "
delete from css_simple
where scope='group'
and user_group_group_type(group_id)=:group_type
"
append page_html "[db_resultrows] rows deleted.\n"

append page_html "<li>Deleting groups address books... "

db_dml ab_delete_group "
delete from address_book
where scope='group'
and user_group_group_type(group_id)=:group_type
"
append page_html "[db_resultrows] rows deleted.\n"

append page_html "<li>Deleting groups downloads ... "

db_dml download_delete_group "
delete from downloads
where scope='group'
and user_group_group_type(group_id)=:group_type
"
append page_html "[db_resultrows] rows deleted.\n"

append page_html "<li>Deleting groups portal mappings ..."

db_dml portal_table_delete_group "
delete from portal_table_page_map ptpm
where exists (select 1
              from portal_pages pp
              where pp.page_id = ptpm.page_id
              and user_group_group_type(pp.group_id) = :group_type)
"
append page_html "[db_resultrows] rows deleted.\n"

append page_html "<li>Deleting groups portal pages ..."

db_dml portal_pages_delete_grouptype "
delete from portal_pages
where user_group_group_type(group_id) = :group_type
"
append page_html "[db_resultrows] rows deleted.\n"

append page_html "<li>Deleting rows about which extra fields to store for this kind of group..."

db_dml ugtf_delete_group_type "delete from user_group_type_fields where group_type =  :group_type"

append page_html "[db_resultrows] rows deleted."

append page_html "<li>Deleting any group specific member fields... "

db_dml ugmf_delete_group_type "delete from user_group_member_fields ugmf where ugmf.group_id in (select ug.group_id from user_groups ug where group_type = :group_type)"

append page_html "[db_resultrows] rows deleted."

append page_html "<li>Deleting any group type specific member fields... "

db_dml ugtmf_delete_group_type "delete from user_group_type_member_fields where group_type = :group_type"

append page_html "[db_resultrows] rows deleted."

append page_html "
<li>Removing the modules associated with $pretty_name ... 
"

db_dml ugtmmap_delete_group_type "
delete from user_group_type_modules_map 
where group_type=:group_type
"

append page_html "[db_resultrows] rows deleted."


set info_table_name [string toupper "${group_type}_info"]
if { [db_string info_table_exists "select count(*) from user_tables where table_name = :info_table_name"] > 0 } {
    append page_html "
    <li>Deleting the special table to hold group info...\n"
    db_dml drop_info_table "drop table $info_table_name"
    append page_html "done.\n"
}

set info_audit_table_name [string toupper ${info_table_name}_audit]
if { [db_string info_audit_table_exists "select count(*) from user_tables where table_name = :info_audit_table_name"] > 0 } {
    append page_html "
    <li>Deleting the special table to hold group info...\n"
    db_dml drop_info_table "drop table $info_table_name"
    append page_html "done.\n"
}


set trigger_name [string toupper ${info_table_name}_audit_tr]
if { [db_string info_table_audit_trigger "select 1 from user_objects where object_name = :trigger_name"] > 0 } {
    append page_html "
    <li>Deleting the audit trail trigger ..." 
    db_dml "drop trigger ${info_table_name}_audit_tr"
    append page_html "done.\n"
}

append page_html "<li>Deleting user_groups of this type...."

db_dml ug_delete_gtype "delete from user_groups where group_type =  :group_type"

append page_html "[db_resultrows] rows deleted."

append page_html "<li>Deleting the row from the user_group_types table... 
"

db_dml ug_types_delete_group_type "delete from user_group_types where group_type =  :group_type"

append page_html "[db_resultrows] rows deleted.

<li>Committing changes....
"

}

append page_html "

</ul>

[ad_admin_footer]
"

doc_return  200 text/html $page_html







