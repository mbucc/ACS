#/admin/ug/group-type-module-remove-2.tcl

ad_page_contract {
    Removes association between module and the group type.
    @param group_type the type of group
    @param module_key the handle of the module
    @param confirm_button do we display a confirm button

    @cvs-id group-type-module-remove-2.tcl,v 3.2.2.4 2000/07/22 06:42:58 ryanlee Exp
    @author tarik@arsdigita.com
    @creation-date 22 December 1999
} {
    group_type:notnull
    module_key:notnull
    confirm_button
}

set return_url "group-type?group_type=[ns_urlencode $group_type]"

if { [string compare $confirm_button yes]!=0 } {
    ad_returnredirect $return_url
    return
}



db_transaction {

db_dml ugtmm_delete "
delete from user_group_type_modules_map 
where group_type=:group_type and module_key=:module_key
"

db_dml cslinks_delete "
delete from content_section_links
where from_section_id in (select section_id
                          from content_sections
                          where scope='group'
                          and user_group_group_type(group_id)=:group_type
                          and module_key=:module_key)
or to_section_id in (select section_id
                          from content_sections
                          where scope='group'
                          and user_group_group_type(group_id)=:group_type
                          and module_key=:module_key)
"

db_dml content_files_delete "
delete from content_files
where section_id in (select section_id
                     from content_sections
                     where scope='group'
                     and user_group_group_type(group_id)=:group_type
                     and module_key=:module_key)
"

db_dml content_sections_delete "
delete from content_sections
where scope='group'
and user_group_group_type(group_id)=:group_type
and module_key=:module_key
"

if { $module_key=="content-sections" } {
    # special case: if we are removing content-sections module, we want to make sure
    # that group_module_administration is set to none, becase full and enabling group_module_administration
    # don't make sense if content-sections module is not installed
    db_dml update_gma_w_gt "
    update user_group_types set group_module_administration='none' where group_type=:group_type
    "
}

}

ad_returnredirect $return_url




