# /www/register/legacy-user-2.tcl
ad_page_contract {
    @author Unknown
    @creation-date Unknown
    @cvs-id legacy-user-2.tcl,v 3.4.2.2 2000/11/03 00:00:19 kevin Exp
} {
    user_id:integer,notnull
    password1:notnull
    password2:notnull
    {return_url ""}
} -validate {
    passwords_identical_p -requires {password1 password2} {
	ad_complain "The passwords you typed didn't match.  Please type the same password in both boxes."
    }
} -errors {
    password1 {You must enter your password in both boxes}
    password2 {You must enter your password in both boxes}
}


# for security, we are only willing to update rows where converted_p = 't'
# this keeps people from hijacking accounts

db_dml update_legacy_user "
update users 
set    password = :password1,
       converted_p = 'f'
where  user_id = :user_id
and    converted_p = 't'"

if [empty_string_p $return_url] {
    set return_url [ad_pvt_home]
}

ad_user_login $user_id
ad_returnredirect $return_url

