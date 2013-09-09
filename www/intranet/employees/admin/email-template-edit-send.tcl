# /www/intranet/employees/admin/email-template-edit-send.tcl

ad_page_contract {

    Send an edited email template to a user from another user.

    @author jbank@arsdigita.com
    @creation-date Tue Jun 20 10:21:42 2000
    @cvs-id email-template-edit-send.tcl,v 3.1.2.5 2000/08/16 21:24:48 mbryzek Exp
    @param return_url The bounce-back url.
    @param html_p  Is this in html
    @param user_id The user 
    @param email_to The email to address
    @param email_from  The email from address
    @param email_subject  The subject for the email
    @param email_body The body of the email
} {
    return_url 
    html_p 
    user_id 
    email_to 
    email_from 
    email_subject 
    email_body
}



set from_user_id [ad_maybe_redirect_for_registration]


set extra_headers [email_extra_headers $html_p]
ns_set put $extra_headers "Reply-To" "$email_from, recruiting-$user_id@intranet.arsdigita.com"

set email_obj [email_object_create $email_to $email_from $email_subject $email_body $extra_headers]
ad_email_object_send $email_obj
        
set comment_id [db_string getcommentid "select general_comment_id_sequence.nextval from dual"]
ad_general_comment_add $comment_id "im_employee_pipeline" $user_id "Email: $email_subject" \
        [email_object_pretty_print $email_obj $html_p] $from_user_id [ns_conn peeraddr] "t" "t" "Email: $email_subject"

ad_returnredirect $return_url        


