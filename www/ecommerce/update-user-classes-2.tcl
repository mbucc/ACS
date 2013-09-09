#  www/ecommerce/update-user-classes-2.tcl
ad_page_contract {
    @param user_class_id ID of the user class
    @param usca_p User session begun or not
    @author
    @creation-date
    @cvs-id update-user-classes-2.tcl,v 3.2.2.7 2000/08/18 21:46:37 stevenp Exp
} {
    user_class_id:multiple
    usca_p:optional
}

set user_class_id_list $user_class_id

set user_id [ad_verify_and_get_user_id]

set ip_address [ns_conn peeraddr]

if {$user_id == 0} {
    
    set return_url "[ad_conn url]"

    ad_returnredirect "/register?[export_url_vars return_url]"
    return
}

set user_session_id [ec_get_user_session_id]

ec_create_new_session_if_necessary
# type1

ec_log_user_as_user_id_for_this_session

# update User Class

db_transaction {

    # Get old user_class_ids
    set old_user_class_id_list [db_list get_old_class_ids "select user_class_id 
    from ec_user_class_user_map 
    where user_id = :user_id"]

    # Add the user_class if it is not already there
    foreach user_class_id $user_class_id_list {
	if { [lsearch -exact $old_user_class_id_list $user_class_id] == -1 && ![empty_string_p $user_class_id] } {
	    set sql "insert into 
	    ec_user_class_user_map (
	    user_id, user_class_id, user_class_approved_p, last_modified, last_modifying_user, modified_ip_address
	    ) values (
	    :user_id, :user_class_id, NULL, sysdate, :user_id, :ip_address)"
	
	    if [catch { db_dml insert_into_user_class_map $sql } errmsg] {
		ad_return_error "Ouch!" "The database choked on our update:
		<blockquote>
		$errmsg
		</blockquote>
		"
	    }
	}
    }

    # Delete the user_class if it is not in the new list
    foreach old_user_class_id $old_user_class_id_list {
	if { [lsearch -exact $user_class_id_list $old_user_class_id] == -1 && ![empty_string_p $old_user_class_id] } {
	    set sql "delete from ec_user_class_user_map 
	    where user_id = :user_id 
	    and user_class_id = :old_user_class_id"
	
	    if [catch { db_dml delete_from_user_class_map $sql } errmsg] {
		ad_return_error "Ouch!" "The database choked on our update:
		<blockquote>
		$errmsg
		</blockquote>
		"
	    }
	    ad_audit_delete_row [list $user_id $old_user_class_id] [list user_id user_class_id] ec_user_class_user_map_audit
	}
    }
    
}
db_release_unused_handles

ad_returnredirect "account"
