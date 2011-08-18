# $Id: procedure-delete.tcl,v 3.0.4.1 2000/04/28 15:10:47 carsten Exp $
# procedure-delete.tcl -- confirm the removal of a software procedure from glassroom_procedures




set_the_usual_form_variables

# Expects procedure_id


if { [ad_read_only_p] } {
    ad_return_read_only_maintenance_message
    return
}


# check for user

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}




#make sure the procedure is still there

set db [ns_db gethandle]

set select_sql "
select procedure_name
  from glassroom_procedures
 where procedure_name='$QQprocedure_name'"

set procedure_name [database_to_tcl_string_or_null $db $select_sql]

ns_db releasehandle $db

# if there's nothing there, it might have been deleted already
if { [empty_string_p $procedure_name] } {
    ad_returnredirect index.tcl
}


#emit the page contents

ReturnHeaders

ns_write "[ad_header "Delete \"$procedure_name\""]

<h2>Delete \"$procedure_name\"</h2>
in [ad_context_bar [list index.tcl Glassroom] [list procedure-view.tcl?[export_url_vars procedure_name] "View Procedure"] "Delete Procedure"]
<hr>

Are you sure you want to delete this procedure?

<ul>
   <li> <a href=\"procedure-delete-2.tcl?[export_url_vars procedure_name]\">yes, I'm sure</a>
        <br><br>

   <li> <a href=\"procedure-view.tcl?[export_url_vars procedure_name]\">no, let me look at the procedure info again</a>
</ul>

[glassroom_footer]
"





