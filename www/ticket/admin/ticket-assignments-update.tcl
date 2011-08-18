# $Id: ticket-assignments-update.tcl,v 3.0.4.1 2000/04/28 15:11:37 carsten Exp $
ad_page_variables {return_url}
set form [ns_getform]

set db [ns_db gethandle] 
set my_user_id [ad_get_user_id]

if {[empty_string_p $form]} { 
    ad_return_complaint 1 "<LI>You did not send me any information"
    return
}

set size [ns_set size $form]

# make a list of the changed assignments.
set bad 0
set badstr {}
set map {}
for  {set i 0} {$i < $size} { incr i} {
    set new_user_id [ns_set value $form $i]
    if {[regexp {^a_(([0-9]+)_([0-9]+))_([0-9]*)} [ns_set key $form $i] match pg project_id domain_id user_id]} { 
        if {[string compare $new_user_id $user_id] != 0} { 
            if {[info exists seen($pg)]} { 
                incr bad 
                append badstr "<LI> You had a duplicate entry for project $project_id domain $domain_id"
            } else { 
                if {[empty_string_p $user_id]} { 
                    set user_id_check "default_assignee is null"
                } else { 
                    set user_id_check "default_assignee = $user_id"
                }
                if {[empty_string_p $new_user_id]} {
                    set new_user_id null
                }
                set seen($pg) 1
                lappend map [list $project_id $domain_id $user_id_check $new_user_id]
            }
        }
    }
}
            
if { $bad } {
    ad_return_complaint $bad $badstr
    return 
}

if { [empty_string_p $map] } {
    ad_return_complaint 1 "<LI>You did not change anything"
    return
}

# now generate the update statements

with_transaction $db { 
    foreach amap $map { 
        ns_db dml $db "update ticket_domain_project_map set default_assignee = [lindex $amap 3] 
  where $user_id_check and project_id = [lindex $amap 0] and domain_id = [lindex $amap 1]"
    }
} { 
    ad_return_complaint 1 "<LI>Database failure performing update <pre>$errmsg</pre>"
    return
}

ad_returnredirect $return_url 
