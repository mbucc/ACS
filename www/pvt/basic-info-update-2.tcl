# $Id: basic-info-update-2.tcl,v 3.3.2.1 2000/04/28 15:11:23 carsten Exp $
set_the_usual_form_variables

# first_names, last_name, email, url, screen_name, bio
# return_url (optional)

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect /register/
    return
}

set db [ns_db gethandle]

set exception_text ""
set exception_count 0

if { ![info exists first_names] || [empty_string_p $first_names] } {
    append exception_text "<li>You need to type in a first name\n"
    incr exception_count
}


if { ![info exists last_name] || [empty_string_p $last_name] } {
    append exception_text "<li>You need to type in a last name\n"
    incr exception_count
}


if {[info exists first_names] && [string first "<" $first_names] != -1} {
    incr exception_count
    append exception_text "<li> You can't have a &lt; in your first name because it will look like an HTML tag and confuse other users."
}

if {[info exists last_name] && [string first "<" $last_name] != -1} {
    incr exception_count
    append exception_text "<li> You can't have a &lt; in your last name because it will look like an HTML tag and confuse other users."
}

if { ![info exists email] || [empty_string_p $email] } {
    append exception_text "<li>You need to type in an email address\n"
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

if { ![info exists bio] } {
    set bio "" 
} elseif { [string length $bio] >= 4000 } {
    append exception_text "<li> Your biography is too long. Please limit it to 4000 characters"
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

if { [database_to_tcl_string $db "select count(user_id) from users where upper(email) = '[string toupper $QQemail]' and user_id <> $user_id"] > 0 } {
    ad_return_error "$email already in database" "The email address \"$email\" is already in the database.  If this is your email address, perhaps you're trying to combine two accounts?  If so, please email <a href=\"mailto:[ad_system_owner]\">[ad_system_owner]</a> with your request."
    return
}

if { [empty_string_p $screen_name] } {
    set screen_name_sql null
} else {
    set screen_name_sql "'$screen_name'"
}

    set sql "update users
    set first_names = '$QQfirst_names',
    last_name = '$QQlast_name',
    email = '$QQemail',
    url = '$QQurl',
    screen_name=$screen_name_sql,
    bio='$QQbio'
    where user_id = $user_id"

if [catch { ns_db dml $db $sql } errmsg] {
    ad_return_error "Ouch!"  "The database choked on our update:
<blockquote>
$errmsg
</blockquote>
"
} else {
    if { [exists_and_not_null return_url] } {
	ad_returnredirect $return_url
    } else {
	ad_returnredirect home.tcl
    }
}

