# File:     /admin/ug/group-module-remove-2.tcl
ad_page_contract {
    Purpose:  removes association between module and the group
    @param group_id the ID of the group
    @param module_key the handle for the module
    @param confirm_button use a confirm button

    @author tarik@arsdigita.com
    @creation-date 1 January 2000
    @cvs-id group-module-remove-2.tcl,v 3.2.2.4 2000/07/22 06:15:39 ryanlee Exp

} {
    group_id:notnull,naturalnum
    module_key:notnull
    confirm_button
}


set return_url "group?group_id=$group_id"

if { [string compare $confirm_button yes]!=0 } {
    ad_returnredirect $return_url
    return
}

db_transaction {

db_dml cs_links_delete "
delete from content_section_links
where from_section_id=(select section_id
                       from content_sections
                       where scope='group'
                       and group_id=:group_id
                       and module_key=:module_key)
or to_section_id=(select section_id
                  from content_sections
                  where scope='group'
                  and group_id=:group_id
                  and module_key=:module_key)
"

db_dml cs_content_delete "
delete from content_files
where section_id=(select section_id
                  from content_sections
                  where scope='group'
                  and group_id=:group_id
                  and module_key=:module_key)
"

db_dml cs_delete_group "
delete from content_sections
where scope='group'
and group_id=:group_id
and module_key=:module_key
"

} on_error {
    ad_return_error "Oracle Error" "Oracle returned the following error:\n<pre>\n$errmsg\n</pre>\n"
}

ad_returnredirect $return_url

