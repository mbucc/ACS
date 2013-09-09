# /www/wp/presentation-acl-add-group-2.tcl

ad_page_contract {
    Adds a group to an ACL (after confirming). 

    @author Jon Salz <jsalz@mit.edu>
    @creation-date 28 Nov 1999
    
    @param presentation_id the ID of the presentation
    @param role type of permission being granted (read, write, admin)
    @param group_id group we are granting permission to

    @cvs-id presentation-acl-add-group-2.tcl,v 3.1.6.7 2000/09/22 01:39:31 kevin Exp
} {
    presentation_id:integer
    role 
    group_id:integer
}

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "admin"

# req_group_id of users we want to access role to
set req_group_id $group_id


db_1row select_presentation "select presentation_id, \
	                            title \
			     from wp_presentations where presentation_id = :presentation_id" 


set page_content ""
append page_content "[wp_header_form "action=presentation-acl-add-group-3" \
           [list "" "WimpyPoint"] [list "index?show_user=" "Your Presentations"] \
           [list "presentation-top?presentation_id=$presentation_id" "$title"] \
           [list "presentation-acl?presentation_id=$presentation_id" "Authorization"] "Confirm Add User"]

[export_form_vars presentation_id role req_group_id]

<p>Are you sure you want to give the following users permission to [wp_role_predicate $role $title]?

<ul>
"

set users ""

# users mapped to the group we selected
db_foreach select_group_details "
    select u.first_names, u.last_name
    from   users u, user_group_map ugm
    where  ugm.group_id = :req_group_id
    and    ugm.user_id = u.user_id
    order  by upper(last_name), upper(first_names)
" {
    append users "<li>$first_names $last_name\n"
}

append page_content "$users</ul>

<p><center>
<input type=button value=\"No, I want to cancel.\" onClick=\"location.href='presentation-acl?presentation_id=$presentation_id'\">
<spacer type=horizontal size=50>
<input type=submit value=\"Yes, proceed.\">
</p></center>

[wp_footer]
"

doc_return  200 "text/html" $page_content













