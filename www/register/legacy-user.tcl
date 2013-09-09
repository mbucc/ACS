# /www/register/legacy-user.tcl
ad_page_contract {
    @author Unknown
    @creation-date Unknown
    @cvs-id legacy-user.tcl,v 3.2.2.4 2000/11/03 00:00:19 kevin Exp
} {
    user_id:integer,notnull
    {return_url ""}
}

 
if ![db_0or1row user_state "
select user_state from users where user_id = :user_id"] {
    ad_return_error "Couldn't find your record" "User id $user_id is not in the database.  This is probably our programming bug."
    return
}


if { $user_state == "banned" } {
    doc_return  200 text/html "[ad_header "Sorry"]

<h2>Sorry</h2>

<hr>

Sorry but it seems that you've been banned from [ad_system_name].

[ad_footer]
"
    return
}

# they presumably deleted themselves

doc_return 200 text/html "[ad_header "Welcome"]

<h2>Welcome</h2>

to the new [ad_site_home_link]

<hr>

We've converted this server to use <a
href=\"http://photo.net/wtr/thebook/community.html\">the ArsDigita
Community System</a> open-source software toolkit.

Instead of typing your email address and name each time you contribute
content, we've set up an account for you and ask you to log in only
once.

<p>

Why the conversion?  It makes it easier for the moderators of the
community to identify users who should be asked to co-moderate and
users who should be encouraged to, uh, read the site polices more
thoroughly before posting again.  It makes it possible for us to hide
your email address from spam-harvesting robots, but show it to other
registered members.  

<p>

We need a password from you to protect your identity as you contribute
to the Q&amp;A, discussion forums, and other community activities on this
site:

<p>

<blockquote>
<form method=POST action=\"legacy-user-2\">
[export_form_vars user_id return_url]

<table>
<tr>
<td>
<table>
<tr><th>Password:</th><td> <input type=password name=password1 size=10></td></tr>
<tr><th>Confirm:</th><td> <input type=password name=password2 size=10></td></tr>
</table>
</td>
<td>

<input type=submit value=\"Record\">

</td>
</tr>
</table>

<p>

(don't obsess too much over this; if you forget it, our server will
offer to email it to you)
</blockquote>

</form>

[ad_footer]
"
