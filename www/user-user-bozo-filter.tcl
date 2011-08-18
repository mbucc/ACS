# $Id: user-user-bozo-filter.tcl,v 3.0.4.1 2000/03/17 06:00:51 jsc Exp $
# File: /user-user-bozo-filter.tcl
# Date: Fri Jan 14 19:27:42 EST 2000
# Contact: ahmeds@mit.edu
# Purpose: this page implements a bozo filter
#          i.e. it makes sure the caller does not get any site-wide email 
#          from the specified sender   

set_the_usual_form_variables 0
# sender_id process

validate_integer sender_id $sender_id

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

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select first_names,last_name
                                  from users
                                  where user_id = $sender_id"]

if { [empty_string_p $selection] } {
    # to sender_id to prevent is not valid
    incr exception_count
    append exception_text "
    <li>Invalid sender id"
} else {
    set_variables_after_query
} 

if {$exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set user_id [ad_verify_and_get_user_id]

set counter [database_to_tcl_string $db "select count(*)
                                                 from user_user_bozo_filter
                                                 where origin_user_id = $user_id"]

if { $process == "unset_filter" } {
    if [catch { ns_db dml $db "delete from user_user_bozo_filter
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
    <a href=\"user-user-bozo-filter.tcl?[export_url_vars sender_id]&process=set_filter\">here</a>
    <p>
    "
} else {
    # process= set_filter			     
				
    if [catch { ns_db dml $db "insert into user_user_bozo_filter
                           (origin_user_id,target_user_id)
                           values 
                           ($user_id,$sender_id )" } errmsg ] {
			       
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
    <a href=\"user-user-bozo-filter.tcl?[export_url_vars sender_id]&process=unset_filter\">here</a>
    <p>
    "
}

ReturnHeaders 

set process_string [ad_decode $process "set_filter" "Set" "Unset"]

ns_write "
[ad_header "$process_string Bozo Filter" ]
<h2>$process_string Bozo Filter</h2>
[ad_context_bar_ws_or_index  "$process_string Bozo Filter"] 
<hr>

<blockquote>
$html
</blockquote>
[ad_footer]
"
