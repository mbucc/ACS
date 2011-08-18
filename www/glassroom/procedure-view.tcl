# $Id: procedure-view.tcl,v 3.0.4.1 2000/04/28 15:10:48 carsten Exp $
# procedure-view.tcl -- view a procedure's information

set_the_usual_form_variables

# epects procedure name


set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}



set db [ns_db gethandle]

set select_sql "
select procedure_description, responsible_user, responsible_user_group, max_time_interval, importance
  from glassroom_procedures
 where procedure_name='$QQprocedure_name'
 order by procedure_name"

set selection [ns_db 0or1row $db $select_sql]

if { [empty_string_p $selection] } {

    # if it's not there, just redirect them to the index page
    # (if they hacked the URL, they get what they deserve, if the
    # the module has been deleted, they can see the list of valid modules)
    ad_returnredirect index.tcl
    return
}

set_variables_after_query

if { [info exists responsible_user] && ![empty_string_p $responsible_user] } {
    set responsible_user [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$responsible_user"]
} else {
    set responsible_user "Nobody"
}

if { [info exists responsible_user_group] && ![empty_string_p $responsible_user_group] } {
    set responsible_user_group [database_to_tcl_string $db "select group_name from user_groups where group_id=$responsible_user_group"]
} else {
    set responsible_user_group "Nobody"
}

if { [info exists max_time_interval] && ![empty_string_p $max_time_interval] } {
    append max_time_interval " days"
} else {
    set max_time_interval "none"
}




# emit the page contents

ReturnHeaders

ns_write "[ad_header "$procedure_name"]

<h2>$procedure_name</h2>
in [ad_context_bar [list index.tcl Glassroom] "View Procedure"]
<hr>


<h3>The Procedure</h3>

<ul>

  <li> <b>Procedure Name</b>: $procedure_name
       <p>

  <li> <b>Procedure Description</b>: $procedure_description
       <p>

  <li> <b>Responsible User</b>: $responsible_user
       <p>

  <li> <b>Responsible Group</b>: $responsible_user_group
       <p>

  <li> <b>Max Time Interval</b>: $max_time_interval
       <p>

  <li> <b>Importance</b>: $importance (1 is least important, 10 is most important)
       <p>

</ul>
"



ns_write "

<h3>Actions</h3>

<ul>
   <li> <a href=\"procedure-edit.adp?[export_url_vars procedure_name]\">Edit</a>
        <p>

   <li> <a href=\"procedure-delete.tcl?[export_url_vars procedure_name]\">Delete</a>

</ul>

[glassroom_footer]
"
