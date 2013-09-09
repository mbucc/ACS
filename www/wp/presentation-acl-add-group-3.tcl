# /www/wp/presentation-acl-add-group-3.tcl

ad_page_contract {
    Adds a group to an ACL.    

    @author Jon Salz <jsalz@mit.edu>
    @creation-date 28 Nov 1999

    @param presentation_id the ID of the presentation
    @param role type of permission being granted (read, write, admin)
    @param req_group_id group group_id of the user_group containing users we want to add permissions to

    @cvs-id presentation-acl-add-group-3.tcl,v 3.1.6.9 2000/08/16 21:49:40 mbryzek Exp
} {
    presentation_id:integer
    role
    req_group_id:integer
}

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "admin"

db_1row select_presentation "select presentation_id, \
	                            title, \
				    group_id as presentation_group_id\
		             from wp_presentations where presentation_id = :presentation_id" 

# must map to presentation group_id (might already be mapped so check)

# first get users in group
set add_user_list [list]
db_foreach select_group_members "
   select ugm.user_id
   from users u, user_group_map ugm
   where ugm.group_id = :req_group_id
   and   ugm.user_id = u.user_id
" {
    lappend add_user_list $user_id
}

foreach user_in_list $add_user_list {
    # is user mapped to presentation group_id ?
    if { [db_string user_mapped " select decode( count(*), 0, 0, 1) \
	    from user_group_map \
	    where user_id = :user_in_list \
	    and group_id = :presentation_group_id " ] } {
	# update
	db_dml update_user_info " update user_group_map \
		set role = :role, \
		 mapping_user = :user_id,\
		 mapping_ip_address = '[ns_conn peeraddr]' \
		where user_id = :user_in_list \
		 and  group_id = :presentation_group_id "
    } else {
	# insert
	db_dml insert_user_info " insert into user_group_map \
		(group_id, user_id, role, mapping_user, mapping_ip_address) \
		values \
		( :presentation_group_id, :user_in_list, :role, :user_id, '[ns_conn peeraddr]')	"
    }
}

db_release_unused_handles
ad_returnredirect "presentation-acl?presentation_id=$presentation_id"




