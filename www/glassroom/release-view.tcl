# $Id: release-view.tcl,v 3.0.4.1 2000/04/28 15:10:53 carsten Exp $
# release-view.tcl -- view a software release's information

set_form_variables

# Expects release_id


# check for user

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}



set db [ns_db gethandle]

set select_sql "
select glassroom_releases.module_id, release_name, manager, module_name, release_date, anticipated_release_date
  from glassroom_releases, glassroom_modules
 where glassroom_releases.module_id = glassroom_modules.module_id and release_id = $release_id"

set selection [ns_db 0or1row $db $select_sql]

if { [empty_string_p $selection] } {

    # if it's not there, just redirect them to the index page
    # (if they hacked the URL, they get what they deserve, if the
    # the module has been deleted, they can see the list of valid modules)
    ad_returnredirect index.tcl
    return
}

set_variables_after_query

if { [info exists manager] && ![empty_string_p $manager] } {
    set manager [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$manager"]
} else {
    set manager "Nobody"
}

if [empty_string_p $release_date] {
    set release_date "not released"
}


# emit the page contents

ReturnHeaders

ns_write "[ad_header "$release_name"]

<h2>$release_name</h2>
in [ad_context_bar [list index.tcl Glassroom] "View Release"]
<hr>


<h3>The Release</h3>

<ul>

  <li> <b>Release Name</b>: $release_name
       <p>

  <li> <b>Software Module</b>: $module_name
       <p>

  <li> <b>Manager</b>: $manager
       <p>

  <li> <b>Anticipated Release Date</b>: [util_AnsiDatetoPrettyDate $anticipated_release_date]
       <p>

  <li> <b>Release Date</b>: [util_AnsiDatetoPrettyDate $release_date]
       <p>

</ul>

"



ns_write "

<h3>Actions</h3>

<ul>
   <li> <a href=\"release-edit.adp?[export_url_vars release_id]\">Edit</a>
        <p>

   <li> <a href=\"release-delete.tcl?[export_url_vars release_id]\">Delete</a>

</ul>

[glassroom_footer]
"
