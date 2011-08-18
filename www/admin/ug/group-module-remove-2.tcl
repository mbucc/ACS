# $Id: group-module-remove-2.tcl,v 3.0.4.1 2000/04/28 15:09:29 carsten Exp $
# File:     /admin/ug/group-module-remove-2.tcl
# Date:     01/01/2000
# Contact:  tarik@arsdigita.com
# Purpose:  removes association between module and the group

set_the_usual_form_variables
# group_id, module_key, confirm_button

set return_url "group.tcl?group_id=$group_id"

if { [string compare $confirm_button yes]!=0 } {
    ad_returnredirect $return_url
    return
}

set db [ns_db gethandle]

ns_db dml $db "begin transaction"

ns_db dml $db "
delete from content_section_links
where from_section_id=(select section_id
                       from content_sections
                       where scope='group'
                       and group_id=$group_id
                       and module_key='$QQmodule_key')
or to_section_id=(select section_id
                  from content_sections
                  where scope='group'
                  and group_id=$group_id
                  and module_key='$QQmodule_key')
"

ns_db dml $db "
delete from content_files
where section_id=(select section_id
                  from content_sections
                  where scope='group'
                  and group_id=$group_id
                  and module_key='$QQmodule_key')
"

ns_db dml $db "
delete from content_sections
where scope='group'
and group_id=$group_id
and module_key='$QQmodule_key'
"

ns_db dml $db "end transaction"

ad_returnredirect $return_url


