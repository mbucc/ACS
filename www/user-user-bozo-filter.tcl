# /user-user-bozo-filter.tcl

ad_page_contract {
    this page implements a bozo filter
    i.e. it makes sure the caller does not get any site-wide email
    from the specified sender   

    @author ahmeds@mit.edu 
    @creation-date: Fri Jan 14 19:27:42 EST 2000
    @cvs-id user-user-bozo-filter.tcl,v 3.2.6.3 2000/09/22 01:34:09 kevin Exp

} {
    sender_id:naturalnum,optional
    process:optional
}

#validate_integer sender_id $sender_id

set exception_count 0
set exception_text ""

if { ![info exists sender_id] || [empty_string_p $sender_id]} {
    incr exception_count
    append exception_text "
    <li>No sender id was passed"
}

if {$exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

if { ![info exists process] || [empty_string_p $process]} {
    set process set_filter
}



set selection [db_0or1row user_user_bozo_filter_get_sender_name "select first_names,last_name
                                  from users
                                  where user_id = :sender_id"]

if { [empty_string_p $selection] } {
    # to sender_id to prevent is not valid
    incr exception_count
    append exception_text "
    <li>Invalid sender id"
} 
#else 
#{

#} 

if {$exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set user_id [ad_verify_and_get_user_id]

set counter [db_string user_user_bozo_filter_get_num_filters "select count(*)
                                                 from user_user_bozo_filter
                                                 where origin_user_id = $user_id"]

if { $process == "unset_filter" } {
    if [catch { db_dml user_user_bozo_filter_remove_filters "delete from user_user_bozo_filter
                               where origin_user_id = $user_id
                               and   target_user_id = $sender_id"  } errmsg ] {
        
        # choked; let's see if it is because filter doesn't already exist	
	if { $counter == 0 } {
	append html "
	No filter was set to prevent you from any emails 
	sent by $first_names $last_name ( ID : $sender_id )"

	} else {  
	    ad_return_error "Ouch!"\
		    "The database choked on delete:
	    <blockquote>
	    $errmsg
	    </blockquote>
	    "  
	    return
	}

    } else {
	set html "
	The filter to prevent you from any emails sent by
	$first_names $last_name ( ID : $sender_id ) has been removed 
	"
    }
    
    append html "
    <p>
    To stop receiving any future emails sent by $first_names $last_name, click 
    <a href=\"user-user-bozo-filter?[export_url_vars sender_id]&process=set_filter\">here</a>
    <p>
    "
} else {
    # process= set_filter			     
				
    if [catch { db_dml user_user_bozo_filter_insert_filter "insert into user_user_bozo_filter
                           (origin_user_id,target_user_id)
                           values 
                           (:user_id,:sender_id )" } errmsg ] {
			       
	# choked; let's see if it is because filter already exists
	
	if { $counter > 0 } {
	    append html "
	    A filter already exists to prevent you from any emails 
	    sent by $first_names $last_name ( ID : $sender_id )  
	    "
	} else {
	    ad_return_error "Ouch!"\
		            "The database choked on your insert:
	                     <blockquote>
	                     $errmsg
	                     </blockquote>
	                     "  
	    return
	}
       
    } else {
	set html "
	A filter has been set to prevent you from any future emails 
	sent by $first_names $last_name ( ID : $sender_id ) 
	"
    }
    
    append html "
    <p>
    To resume receiving emails from $first_names $last_name , click 
    <a href=\"user-user-bozo-filter?[export_url_vars sender_id]&process=unset_filter\">here</a>
    <p>
    "
}

db_release_unused_handles



set process_string [ad_decode $process "set_filter" "Set" "Unset"]

doc_return 200 text/html "
[ad_header "$process_string Bozo Filter" ]
<h2>$process_string Bozo Filter</h2>
[ad_context_bar_ws_or_index  "$process_string Bozo Filter"] 
<hr>

<blockquote>
$html
</blockquote>
[ad_footer]
"
