# $Id: update-user-classes-2.tcl,v 3.0.4.1 2000/04/28 15:10:04 carsten Exp $
set_form_variables 0
# user_class_id, which is a select multiple
# possibly usca_p

set form [ns_getform]
set form_size [ns_set size $form]
set form_counter 0

set user_class_id_list [list]

while {$form_counter<$form_size} {
    if {[ns_set key $form $form_counter]=="user_class_id"} {
	lappend user_class_id_list [ns_set value $form $form_counter]
    }
    incr form_counter
}

set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set user_session_id [ec_get_user_session_id]

set db [ns_db gethandle]
ec_create_new_session_if_necessary
# type1

ec_log_user_as_user_id_for_this_session

# update User Class

ns_db dml $db "begin transaction"

# Get old user_class_ids
set old_user_class_id_list [database_to_tcl_list $db "select user_class_id from ec_user_class_user_map where user_id = $user_id"]

# Add the user_class if it is not already there
foreach user_class_id $user_class_id_list {
    if { [lsearch -exact $old_user_class_id_list $user_class_id] == -1 &&
![empty_string_p $user_class_id] } {
	set sql "insert into 
	ec_user_class_user_map (
	user_id, user_class_id, user_class_approved_p, last_modified, last_modifying_user, modified_ip_address
	) values (
	$user_id, $user_class_id, NULL, sysdate, $user_id, '[DoubleApos [ns_conn peeraddr]]')"
	
	if [catch { ns_db dml $db $sql } errmsg] {
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
    if { [lsearch -exact $user_class_id_list $old_user_class_id] == -1 &&
![empty_string_p $old_user_class_id] } {
	set sql "delete from ec_user_class_user_map where user_id = $user_id and user_class_id = $old_user_class_id"
	
	if [catch { ns_db dml $db $sql } errmsg] {
	    ad_return_error "Ouch!" "The database choked on our update:
	    <blockquote>
	    $errmsg
	    </blockquote>
	    "
	}
	ad_audit_delete_row $db [list $user_id $old_user_class_id] [list user_id user_class_id] ec_user_class_user_map_audit
    }
}

ns_db dml $db "end transaction"

ad_returnredirect "account.tcl"
