# 
# /www/education/class/admin/grade-policy-edit-2.tcl
#
# by aileen@mit.edu, randyg@arsdigita.com, February 2000
#
# this page updates the database with the new information about the
# particular grade ID
#

# comments_$grade_id, grade_name_$grade_id, weight_$grade_id and
# new_comments_(1-5)
# new_grade_name_(1-5), new_weight_(1-5)

set_the_usual_form_variables
set error_count 0
set error_text ""

set add_id_list ""
set delete_id_list ""

set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Evaluate"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]



# check the input for each existing grade entry, they must have either
# both the grade names and the weight filled in or neither (in which
# case the entry will be deleted) 
foreach grade_id $grade_id_list {
    if {![info exists grade_name_$grade_id] || [empty_string_p [set grade_name_$grade_id]]} {
	if {[info exists weight_$grade_id] && ![empty_string_p [set weight_$grade_id]]} {
	    
	    if {!$error_count} {
		incr error_count
		append error_text "<li>You must have both a name and weight for each grade entry. Leave both fields blank if you wish to delete that entry"
	    }
	} else {
	    # both weight and grade_name are blank, so mark this entry for 
	    # deletion
	    lappend delete_id_list $grade_id
	    continue
	}
	    
    } elseif {![info exists weight_$grade_id] || [empty_string_p [set weight_$grade_id]]} {
	if {!$error_count} {
	    incr error_count
	    append error_text "<li>You must have both a name and weight for each grade entry. Leave both fields blank if you wish to delete that entry"
	}
    }

   lappend add_id_list $grade_id
}

set count 1
set new_entries_list ""

while {$count<=5} {
    if {![info exist new_grade_name_$count] || [empty_string_p [set new_grade_name_$count]]} {
	if {[info exists new_weight_$count] && ![empty_string_p [set new_weight_$count]]} {
	    if {!$error_count} {
		append error_text "<li>You must have both a name and weight for each grade entry. Leave both fields blank if you wish to delete that entry"
		incr error_count
	    }
	} else {
	    incr count
	    continue
	}
    } elseif {![info exists new_weight_$count] || [empty_string_p [set new_weight_$count]]} {
	if {!$error_count} {
	    incr error_count
	    append error_text "<li>You must have both a name and weight for each grade entry. Leave both fields blank if you wish to delete that entry"
	}
    }
   
    lappend new_entries_list $count
    incr count
}

if {$error_count} {
    ad_return_complaint $error_count $error_text
    return
}

# now make sure the weights add up to 100%

set sum 0

foreach id $add_id_list {
    set sum [expr $sum + [set weight_${id}]]
}

foreach id $new_entries_list {
    set sum [expr $sum + [set new_weight_${id}]]
}

# in case we have decimals
if {$sum>100 || $sum<100} {
    ad_return_complaint 1 "<li>Weights of all grades must add up to 100%"
    return
}

# input checks complete

ns_db dml $db "begin transaction"

foreach id $delete_id_list {
    ns_db dml $db "delete from edu_grades where grade_id=$id"
    ad_audit_delete_row $db [list $id] [list grade_id] edu_grades_audit
}

foreach id $add_id_list {
    ns_db dml $db "
    update edu_grades 
    set grade_name='[set QQgrade_name_$id]',
    weight=[set weight_$id],
    comments='[set QQcomments_$id]',
    modified_ip_address = '[ns_conn peeraddr]',
    last_modifying_user = $user_id
    where grade_id=$id"
}

foreach id $new_entries_list {
    ns_db dml $db "
    insert into edu_grades 
    (grade_id, grade_name, weight, comments, class_id, last_modified, last_modifying_user, modified_ip_address)
    values
    (edu_grade_sequence.nextval, '[set QQnew_grade_name_$id]', [set new_weight_$id], '[set QQnew_comments_$id]', $class_id, sysdate, $user_id, '[ns_conn peeraddr]')"
}

ns_db dml $db "end transaction"

ns_db releasehandle $db

ad_returnredirect ""


