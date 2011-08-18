#
# Prompt the user for email and password.
#
# $Id: index.tcl,v 3.2.2.1 2000/04/28 15:11:25 carsten Exp $
#

set_form_variables 0
# return_url maybe

set old_login_process [ad_parameter "SeparateEmailPasswordPagesP" "" "0"]

if {![info exists return_url]} {
    set return_url [ad_pvt_home]
}

ReturnHeaders
ns_write "[ad_header "Log In"]

<h2>Log In</h2>

to <a href=/>[ad_system_name]</a>

<hr>

<p><b>Current users:</b> Please enter your email and password below.</p>
<p><b>New users:</b>  Welcome to [ad_system_name].  Please begin the
registration process by entering a valid email address and a
password for signing into the system.  We will direct you to another form to 
complete your registration.</p>

<FORM method=post action=user-login.tcl>
[export_form_vars return_url]
<table>
<tr><td>Your email address:</td><td><INPUT type=text name=email></tr>
"

if { !$old_login_process } {
    ns_write "<tr><td>Your password:</td><td><input type=password name=password></td></tr>\n"
    if [ad_parameter AllowPersistentLoginP "" 1] {
	if [ad_parameter PersistentLoginDefaultP "" 1] {
	    set checked_option "CHECKED" 
	} else {
	    set checked_option "" 
	}
	ns_write "<tr><td colspan=2><input type=checkbox name=persistent_cookie_p value=t $checked_option> 
	Remember this address and password?
	(<a href=\"explain-persistent-cookies.adp\">help</a>)</td></tr>\n"
    }
}

ns_write "

<tr><td colspan=2 align=center><INPUT TYPE=submit value=\"Submit\"></td></tr>
</table>

</FORM>

<p>

[ad_style_bodynote "If you keep getting thrown back here, it is probably because your
browser does not accept cookies.  We're sorry for the inconvenience
but it really is impossible to program a system like this without
keeping track of who is posting what.

<p>

In Netscape 4.0, you can enable cookies from Edit -&gt; Preferences
-&gt; Advanced.  In Microsoft Internet Explorer 4.0, you can enable cookies from View -&gt; Internet Options -&gt; Advanced -&gt; Security."]

[ad_footer]
"
