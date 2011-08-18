# $Id: index.tcl,v 3.0.4.1 2000/04/28 15:09:55 carsten Exp $
#
# /directory/index.tcl
#
# by philg@mit.edu in early 1999
# 
# let's users search and browse for each other
# also gives access to users with uploaded portraits
#

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode "/directory/"]"
    return
}

set simple_headline "<h2>Directory</h2>

[ad_context_bar_ws_or_index "User Directory"]
"

if ![empty_string_p [ad_parameter IndexPageDecoration directory]] {
    set full_headline "<table cellspacing=10><tr><td>[ad_parameter IndexPageDecoration directory]<td>$simple_headline</tr></table>"
} else {
    set full_headline $simple_headline
}

ReturnHeaders

ns_write "
[ad_header "[ad_system_name] Directory"]

$full_headline

<hr>

Look up a fellow user:

<p>


<blockquote>

<form method=GET action=\"lookup.tcl\">

<table>
<tr><td>Whose last name begins with<td><input type=text name=last_name size=20></tr>
<tr><td>Whose email address begins with<td><input type=text name=email size=20></tr>

</table>


<center>
<input type=submit value=\"Search\">
</center>

</form>

</blockquote>

"

if {[ad_parameter ProvideUserBrowsePageP directory 1] && [ad_parameter NumberOfUsers "" medium] != "large" } {
    ns_write "To get a feel for the community, you might want to simply 
<ul>
<li><a href=\"browse.tcl\">browse the [ad_system_name] directory</a>
<li>or <a href=\"portrait-browse.tcl\">look at user-uploaded portraits</a>
</ul>
<p>

"
}

ns_write "

[ad_style_bodynote "Note: The only reason you are seeing this page at all is that you
are a logged-in authenticated user of [ad_system_name]; this
information is not available to tourists.  If you want to upload
a picture of yourself, visit [ad_pvt_home_link]."]

[ad_footer]
"
