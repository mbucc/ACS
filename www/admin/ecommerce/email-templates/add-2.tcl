# $Id: add-2.tcl,v 3.0.4.1 2000/04/28 15:08:41 carsten Exp $
set_the_usual_form_variables
# variables, title, subject, message, when_sent, issue_type (select multiple)

# we need them to be logged in
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

ns_db dml $db "insert into ec_email_templates
(email_template_id, title, subject, message, variables, when_sent, issue_type_list, last_modified, last_modifying_user, modified_ip_address)
values
(ec_email_template_id_sequence.nextval, '$QQtitle', '$QQsubject', '$QQmessage', '$QQvariables', '$QQwhen_sent', '[DoubleApos $issue_type_list]', sysdate, '$user_id', '[DoubleApos [ns_conn peeraddr]]')"

ad_returnredirect "index.tcl"
