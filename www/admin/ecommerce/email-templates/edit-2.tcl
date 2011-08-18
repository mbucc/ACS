# $Id: edit-2.tcl,v 3.0.4.1 2000/04/28 15:08:42 carsten Exp $
set_the_usual_form_variables
# email_template_id, variables, title, subject, message, when_sent, issue_type (select multiple)

set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set form [ns_getform]
set form_size [ns_set size $form]
set form_counter 0
set issue_type_list [list]
while { $form_counter < $form_size} {
    set form_key [ns_set key $form $form_counter]
    if { $form_key == "issue_type" } {
	set form_value [ns_set value $form $form_counter]
	if { ![empty_string_p $form_value] } {
	    lappend ${form_key}_list $form_value
	}
    }
    incr form_counter
}

set db [ns_db gethandle]

regsub -all "\r" $QQmessage "" newQQmessage

ns_db dml $db "update ec_email_templates
set title='$QQtitle', subject='$QQsubject', message='$QQmessage', variables='$QQvariables', when_sent='$QQwhen_sent', issue_type_list='[DoubleApos $issue_type_list]', last_modified=sysdate, last_modifying_user='$user_id', modified_ip_address='[DoubleApos [ns_conn peeraddr]]'
where email_template_id=$email_template_id"

ad_returnredirect "index.tcl"
