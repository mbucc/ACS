# /www/admin/users/basic-info-update-2.tcl
#

ad_page_contract {
    @param user_id
    @param first_names
    @param last_names
    @param email
    @param url
    @param screen_name
    @author ?
    @creation-date ?
    @cvs-id basic-info-update-2.tcl,v 3.2.2.4.2.6 2000/09/12 20:11:22 cnk Exp
} {
    user_id:integer,notnull
    first_names:notnull
    last_name:notnull
    email:notnull
    { url "" }
    { screen_name "" }
}



set exception_text ""
set exception_count 0

if { ![info exists first_names] || $first_names == "" } {
    append exception_text "<li>You need to type in a first name\n"
    incr exception_count
}

if { ![info exists last_name] || $last_name == "" } {
    append exception_text "<li>You need to type in a last name\n"
    incr exception_count
}

if { ![info exists email] || $email == "" } {
    append exception_text "<li>You need to type in an email address\n"
    incr exception_count
}

if { [db_string check_email_in_use "select count(user_id) from users where upper(email) = upper(:email) and user_id <> :user_id"] > 0 } {
    append exception_text "<li>the email $email is already in the database\n"
    incr exception_count
}

if {![empty_string_p $screen_name]} {
    # screen name was specified.
    set sn_unique_p [db_string check_screen_name_in_use "
    select count(*) from users where screen_name = :screen_name and user_id != :user_id"]
    if {$sn_unique_p != 0} {
	append exception_text "<li>The screen name you have selected is already taken.\n"
	incr exception_count
    }
}

if { $exception_count > 0 } {
    db_release_unused_handles
    ad_return_complaint $exception_count $exception_text
    return
}

if {[empty_string_p $screen_name]} {
    set sql "update users
    set first_names = :first_names,
    last_name = :last_name,
    email = :email,
    url = :url,
    screen_name = null
    where user_id = :user_id"
} else {
    set sql "update users
    set first_names = :first_names,
    last_name = :last_name,
    email = :email,
    url = :url,
    screen_name = :screen_name
    where user_id = :user_id"
}

if [catch { db_dml set_user_info $sql } errmsg] {
    db_release_unused_handles
    ad_return_error "Ouch!"  "The database choked on our update:
<blockquote>
$errmsg
</blockquote>
"
} else {
    db_release_unused_handles
    ad_returnredirect "one.tcl?user_id=$user_id"
}





