# $Id: group-type-module-remove-2.tcl,v 3.0.4.1 2000/04/28 15:09:33 carsten Exp $
# File:     /admin/ug/group-type-module-remove-2.tcl
# Date:     22/12/99
# Contact:  tarik@arsdigita.com
# Purpose:  removes association between module and the group type

set_the_usual_form_variables
# group_type, module_key, confirm_button

set return_url "group-type.tcl?group_type=[ns_urlencode $group_type]"

if { [string compare $confirm_button yes]!=0 } {
    ad_returnredirect $return_url
    return
}

set db [ns_db gethandle]

ns_db dml $db "begin transaction"

ns_db dml $db "
delete from user_group_type_modules_map 
where group_type='$QQgroup_type' and module_key='$QQmodule_key'
"

ns_db dml $db "
delete from content_section_links
where from_section_id in (select section_id
                          from content_sections
                          where scope='group'
                          and user_group_group_type(group_id)='$QQgroup_type'
                          and module_key='$QQmodule_key')
or to_section_id in (select section_id
                          from content_sections
                          where scope='group'
                          and user_group_group_type(group_id)='$QQgroup_type'
                          and module_key='$QQmodule_key')
"

ns_db dml $db "
delete from content_files
where section_id in (select section_id
                     from content_sections
                     where scope='group'
                     and user_group_group_type(group_id)='$QQgroup_type'
                     and module_key='$QQmodule_key')
"

ns_db dml $db "
delete from content_sections
where scope='group'
and user_group_group_type(group_id)='$QQgroup_type'
and module_key='$QQmodule_key'
"

if { $module_key=="content-sections" } {
    # special case: if we are removing content-sections module, we want to make sure
    # that group_module_administration is set to none, becase full and enabling group_module_administration
    # don't make sense if content-sections module is not installed
    ns_db dml $db "
    update user_group_types set group_module_administration='none' where group_type='$QQgroup_type'
    "
}

ns_db dml $db "end transaction"

ad_returnredirect $return_url



