# add-2.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id add-2.tcl,v 3.2.2.8 2000/09/22 01:34:55 kevin Exp
} {
    variables:optional
    title:trim,notnull
    subject:notnull
    message:notnull
    when_sent
    issue_type:multiple
}
# 

# 

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ad_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# check the entered ADP for functions
if {[fm_adp_function_p $message]} {
    doc_return  200 text/html "
    <P><tt>We're sorry, but message templates added here cannot
    have functions in them for security reasons. Only HTML and 
    <%= \$variable %> style code may be used.</tt>"
}




#regsub -all "\r" $QQmessage "" newQQmessage

if { [catch {db_dml unused "insert into ec_email_templates
(email_template_id, title, subject, message, variables, when_sent, issue_type_list, last_modified, last_modifying_user, modified_ip_address)
values
(ec_email_template_id_sequence.nextval, :title, :subject, :message, :variables, :when_sent, :issue_type, sysdate, :user_id, '[DoubleApos [ns_conn peeraddr]]')"} errMsg] } {
    ad_return_complaint 1 "Failed to add the email template, Suspect double click/ template already created"
}

db_release_unused_handles

ad_returnredirect "index.tcl"


