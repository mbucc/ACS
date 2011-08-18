# $Id: add-3.tcl,v 3.0.4.1 2000/04/28 15:08:57 carsten Exp $
set_the_usual_form_variables
# template_id, template_name, template

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_url_vars template_id template_name template]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set exception_count 0
set exception_text ""

if { ![info exists template_name] || [empty_string_p $template_name] } {
    incr exception_count
    append exception_text "<li>You forgot to enter a template name.\n"
}

if { ![info exists template] || [empty_string_p $template] } {
    incr exception_count
    append exception_text "<li>You forgot to enter anything into the ADP template box.\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set db [ns_db gethandle]

# see if the template's already in there, which means they pushed reload
if { [database_to_tcl_string $db "select count(*) from ec_templates where template_id=$template_id"] > 0 } {
    ad_returnredirect index.tcl
    return
}

ns_db dml $db "insert into ec_templates
(template_id, template_name, template, last_modified, last_modifying_user, modified_ip_address)
values
($template_id, '$QQtemplate_name', '$QQtemplate', sysdate, $user_id, '[DoubleApos [ns_conn peeraddr]]')"

ad_returnredirect index.tcl
