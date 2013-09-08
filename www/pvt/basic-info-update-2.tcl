# /www/pvt/basic-info-update-2.tcl

ad_page_contract {
    Update the user personal information according to his submission.

    @param first_names The user's first names.
    @param last_names The user's last name.
    @param email The user's email.
    @param url The URL of the user's website.
    @param screen_name The user's screen name, a unique identifier.
    @param bio The user's bio.

    @param return_url An optional url to redirect the user to, once the task is completed.

    @author Multiple
    @cvs-id basic-info-update-2.tcl,v 3.6.2.4 2000/08/22 00:51:18 mbryzek Exp

} {
    first_names:notnull
    last_name:notnull
    email:notnull
    url
    screen_name
    bio:html
    return_url:optional
}

set user_id [ad_maybe_redirect_for_registration]

set exception_text ""
set exception_count 0

if {[info exists first_names] && [string first "<" $first_names] != -1} {
    incr exception_count
    append exception_text "<li> You can't have a &lt; in your first name because it will look like an HTML tag and confuse other users."
}

if {[info exists last_name] && [string first "<" $last_name] != -1} {
    incr exception_count
    append exception_text "<li> You can't have a &lt; in your last name because it will look like an HTML tag and confuse other users."
}

if { ![philg_email_valid_p $email] } {
    incr exception_count
    append exception_text "<li>The email address that you typed doesn't look right to us.  Examples of valid email addresses are 
<ul>
<li>Alice1234@aol.com
<li>joe_smith@hp.com
<li>pierre@inria.fr
</ul>"
}

if { ![empty_string_p $url] && ![philg_url_valid_p $url] } {
    incr exception_count
    append exception_text "<li>Your URL doesn't really look like a URL."
}

if {![empty_string_p $screen_name]} {
    # screen name was specified.
    set sn_unique_p [db_string sn_unique_p {
	select count(*) 
	from users 
	where screen_name=:screen_name and user_id != :user_id
    }] 

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

set email_in_use_p [db_string email_in_use_p {
    select count(user_id) 
    from users 
    where upper(email) = upper (:email) 
    and user_id <> :user_id 
}] 

if { $email_in_use_p > 0 } {
    ad_return_error "$email already in database" "The email address \"$email\" is already in the database.  If this is your email address, perhaps you're trying to combine two accounts?  If so, please email <a href=\"mailto:[ad_system_owner]\">[ad_system_owner]</a> with your request."
    return
}

if { [empty_string_p $screen_name] } {
    set screen_name [db_null]
} 


if [catch { db_dml user_info_update {
    update users
    set first_names = :first_names,
    last_name = :last_name,
    email = :email,
    url = :url,
    screen_name=:screen_name,
    bio=:bio
    where user_id = :user_id
}} errmsg] {
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

