# /www/admin/users/approve.tcl

ad_page_contract {

    Process the approval of a new user account

    @cvs-id approve.tcl,v 3.3.2.3.2.6 2000/08/08 00:09:49 kevin Exp
} {
    user_id:integer,notnull
}


set admin_id [ad_verify_and_get_user_id]

db_1row user_info "
select first_names || ' ' || last_name as name, 
       user_state, 
       email_verified_date, 
       email 
from   users 
where  user_id = :user_id"

# Update the database based on the user's current state

switch $user_state {    

    need_admin_approv { 
	db_dml set_user_state_authorized "
	update users 
	set    approved_date  = sysdate, 
	       user_state     = 'authorized',
	       approving_user = :admin_id
	where  user_id        = :user_id"
    }

    need_email_verification_and_admin_approv {
	db_dml set_user_state_need_email_verification "
	update users 
	set    approved_date  = sysdate, 
               user_state     = 'need_email_verification',
	       approving_user = :admin_id
	where  user_id        = :user_id"
    }

    rejected {

	if {[ad_parameter RegistrationRequiresEmailVerificationP "" 0] && \
		[empty_string_p $email_verified_date]} {
	    db_dml set_user_state_need_email_verification "
	    update users 
	    set    approved_date  = sysdate, 
                   user_state     = 'need_email_verification',
	           approving_user = :admin_id
	    where  user_id        = :user_id"
	} else {
	    db_dml set_user_state_authorized "
	    update users 
	    set    approved_date  = sysdate, 
	           user_state     = 'authorized',
	           approving_user = :admin_id
	    where  user_id        = :user_id"
	}
    }

    default {
	ad_return_error "Invalid User State" "
	The user account you are attempting to approve is currently in
	an unrecognized state in the database."
	return
    }
}

db_release_unused_handles

ns_sendmail $email "[ad_parameter NewRegistrationEmailAddress "" [ad_system_owner]]" "Welcome to [ad_system_name]" "Your membership to [ad_system_name] has been approved.  Please return to [ad_parameter SystemUrl]." 

# Redirect back to the need_admin_approv page so the administrator can
# continue with other users if necessary

ad_returnredirect "view?user_state=[ns_urlencode need_admin_approv]"








