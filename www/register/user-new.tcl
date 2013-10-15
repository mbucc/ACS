ad_page_contract {
    Registration form for a new user.  The following variables must be set using 
    <code>ad_set_client_property register</code>:
    <ul>
    <li>email
    <li>password
    <li>return_url is optional
    </ul>

    @cvs-id  user-new.tcl,v 3.4.2.7 2001/01/12 19:58:32 khy Exp
} 


set email [ad_get_client_property register email]
set password [ad_get_client_property register password]
set return_url [ad_get_client_property -default [ad_pvt_home] register return_url]

# Check if the email address makes sense
# We check it here, because this is the last chance the user has to change it
if { ![philg_email_valid_p $email] } {
    ad_return_complaint 1 "<li>The email address that you typed doesn't look right to us.  Examples of valid email addresses are 
<ul>
<li>Alice1234@aol.com
<li>joe_smith@hp.com
<li>pierre@inria.fr
</ul>"
    return
}

# we're going to ask this guy to register

set user_id [db_string user_new_user_id_next_sequence_id "select user_id_sequence.nextval from dual"]

# we don't need it anymore so let's release it for another thread
db_release_unused_handles 

append html_text "[ad_header "Register"]

<h2>Register</h2>

yourself as a user of <a href=\"index\">[ad_system_name]</a>

<hr>

<form method=post action=\"user-new-2\">
[export_form_vars email return_url]
[export_form_vars -sign user_id]
"

if ![ad_parameter RegistrationProvidesRandomPasswordP "" 0] {

    append html_text "<h3>Security</h3>

We need a password from you to protect your identity as you contribute to the Q&A, discussion forums, and other community activities on this site.

<p>
<table>
<tr>
  <td>Password:</td>
  <td><input type=password name=password value=\"$password\" size=10></td>
</tr>
<tr>
  <td>Password Confirmation:</td>
  <td><input type=password name=password_confirmation size=10></td>
</tr>
</table>
<p>

[ad_style_bodynote "Leading or trailing spaces will be removed by the server.  
Don't obsess too much over your choice of password; if you forget it, our server will
offer to email it to you."]
"

}

append html_text "<h3>About You</h3>

We know your email address already: \"$email\".  But we need your full
name to generate certain kinds of user interface.

<p>

Full Name:    <input type=text name=first_names size=20> <input type=text name=last_name size=25>
<p>

If you have a Web site, we'll be able to point searchers there.

<p>

Personal Home Page URL:  <input type=text name=url size=50 value=\"http://\">

<p>

<center>
<input type=submit value=\"Register\">
</center>
</form>

[ad_footer]
"

doc_return  200 text/html $html_text
