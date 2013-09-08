# /www/wp/presentation-acl-add-group.tcl

ad_page_contract {
    Allows an administrator to add a group to an ACL list.    

    @author Jon Salz <jsalz@mit.edu>
    @creation-date 26 April 2000
    
    @param presentation_id the ID of the presentation
    @param role the type of permission being granted (read, write, admin)

    @cvs-id presentation-acl-add-group.tcl,v 3.1.6.4 2000/09/22 01:39:31 kevin Exp
} {
    presentation_id:integer
    role
}

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "admin"

db_1row select_presentation "select presentation_id, \
	        title
	from wp_presentations where presentation_id = :presentation_id" 


set page_content ""
append page_content "[wp_header_form "action=presentation-acl-add-group-2" \
           [list "" "WimpyPoint"] [list "index?show_user=" "Your Presentations"] \
           [list "presentation-top?presentation_id=$presentation_id" "$title"] \
           [list "presentation-acl?presentation_id=$presentation_id" "Authorization"] "Add Group"]

[export_form_vars presentation_id role]

<center>

<p><table border=2 cellpadding=10 width=60%><tr><td>
<table cellspacing=0 cellpadding=0>
<tr><td colspan=2>Please select the name of the group
you wish to give permission to [wp_role_predicate $role $title].
Only groups of which you a member are listed.
<hr></td></tr>
<tr><td align=center><select name=group_id>"

set groups ""
  
# select all groups that this user is a part of
db_foreach select_group_details "
    select ugt.pretty_name, ug.group_name, ug.group_id
    from   user_group_map ugm, user_groups ug, user_group_types ugt
    where  ugm.user_id = $user_id
    and    ugm.group_id = ug.group_id
    and    ug.group_type = ugt.group_type
    order by upper(group_name)
" {
    append groups "<option value=$group_id>$pretty_name - $group_name\n"
}

append page_content "$groups</select>
<tr><td colspan=2 align=center>
<hr>
<input type=submit value=Add Members>
</td></tr>
</table></td></tr></table></p></center>

[wp_footer]
"

db_release_unused_handles
doc_return 200 "text/html" $page_content


