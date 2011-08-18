#
# /tcl/education.tcl
#
# by randyg@arsdigita.com, aileen@arsdigita.com, January 2000
#
# This is the bulk of the tcl procs that are used by the educational module
#

util_report_library_entry

proc_doc edu_url {} "This returns the base url where all of the files are located." {
    return "/education/"
}


proc_doc edu_term_select_widget { db select_name { default "" } } "Returns a selection box that lists all of the available terms that run are current or in the future." {
    set widget_value "<select name=\"$select_name\">\n"
    if { $default == "" } {
        append widget_value "<option value=\"\" SELECTED>Choose a Term</option>\n"
    }

    set selection [ns_db select $db "select term_name, term_id from edu_terms where end_date > sysdate or end_date is null order by end_date"]

    while { [ns_db getrow $db $selection] } {
        set_variables_after_query
	if { $default == $term_id } {
            append widget_value "<option value=\"$term_id\" SELECTED>$term_name</option>\n" 
	} else {            
            append widget_value "<option value=\"$term_id\">$term_name</option>\n"
	}
    }

    append widget_value "</select>\n"
    return $widget_value
}



# the following two procs are used to automatically set up the roles
# and actions for a class when it is created

###################################
#                                 #
#       Begin Role Procs          #
#                                 #
###################################

# the next set of three procs are here so that we do not have to hard code
# ta, professor, or student into the code anywhere.  This will allow us to easily
# change the roles if we so desire.

# If we change the roles here, you also need to change them in the 
# /www/doc/sql/education.sql file

proc_doc edu_get_ta_role_string {} "This returns the string used for the TEACHING ASSISTANT role.  It prevents us from having to hard code Teaching Assistant into the code all over the place." {
    return ta
}


proc_doc edu_get_professor_role_string {} "This returns the string used for the PROFESSOR role.  It prevents us from having to hard code Professor into the code all over the place." {
    return professor
}


proc_doc edu_get_student_role_string {} "This returns the string used for the STUDENT role.  It prevents us from having to hard code Studnet into the code all over the place." {
    return student
}

proc_doc edu_get_dropped_role_string {} "This returns the string used for the Dropped role.  It prevents us from having to hard code Dropped into the code all over the place." {
    return dropped
}


proc_doc edu_get_class_original_role_pretty_role {} "This returns the list of roles and corresponding pretty role and plural pretty role that are used to initialize the roles for a class.  This procedure should only be called from the procedure that sets up a class.  It is a proc only so that is is next to the other place role are hardcoded into TCL" {
    return [list [list [edu_get_professor_role_string] Professor Professors] [list [edu_get_ta_role_string] "Teaching Assistant" "Teaching Assistants"] [list [edu_get_student_role_string] Students Students] [list [edu_get_dropped_role_string] Dropped Dropped]]
}


proc_doc edu_get_class_roles_to_actions_map {} "This returns a role and the corresponding default actions.  This procedure is used to initialize the roles and actions for a new class.  So, each internal list has the first element of a role and the second element is a list of actions the role should start out with." {

    set to_return [list [list [edu_get_professor_role_string] [list "Manage Users" "Add Tasks" "Edit Tasks" "Delete Tasks" "Edit Class Properties" "Manage Communications" "Edit Permissions" "View Admin Pages" "Evaluate" "Spam Users" "Submit Tasks"]]]

    lappend to_return [list [edu_get_ta_role_string] [list "Manage Users" "Add Tasks" "Edit Tasks" "Delete Tasks" "Edit Class Properties" "Manage Communications" "View Admin Pages" "Evaluate" "Spam Users" "Submit Tasks"]]

    lappend to_return [list [edu_get_student_role_string] [list "Spam Users" "Submit Tasks"]]

    lappend to_return [list [edu_get_dropped_role_string] [list]]

    return $to_return
}



proc_doc edu_set_class_roles_and_actions { db class_id } "This takes a class id and a database handle and sets up the class permission options.  This should be called when a class is first created and we want to set up all of the permissions." {

    set roles [edu_get_class_original_role_pretty_role]
    set role_action_map [edu_get_class_roles_to_actions_map]
    set action_list [list "Manage Users" "Add Tasks" "Edit Tasks" "Delete Tasks" "Edit Class Properties" "Manage Communications" "Edit Permissions" "View Admin Pages" "Evaluate" "Spam Users" "Submit Tasks"]

    #the first thing we want to do is add all of the roles
    foreach role $roles {
	ad_user_group_role_add $db $class_id [lindex $role 0]
	# the trigger will have done the insert so now we update
	# the information
	ns_db dml $db "update edu_role_pretty_role_map
                       set pretty_role = '[lindex $role 1]',
                           pretty_role_plural = '[lindex $role 2]'
                       where role = '[lindex $role 0]'"
    }

    #now, add all of the roles
    foreach action $action_list {
	ad_user_group_action_add $db $class_id "$action"
    }

    #now, map the roles to the correct actions
    foreach role_action $role_action_map {
	set role [lindex $role_action 0]
	set action_list [lindex $role_action 1]
	foreach action $action_list {
	    ad_user_group_action_role_map $db $class_id $action $role
	}
    }	
}




proc_doc edu_action_to_pretty_roles { db group_id action } "This takes an action and returns a string of roles that can perform that action." {
    
    if {[empty_string_p $action]} {
	return Public
    } else {
	set roles_list [database_to_tcl_list $db "select pretty_role 
              from user_group_action_role_map ugmap,
                   edu_role_pretty_role_map role_map
             where group_id = $group_id 
               and action = '$action'
               and ugmap.role = role_map.role
      order by sort_key"]
	return [join $roles_list ", "]
    }
}




proc_doc edu_group_user_role_select_widget { db select_name group_id {user_id ""}} "This returns a select box that allows an administrator to select a role for a user." {
    
    if {[empty_string_p $user_id]} {
	set default ""
    } else {
	set default [database_to_tcl_string_or_null $db "select lower(role) from user_group_map where group_id = $group_id and user_id = $user_id"]
    }

    set widget_value "<select name=\"$select_name\">\n"
    if { $default == "" } {
        append widget_value "<option value=\"\" SELECTED>Choose a Role</option>\n"
    }

    set selection [ns_db select $db "select roles.role, pretty_role
              from user_group_roles roles,
                   edu_role_pretty_role_map map
             where roles.group_id = $group_id 
               and lower(roles.role) = lower(map.role)
               and roles.group_id = map.group_id
          order by sort_key"]

    set count 0
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	incr count
	if { [string compare $default [string tolower $role]] == 0 } {
            append widget_value "<option value=\"$role\" SELECTED>$pretty_role</option>\n" 
	} else {            
            append widget_value "<option value=\"$role\">$pretty_role</option>\n"
	}
    }

    if {$count == 0} {
	set role_list [database_to_tcl_list $db "select role from user_group_roles where group_id = $group_id"]

	if {[llength $role_list] == 0} {
	    # we just want to have the list of admin and member
	    set role_list [list administrator member]
	}

	foreach role $role_list {
	    if { [string compare $default $role] == 0 } {
		append widget_value "<option value=\"$role\" SELECTED>[capitalize $role]</option>\n" 
	    } else {            
		append widget_value "<option value=\"$role\">[capitalize $role]</option>\n"
	    }
	}
    }

    append widget_value "</select>\n"
    return $widget_value
}

proc_doc edu_get_roles_for_group {db group_id} "returns a list of list of roles for a group_id and their corresponding pretty names in the form of {{role1 pretty_role1} {role2 pretty_role2} ...}" {
    set selection [ns_db select $db "
    select unique r.role, pretty_role, sort_key 
    from user_group_roles r, edu_role_pretty_role_map m
    where r.group_id=$group_id
    and r.role=m.role 
    order by m.sort_key"]

    set role_list [list]

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	
	lappend role_list [list $role $pretty_role]
    }

    return $role_list
}



proc_doc edu_get_user_role { db user_id group_id } "This returns the role the user has within the group" {
    
    set role [database_to_tcl_string_or_null $db "select pretty_role 
           from user_group_map ugmap,
                edu_role_pretty_role_map role_map
          where user_id = $user_id 
            and group_id = $group_id
            and ugmap.role = role_map.role"]

    if {[empty_string_p $role]} {
	return "None"
    } else {
	return $pretty_role
    }
}



##############################
#                            #
# End role management procs  #
#                            #
##############################






proc_doc edu_empty_row {} "returns an empty table row" {
    return "<tr><td>&nbsp;</td></tr>"
}


proc_doc edu_get_classes {db user_id} "returns a list of class_ids of which user_id is a member" {
    return [database_to_tcl_list $db "
    select class_id 
    from edu_classes c, edu_user_group_map m 
    where m.user_id=$user_id
    and m.group_id=c.class_id"]
}




proc_doc edu_file_upload_widget { db class_id folder_name {default_read ""} {default_write ta} {version_notes_p t}} "This produces the widget that takes care of the file permissions for classes.  It assumes that it is within a table and returns HTML that will fill in two rows of the two column table.  An empty string for a role means that public has that permission" {
    
    set role_list [database_to_tcl_list_list $db "select roles.role,
             pretty_role_plural
        from user_group_roles roles,
             edu_role_pretty_role_map map
       where roles.group_id = $class_id
         and roles.group_id = map.group_id
         and lower(roles.role) = lower(map.role)
       order by priority"]

    lappend role_list [list "" Public]

    set folder_id_str $folder_name
    append folder_id_str "_folder_id"

    set parent_id [database_to_tcl_string $db "select $folder_id_str from edu_classes where class_id = $class_id"]

    set version_id [database_to_tcl_string $db "select fs_version_id_seq.nextval from dual"]
    
    set html "
    <tr>
    <td align=right>URL: </td>
    <td><input type=input name=url size=40></td>
    </tr>
    
    <tr>
    <td align=right><EM>or</EM> filename: </td>
    <td><input type=file name=upload_file size=20>
    <Br><FONT SIZE=-1>Use the \"Browse...\" button to locate your file, then click \"Open\".
    </FONT></td>
    </tr>
    
    
    <tr>
    <td><Br></td>
    </tr>
    "

    if {[string compare $version_notes_p t] == 0} {
	append html "   
	<tr>
	<td valign=top align=right>
	Version Notes:</td>
	<td colspan=2><textarea rows=5 cols=50 name=version_description wrap></textarea></td>
	</tr>
	"
    } 

    append html "
    <tr>
    <td valign=top align=right> Read Permissions:</td>
    <td>"
    
    set role_to_display_list [list]

    foreach role $role_list {
	set role_name [lindex $role 0]
	lappend role_to_display_list [lindex $role 1]
	set role_to_display [join $role_to_display_list ", "]

	if {[string compare [string tolower $default_read] [string tolower $role_name]] == 0 } {
	    append html "<input type=radio name=read_permission value=\"$role_name\" checked> $role_to_display<br>\n"
	} else {
	    append html "<input type=radio name=read_permission value=\"$role_name\">$role_to_display <br>\n"
	}
    }
    
    
    
    append html "
    </td>
    </tr><tr>
    <td valign=top align=right> Write Permissions:</td>
    <td>
    "
    
    set role_to_display_list [list]
    foreach role $role_list {
	set role_name [lindex $role 0]
	lappend role_to_display_list [lindex $role 1]
	set role_to_display [join $role_to_display_list ", "]
	
	if {[string compare [string tolower $default_write] [string tolower $role_name]] == 0} {
	    append html "<input type=radio name=write_permission value=\"$role_name\" checked>$role_to_display<br>\n"
	} else {
	    append html "<input type=radio name=write_permission value=\"$role_name\">$role_to_display<br>\n"
	}
    }
    
    return "
    $html</td></tr>
    [export_form_vars parent_id version_id]"
}
    
    




proc_doc edu_phone_number_p { number_to_check } "This makes sure that the number passed in has only numbers, -, (, and ).  It returns 1 if the number is valid, 0 otherwise." {
    return [regexp {[0-9\-\(\)]} $number_to_check]
}




proc_doc edu_department_select { db {default_dept_id ""} {select_name department_id} { include_null_entry_p t} } "This returns a string that is a select box listing all of the departments." {
    
    set selection [ns_db select $db "select department_name, department_id from edu_departments order by department_name, department_number"]
    
    set html "<select name=\"$select_name\">"

    if {[string compare $include_null_entry_p t]} {
	append html "<option value=\"\"> ---"
    }

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	if {[string compare $department_id $default_dept_id] == 0} {
	    append html "<option value=$department_id selected>$department_name \n"
	} else {
	    append html "<option value=$department_id>$department_name \n"
	}
    }

    append html "</select>"
    
    return $html
    
}


proc_doc edu_textarea { name { default ""} {cols 60} {rows 10}} "outputs a standard textarea of cols=60 rows=10 for varchar(4000)." {
    return "<textarea cols=$cols rows=$rows wrap name=$name>$default</textarea>"
}


proc_doc edu_maybe_display_text { text_to_display } "Takes in text and returns the text if it is not the empty string.  It is is the empty string, it returns the word 'None'" {
    if {[empty_string_p $text_to_display]} {
	return "None"
    } else {
	return $text_to_display
    }
}

proc_doc edu_get_two_db_handles {} "Sets db and db_sub in the calling environment." {
    return [ns_db gethandle [philg_server_default_pool] 2]
}
    
proc_doc edu_theme_color {} "returns the color used by the calendar and the portal system." {
    return "#aa3333"
}




# there is a handful of pages that share identical functionality.  Instead
# of repeating that code, we are sharing it and using a proc to serve
# the virtual URLs

ns_register_proc GET [edu_url]* edu_serve_util_pages
ns_register_proc POST [edu_url]* edu_serve_util_pages


proc_doc edu_serve_util_pages { } "This procedure determines if there is a file at the requested URL.  If there it, it serves that file.  If there is not, it naively looks for it in the /education/util directory" {

    set pageroot [ns_info pageroot]
    set url_list [ns_conn urlv]
    
    # page_name is the last element of the list
    set page_name [lindex $url_list [expr [llength $url_list] - 1]]
    set actual_url [ns_conn url]

    # if they are requesting a directory without the file, serve up 
    # index.tcl page
    if { [regexp {/$} $actual_url] } {
	set file_extension index.tcl
    } else {
	set file_extension ""
    }
    
    if {![regexp {html$} $actual_url] && ![regexp {tcl$} $actual_url] && ![regexp {adp$} $actual_url] && ![regexp {/$} $actual_url]} {
	ad_returnredirect "$actual_url/index.tcl"
	return
    }

    if {[file exists [ns_info pageroot][ns_conn url]$file_extension]} {
	source [ns_info pageroot][ns_conn url]$file_extension
	return
    } else {
	set extension [list "/education/util"]

	set count [expr [llength $url_list] - 2]
	while {$count >= 0} {
	    # lets see if this is a sub directory of anything (e.g. users)
	    set subdir [lindex $url_list $count]
	    if {[string compare $subdir admin] != 0 && [string compare $subdir department] != 0 && [string compare $subdir class] != 0 && [string compare $subdir subject] != 0} {
		lappend extension $subdir
	    } else {
		break
	    }
	    incr count -1
	}

	if {[file exists [ns_info pageroot][join $extension "/"]/$page_name]} {
	    source [ns_info pageroot][join $extension "/"]/$page_name
	    return
	} elseif {[file exists [ns_info pageroot]/education/util/$page_name]} {
	    source [ns_info pageroot]/education/util/$page_name
	    return
	} else {
	    ns_returnnotfound
	    return
	}   
    }
    
}


proc_doc edu_get_group_pretty_type_from_url {} "It does just that.  It looks at the URL and gets the group type.  Right now, it only recognizes 'class' and 'department' and it returns the first of the two that it encounters in the url." {
    set url_list [ns_conn urlv]
    foreach item $url_list {
	if {[string compare [string tolower $item] class] == 0 || [string compare [string tolower $item] department] == 0} {
	    return [string tolower $item]
	}
    }   
}




##################################################
#                                                #
#                                                #
#     BEGIN THE SECURITY PROCS                   #
#                                                #
#                                                #
##################################################



proc_doc edu_bboard_grant_access {db topic_id} "checks if a user is part of the group_id and has the role that is specified in the row containing the input topic_id in bboard_topics. returns 1 if the user has the correct role in the correct group; returns 0 otherwise" {
    set user_id [ad_verify_and_get_user_id $db]
    
    # assumes roles with lower priorities can take on roles with priorities
    # greater than or equal to its priority
    if {[database_to_tcl_string $db "
    select count(*) 
    from bboard_topics t, user_group_map ugm,
         edu_role_pretty_role_map user_role, 
         edu_role_pretty_role_map topic_role
    where ugm.user_id = $user_id
    and ugm.group_id=t.group_id
    and t.topic_id=$topic_id
    and ugm.role = user_role.role
    and topic_role.role=t.role(+)
    and user_role.priority<=topic_role.priority"]>0} {
	     return 1
	 } else {
	     return 0
	 }
}

proc_doc edu_display_not_authorized_message { } "This displays a generic not authorized message for all of the security functions." {
    set signatory [ad_system_owner]
    ReturnHeaders 
    ns_write "
    [ad_header "Authorization Failed"]
    <h3>Authorization Failed</h3>
    in <a href=/>[ad_system_name]</a>
    <hr>
    <p>You are not authorized to use this section of [ad_system_name].  Please contact <a href=\"mailto:$signatory\"><i>$signatory</i></a> if you have any questions.
    </p>
    [ad_footer]
    "
}

proc_doc edu_user_security_check {db} "determines if the user's requested page should be displayed -- under /education/class. this is different from admin page security. Returns {user_id group_id group_name}" {
    set user_id [ad_verify_and_get_user_id]
    
    if { [string compare $user_id "0"] == 0 } {
	ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return 0
    }

    set class_id [ad_get_client_property education edu_class]

    # we want to get the group name and make sure that the id was the correct type
    set group_name [database_to_tcl_string_or_null $db "select group_name from user_groups where group_id = '$class_id' and group_type = 'edu_class'"]
    
    if {[empty_string_p $class_id] || [empty_string_p $group_name]} {
	ad_returnredirect "/education/util/group-select.tcl?group_type=edu_class&return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	# blow out of 2 levels
	return -code return
    } else {
	# check if the class is public, if so just display the page
	# otherwise check if the user is a member of the class with
	# role != dropped
	if {[database_to_tcl_string $db "select public_p from edu_class_info where group_id=$class_id"]=="t"} {
	    return [list $user_id $class_id "$group_name"]
	} elseif {[database_to_tcl_string $db "select count(*) from user_group_map where user_id=$user_id and group_id=$class_id and role!='dropped'"]>0} {
		return [list $user_id $class_id "$group_name"]
	} else {
	    edu_display_not_authorized_message
	    # blow out of 2 levels
	    return -code return
	} 
    }
}


proc_doc edu_group_security_check { db group_type {action ""}} "This returns a list containing, in order, the user_id, the group_id, and the group_name.  Group type should be something like edu_class or edu_department.  This checks to see if the user is logged in as a member of any groups of the given group type.  
<p>
If the user is logged in under the correct group type, it returns the above mentioned list.  If the user is not logged in as a member of a group of the correct type then the user is automatically redirected to group_select.tcl.
<p>
If the user is logged in under the correct group_type then this checks to make sure that the user has permission to perform the passed in action.  If the user does not have the correct permission, this calls edu_display_not_authorized_message and then forces the calling environment to return." { 

    set user_id [ad_verify_and_get_user_id]

    if { [string compare $user_id "0"] == 0 } {
	ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return -code return
    }

    set group_id [ad_get_client_property education $group_type]

    if {![empty_string_p $group_id]} {
	# we want to get the group name and make sure that the id was the correct type
	set group_name [database_to_tcl_string_or_null $db "select group_name from user_groups where group_id = $group_id and group_type = '$group_type'"]
    }


    if {[empty_string_p $group_id] || [empty_string_p $group_name]} {
	ad_returnredirect "/education/util/group-select.tcl?group_type=$group_type&return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	# blow out of 2 levels
	return -code return
    } else {
	# we want to put the action back in eventually
	if {![ad_permission_p $db "" "" $action $user_id $group_id] } {
	    edu_display_not_authorized_message
	    # blow out of 2 levels
	    return -code return
	} else {
	    return [list $user_id $group_id "$group_name"]
	}
    }
}




proc_doc edu_subject_admin_security_check { db subject_id } "This returns the user_id.  It determines if the user is allowed to see the subject admin pages by seeing if they have admin in a department that has the subject.
<p>
If the user is not logged in they are redirected to the log in page.
<p>
If the user is not logged in as a member of a group, they are redirected to group-select.tcl and asked to select a group.
<p>
If they are logged in as a group, the security check is performed.  If the user passes, the user_id is returned to the calling environment.  If the user fails the security check, a standard UNAUTHORIZED message is displayed and the procedure forces the calling environment to return. " {

    # this should be altered if departments go to a multi-roled system 
    # (e.g. prof, staff, students)

    set user_id [ad_verify_and_get_user_id $db]

    if { [string compare $user_id "0"] == 0 } {
	ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return -code return
    }

    if {[ad_administrator_p $db $user_id]} {
	return $user_id
    } 

    # the user is not a site wide admin
    
    set department_id [ad_get_client_property education edu_department]

    if {[empty_string_p $department_id]} {
	ad_returnredirect "/education/util/group-select.tcl?type=edu_department&return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	# blow out of 2 levels
	return -code return
    } else {
	# now, we see if the user is an admin for a department that offers this
	# subject.  If not, we bounce them to group_select or display an error
	# depending on which is appropriate.

	set valid_p [database_to_tcl_string $db "select count(map.subject_id) 
                 from edu_subjects, 
                      edu_subject_department_map map,
                      user_group_map ugmap
                where edu_subjects.subject_id = map.subject_id
                  and map.subject_id = $subject_id
                  and ugmap.user_id = $user_id
                  and ugmap.group_id = map.department_id"] 

	if { $valid_p == 0 } {
	    edu_display_not_authorized_message
	    # blow out of 2 levels
	    return -code return
	} else {
	    return $user_id
	}
    }
}
	
util_report_successful_library_load
