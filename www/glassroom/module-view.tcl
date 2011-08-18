# $Id: module-view.tcl,v 3.0.4.1 2000/04/28 15:10:45 carsten Exp $
# module-view.tcl -- view a software module's information, and also give users
#                    the option to edit or delete the information

set_form_variables

# Expects module_id


# check for user

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}


set db [ns_db gethandle]

set select_sql "
select module_name, source, current_version, who_installed_it, who_owns_it
  from glassroom_modules
 where module_id = $module_id"

set selection [ns_db 0or1row $db $select_sql]

if { [empty_string_p $selection] } {
    # if it's not there, just redirect them to the index page
    # (if they hacked the URL, they get what they deserve, if the
    # the module has been deleted, they can see the list of valid modules)
    ad_returnredirect index.tcl
    return
}

set_variables_after_query

if { [info exists who_installed_it] && ![empty_string_p $who_installed_it] } {
    set who_installed_it [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$who_installed_it"]
} else {
    set who_installed_it "Nobody"
}

if { [info exists who_owns_it] && ![empty_string_p $who_owns_it] } {
    set who_owns_it [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$who_owns_it"]
} else {
    set who_owns_it "Nobody"
}



# emit the page contents

ReturnHeaders

ns_write "[ad_header "$module_name $current_version"]

<h2>$module_name $current_version</h2>
in [ad_context_bar [list index.tcl Glassroom] "View Module"]
<hr>

<h3>The Module</h3>

<ul>
    <li> <b>Module Name:</b> $module_name
         <p>

    <li> <b>Who Installed It:</b> $who_installed_it
         <p>

    <li> <b>Who Owns It:</b> $who_owns_it
         <p>

    <li> <b>Source:</b> $source
         <p>

    <li> <b>Current Version:</b> $current_version
         <p>


</ul>"


ns_write "

<h3>Actions</h3>

<ul>
   <li> <a href=\"module-edit.adp?[export_url_vars module_id]\">Edit</a>
        <p>

   <li> <a href=\"module-delete.tcl?[export_url_vars module_id]\">Delete</a>

</ul>

[glassroom_footer]
"




