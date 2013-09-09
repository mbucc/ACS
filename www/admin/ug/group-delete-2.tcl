# /www/admin/ug/group-delete-2.tcl

ad_page_contract {
    Transaction that deletes a user group
 
    @param group_id the id of the group to perform the action on 

    @cvs-id group-delete-2.tcl,v 3.7.2.7 2000/10/27 06:13:11 tony Exp

} {
    group_id:notnull,naturalnum
    { return_url "" }
}


if { ![db_0or1row get_group_info "select group_name, group_type
from user_groups
where group_id = :group_id"] } {
    ad_return_complaint 1 "<li> That group does not exist (<code>group_id</code> $group_id); please check to make sure it hasn't already been deleted"
    return
}

set helper_table_name [ad_user_group_helper_table_name $group_type]

proc subgroup_delete {group_id} {
    upvar helper_table_name helper_table_name
    
    db_transaction {
	db_dml delete_ugmq "delete from user_group_map_queue where group_id = :group_id"
	db_dml delete_user_gm "delete from user_group_map where group_id = :group_id"
	
	# If there is a helper table for this type of user group, then delete
	# the corresponding row from it.
	if { ![empty_string_p $helper_table_name] } {
	    db_dml delete_from_helper_table "delete from $helper_table_name where group_id = :group_id"
	}
	
	db_dml delete_ugmf "delete from user_group_member_fields where group_id = :group_id"
	db_dml delete_from_ugroles "delete from user_group_roles where group_id = :group_id"
	db_dml delete_from_user_garm "delete from user_group_action_role_map where group_id = :group_id"
	db_dml delete_from_gen_permissions "delete from general_permissions where (scope = 'group_role' or scope = 'group') and  group_id = :group_id"
	db_dml delete_from_ugam "delete from user_group_actions where group_id = :group_id"
	db_dml delete_from_cs_links "delete from content_section_links
	where from_section_id in (select section_id
                          from content_sections
                          where scope='group'
                          and group_id=:group_id)
	or to_section_id in (select section_id
                    from content_sections
                    where scope='group'
                    and group_id=:group_id)"
	db_dml delete_g_from_content_files "delete from content_files
	where section_id in (select section_id
                     from content_sections
                     where scope='group'
                     and group_id=:group_id)"
	db_dml delete_grp_from_content_section "delete from content_sections where scope='group' and group_id=:group_id"
	db_dml delete_g_from_content_files "delete from fs_versions
	where file_id in (select file_id
                     from fs_files
                     where group_id=:group_id)"
	db_dml delete_grp_from_content_section "delete from fs_files where group_id=:group_id"
	db_dml delete_from_faq "delete from faqs where scope='group' and group_id=:group_id"
	db_dml delete_g_news_items "delete from news_items where newsgroup_id in (select newsgroup_id
                                                          from newsgroups
                                                          where group_id = :group_id and scope = 'group')"
	db_dml delete_from_newsgroups "delete from newsgroups where scope='group' and group_id=:group_id"
	db_dml delete_from_page_logos "delete from page_logos where scope='group' and group_id=:group_id"
	db_dml delete_from_css_simple "delete from css_simple where scope='group' and group_id=:group_id
	"
	db_dml delete_from_group_downloads "delete from downloads where scope='group' and group_id=:group_id"
	db_dml delete_from_ptpm "delete from portal_table_page_map ptpm
            where exists (select 1
                          from portal_pages pp
                          where pp.page_id = ptpm.page_id
                          and pp.group_id = :group_id)
    "
	db_dml delete_from_pp "delete from portal_pages
            where group_id = :group_id"
	db_dml delete_from_partner "delete from ad_partner where group_id = :group_id"
	set office_p [db_string get_ug_cnt "select count(*)
	                                    from user_groups
	                                    where group_id = :group_id
	                                    and parent_group_id = [im_office_group_id]"]

	if { $office_p > 0 } {
	    db_dml delete_from_im_offices "delete from im_offices where group_id = :group_id"
	}
	
	db_dml delete_from_ug "delete from user_groups where group_id = :group_id"
    }
}
set page_html "[ad_admin_header "Deleting $group_name"]

<h2>Deleting $group_name</h2>

one of <a href=\"index\">the groups</a> in 
<a href=\"/admin\">[ad_system_name] administration</a> 

<hr>

"

db_transaction {

    append page_html  "<ul>
    <li>Deleting subgroups...
    <blockquote> "

    db_foreach subgroup_list "select group_id as sub_group_id, group_name as sub_group_name from user_groups where parent_group_id = :group_id" {
	subgroup_delete $sub_group_id
	append page_html "<br>$sub_group_name"
    } if_no_rows {
	append page_html "None"
    }

    append page_html "</blockquote>
    <li>Deleting the user-group mappings for groups of this type..."

    # user doesn't really need to hear about this 
    db_dml delete_ugmq "delete from user_group_map_queue where group_id = :group_id"

    db_dml delete_user_gm "delete from user_group_map where group_id = :group_id"

    append page_html "[db_resultrows] rows deleted.\n"

    #
    # If there is a helper table for this type of user group, then delete
    # the corresponding row from it.
    #
    set helper_table_name [ad_user_group_helper_table_name $group_type]

    if { ![empty_string_p $helper_table_name] } {

	append page_html "<li>Deleting group type specific fields... "

	db_dml delete_from_helper_table "delete from $helper_table_name where group_id = :group_id"

    } else {

	append page_html "<li>No group type specific fields to be deleted... "
    }

    append page_html "<li>Deleting group specific member fields... "

    db_dml delete_ugmf "delete from user_group_member_fields where group_id = :group_id"

    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting group permissions... "

    db_dml delete_from_ugroles "delete from user_group_roles where group_id = :group_id"

    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting permission mappings... "

    db_dml delete_from_user_garm "delete from user_group_action_role_map where group_id = :group_id"

    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting permission records... "

    db_dml delete_from_gen_permissions "delete from general_permissions where (scope = 'group_role' or scope = 'group') and  group_id = :group_id"

    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting group actions... "

    db_dml delete_from_ugam "delete from user_group_actions where group_id = :group_id"

    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting $group_name content section links... "

    db_dml delete_from_cs_links "delete from content_section_links
where from_section_id in (select section_id
                          from content_sections
                          where scope='group'
                          and group_id=:group_id)
or to_section_id in (select section_id
                    from content_sections
                    where scope='group'
                    and group_id=:group_id)"

    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting $group_name content section files... "

    db_dml delete_g_from_content_files "delete from content_files
where section_id in (select section_id
                     from content_sections
                     where scope='group'
                     and group_id=:group_id)"

    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting $group_name content sections... "

    db_dml delete_grp_from_content_section "delete from content_sections where scope='group' and group_id=:group_id"

    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting $group_name file storage file versions... "

    db_dml delete_g_from_content_files "delete from fs_versions
where file_id in (select file_id
                     from fs_files
                     where group_id=:group_id)"

    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting $group_name file storage files... "

    db_dml delete_grp_from_content_section "delete from fs_files where group_id=:group_id"

    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting $group_name faqs... "

    db_dml delete_from_faq "delete from faqs where scope='group' and group_id=:group_id"

    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting $group_name news items... "

    db_dml delete_g_news_items "delete from news_items where newsgroup_id in (select newsgroup_id
                                                          from newsgroups
                                                          where group_id = :group_id and scope = 'group')"

    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting $group_name newsgroups... "

    db_dml delete_from_newsgroups "delete from newsgroups where scope='group' and group_id=:group_id"

    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting $group_name logo... "

    db_dml delete_from_page_logos "delete from page_logos where scope='group' and group_id=:group_id"

    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting $group_name css... "

    db_dml delete_from_css_simple "delete from css_simple where scope='group' and group_id=:group_id
    "
    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting $group_name downloads ... "

    db_dml delete_from_group_downloads "delete from downloads where scope='group' and group_id=:group_id"

    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting $group_name portal page mappings ... "

    db_dml delete_from_ptpm "delete from portal_table_page_map ptpm
            where exists (select 1
                          from portal_pages pp
                          where pp.page_id = ptpm.page_id
                          and pp.group_id = :group_id)
    "
    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting $group_name portal pages ... "

    db_dml delete_from_pp "delete from portal_pages
            where group_id = :group_id
    "
    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting $group_name spam history ... "

    db_dml delete_from_spam_history "delete from group_spam_history where group_id = :group_id"

    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting $group_name partner entries ... "

    db_dml delete_from_partner "delete from ad_partner where group_id = :group_id"

    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Deleting this group... "

    set office_p [db_string get_ug_cnt "select count(*)
from user_groups
where group_id = :group_id
and parent_group_id = [im_office_group_id]"]

    if { $office_p > 0 } {
	db_dml delete_from_im_offices "delete from im_offices where group_id = :group_id"
    }

    db_dml delete_from_ug "delete from user_groups where group_id = :group_id"

    append page_html "[db_resultrows] rows deleted.\n"

    append page_html "<li>Committing changes...."
} on_error {
    ad_return_error "Oracle Error" "Oracle is complaining about this procedure:\n<pre>\n$errmsg\n</pre>\n"
    ad_script_abort
}

append page_html "

</ul>

[ad_admin_footer]
"


if [empty_string_p $return_url] {
    doc_return  200 text/html $page_html
} else {
    ad_returnredirect $return_url
}




