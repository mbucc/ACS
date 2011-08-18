<%
# logbook-add-2.adp -- add a new entry to the the glassroom_logbook table
#                      (this is an ADP as opposed to a .tcl file so that 
#                      it's consistent naming with logbook-add.adp)


set_the_usual_form_variables

# Expects procedure_name_select, procedure_name_text, notes


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

# check for user

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}




# no real argument checking to be done.
# procedure_name_text takes precedence over procedure_name_select

set procedure_name ""

if { [info exists procedure_name_select] && ![empty_string_p $procedure_name_select] } {
    set procedure_name $procedure_name_select
}

if { [info exists procedure_name_text] && ![empty_string_p $procedure_name_text] } {
    set procedure_name $procedure_name_text
}





# Assuming we don't need to confirm entry.  Just add it to the
# glassroom_certs table

set insert_sql "
    insert into glassroom_logbook
      (entry_id, entry_time, entry_author, procedure_name, notes)
    values
      (glassroom_logbook_entry_id_seq.nextval, sysdate, $user_id,
       '[DoubleApos $procedure_name]', '$QQnotes')
    "
    
set db [ns_db gethandle]
ns_db dml $db "$insert_sql"
ns_db releasehandle $db


# and redirect back to index.tcl so folks can see the new entry list

ad_returnredirect "index.tcl"

%>

