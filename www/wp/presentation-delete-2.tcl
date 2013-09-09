# /wp/presentation-delete-2.tcl
ad_page_contract {
    Deletes a presentation.
    @cvs-id presentation-delete-2.tcl,v 3.0.12.13 2000/09/22 01:39:32 kevin Exp
    @creation-date  28 Nov 1999
    @author  Jon Salz <jsalz@mit.edu>
    @param presentation_id is the id of the presentation to delete
    @param password is the password typed by the deleting user
} {
    presentation_id:naturalnum,notnull
    password:trim,notnull
} -errors {
    password:notnull "Please type in a password."
} 
# modified by jwong@arsdigita.com on 10 Jul 2000 for ACS 3.4 upgrade

set user_id [ad_maybe_redirect_for_registration]
if { $password != [db_string password_select "select password from users where user_id = :user_id"] } {
    db_release_unused_handles
    ad_return_complaint 1 "<li>The password you entered is incorrect.\n"
    return
}

wp_check_authorization $presentation_id $user_id "admin"

db_transaction {
db_dml pres_delete "delete from wp_presentations where presentation_id = :presentation_id"
db_dml group_delete "delete from user_groups where group_type = 'wp' and group_name = :presentation_id" 

} on_error {
    ad_return_error "Error" "Error occurred deleting presentation $presentation_id from the database."
}


db_release_unused_handles

set page_output "[wp_header_form "name=f" \
           [list "" "WimpyPoint"] [list "index?show_user=" "Your Presentations"] "Presentation Deleted"]

The presentation has been deleted.

<p><a href=\"\">Return to your presentations</a>
</p>

[wp_footer]
"

doc_return  200 "text/html" $page_output
