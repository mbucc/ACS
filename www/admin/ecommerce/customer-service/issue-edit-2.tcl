# $Id: issue-edit-2.tcl,v 3.0.4.1 2000/04/28 15:08:39 carsten Exp $
set_the_usual_form_variables
# issue_id, issue_type (select multiple)

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

ns_db dml $db "begin transaction"

ns_db dml $db "delete from ec_cs_issue_type_map where issue_id=$issue_id"

foreach issue_type $issue_type_list {
    ns_db dml $db "insert into ec_cs_issue_type_map (issue_id, issue_type) values ($issue_id, '[DoubleApos $issue_type]')"
}

ns_db dml $db "end transaction"

ad_returnredirect "issue.tcl?[export_url_vars issue_id]"