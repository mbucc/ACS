# /www/register/email-confirm.tcl

ad_page_contract {
    @cvs-id email-confirm.tcl,v 3.3.2.8 2000/10/16 19:51:24 kevin Exp

} {
    row_id:notnull,trim
}

# remove whitespace from rowid
# regsub -all "\[ \t\n]+" $rowid {} rowid

# we take authorized here in case the
# person responds more than once

set sql "select user_state, email, user_id 
         from users 
         where rowid = :row_id
         and (user_state in ('need_email_verification_and_admin_approv',
                             'need_email_verification','need_admin_approv',
                             'authorized'))"

# we want to catch DB errors related to illegal rowids.
# but, we also have to make sure to get the rturn value from db_0or1row too.
set status [catch {set rowid_check [db_0or1row register_email_user_info_get $sql]}]

if { $status != 0 || $rowid_check == 0} {
    db_release_unused_handles
    ad_return_error "Couldn't find your record" "Row id $row_id is not in the database.  Please check your email and verifiy that you have cut and pasted the url correctly."
    return
}
    

if {$user_state == "need_email_verification" || $user_state == "authorized"} {
    db_dml register_email_user_update "update users 
                        set email_verified_date = sysdate, 
                            user_state          = 'authorized' 
                        where user_id = :user_id" 

    set whole_page "[ad_header "Email confirmation success"]

    <h2>Your email is confirmed</h2>
    at [ad_site_home_link]
    <hr>
    Your email has been confirmed. You may now log into
    [ad_system_name].
    <p>
    <form action=\"user-login\" method=post>
    [export_form_vars email]
    <input type=submit value=\"Continue\">
    </form>
    <p>
    Note: If you've forgotten your password, <a
    href=\"email-password.tcl?user_id=$user_id\">ask this server to email it
    to $email</a>.
    [ad_footer]
    "

} else {

    #state is need_email_verification_and_admin_approv or rejected
    if { $user_state == "rejected" } {
	db_dml register_email_confirm_update2 "update users 
                        set email_verified_date = sysdate 
                        where user_id = :user_id" 
    } elseif { $user_state == "need_email_verification_and_admin_approv" } {
	db_dml register_email_confirm_update3 "update users 
                        set email_verified_date = sysdate, 
                            user_state          = 'need_admin_approv' 
                        where user_id = :user_id" 
    }

    set whole_page "[ad_header "Email confirmation success"]
    <h2>Your email is confirmed</h2>
    at [ad_site_home_link]
    <hr>
    Your email has been confirmed. You are now awaiting approval
    from the [ad_system_name] administrator.    
    [ad_footer]"

}

doc_return  200 text/html $whole_page
