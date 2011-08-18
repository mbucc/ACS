# $Id: user-new.tcl,v 3.0.4.1 2000/03/15 17:24:38 jsalz Exp $
#
# user-new.tcl
#
# presents a registration form to a new user
# 

set_the_usual_form_variables

# email, return_url, maybe password

if { ![info exists password] } {
    set password ""
}

# we're going to ask this guy to register

set db [ns_db gethandle]
set user_id [database_to_tcl_string $db "select user_id_sequence.nextval from dual"]
# we don't need it anymore so let's release it for another thread
ns_db releasehandle $db 


append html_text "[ad_header "Register"]

<h2>Register</h2>

as a user of <a href=\"index.tcl\">[ad_system_name]</a>

<hr>

<form method=post action=\"user-new-2.tcl\">
[export_form_vars email return_url user_id]"


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

ns_return 200 text/html $html_text
