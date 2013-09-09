#  www/admin/ecommerce/templates/add-3.tcl
ad_page_contract {

    @param template_id the ID of the template
    @param template_name the name of the template
    @param template 

  @author
  @creation-date
  @cvs-id add-3.tcl,v 3.1.6.7 2001/01/12 19:32:05 khy Exp
} {

    template_id:naturalnum,notnull,verify
    template_name
    template:allhtml
}



# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ad_conn url]?[export_url_vars template_id template_name template]"

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



# see if the template's already in there, which means they pushed reload
if { [db_string get_dclick_temp "select count(*) from ec_templates where template_id=:template_id"] > 0 } {
    ad_returnredirect index.tcl
    return
}

db_dml insert_new_template "insert into ec_templates
(template_id, template_name, template, last_modified, last_modifying_user, modified_ip_address)
values
(:template_id, :template_name, :template, sysdate, :user_id, '[DoubleApos [ns_conn peeraddr]]')"
db_release_unused_handles

ad_returnredirect index.tcl
