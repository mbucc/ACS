# $Id: basic-info-update-2.tcl,v 3.0.4.1 2000/04/28 15:09:36 carsten Exp $
set_the_usual_form_variables

# user_id, first_names, last_name, email, url, screen_name

set db [ns_db gethandle]

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


if { [database_to_tcl_string $db "select count(user_id) from users where upper(email) = '[string toupper $QQemail]' and user_id <> $user_id"] > 0 } {
    append exception_text "<li>the email $email is already in the database\n"
    incr exception_count
}


if {![empty_string_p $screen_name]} {
    # screen name was specified.
    set sn_unique_p [database_to_tcl_string $db "
    select count(*) from users where screen_name='$screen_name' and user_id != $user_id"]
    if {$sn_unique_p != 0} {
	append exception_text "<li>The screen name you have selected is already taken.\n"
	incr exception_count
    }
}


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}



if {[empty_string_p $screen_name]} {
    set sql "update users
    set first_names = '$QQfirst_names',
    last_name = '$QQlast_name',
    email = '$QQemail',
    url = '$QQurl',
    screen_name=null
    where user_id = $user_id"
} else {
    set sql "update users
    set first_names = '$QQfirst_names',
    last_name = '$QQlast_name',
    email = '$QQemail',
    url = '$QQurl',
    screen_name='$screen_name'
    where user_id = $user_id"
}

if [catch { ns_db dml $db $sql } errmsg] {
    ad_return_error "Ouch!"  "The database choked on our update:
<blockquote>
$errmsg
</blockquote>
"
} else {
    ad_returnredirect "one.tcl?user_id=$user_id"
}

