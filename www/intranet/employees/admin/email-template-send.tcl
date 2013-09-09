# /www/intranet/employees/admin/email-template-send.tcl
#
# 
#
# jbank@arsdigita.com, Tue Jun 20 10:21:42 2000
#
# email-template-send.tcl,v 3.1.2.5 2000/09/22 01:38:33 kevin Exp
# /www/intranet/employees/admin/email-template-send.tcl

ad_page_contract {
    Send an email template to a user from another user.

    @author jbank@arsdigita.com
    @creation-date Tue Jun 20 10:21:42 2000
    @cvs-id email-template-send.tcl,v 3.1.2.5 2000/09/22 01:38:33 kevin Exp
    @param return_url The url we return to
    @param email_template_id the template_id
    @param user_id The user_id
    @param preview_p Preview it?
} {
    return_url 
    email_template_id 
    user_id 
    { preview_p "f" }
}



set from_user_id [ad_maybe_redirect_for_registration]




set from_bindings [user_id_to_from_bindings $from_user_id]
set to_bindings [user_id_to_to_bindings $user_id]

db_1row getemailinfo "select from_email, from_name, subject, template, html_p from job_listing_email_templates where email_template_id = :email_template_id"]


set extra_headers [email_extra_headers $html_p]
ns_set put $extra_headers "Reply-To" "[util_template_replace "<from_email>" $from_bindings], recruiting-$user_id@intranet.arsdigita.com"
set email_template [email_object_create \
        "\"<to_name>\" <<to_email>>" \
        [util_decode $from_name "" "$from_email" "\"$from_name\" <${from_email}>"] \
        $subject \
        $template \
        $extra_headers]

set email_obj [ad_email_object_substitute $email_template \
        [binding_list_combine $from_bindings $to_bindings]]

if { $preview_p == "t" } {
    
    doc_return  200 text/html "[ad_public_header]

    [email_object_edit_form $email_obj email-template-edit-send \
            [export_form_vars return_url html_p user_id] "Send Edited" $html_p]

    [ad_public_footer]"
    return
}

ad_email_object_send $email_obj
        
set comment_id [db_string getcomment_id "select general_comment_id_sequence.nextval from dual"]
ad_general_comment_add $comment_id "im_employee_pipeline" $user_id "Email: $subject" \
        [email_object_pretty_print $email_obj $html_p] $from_user_id [ns_conn peeraddr] "t" "t" "Email: $subject"

ad_returnredirect $return_url        


