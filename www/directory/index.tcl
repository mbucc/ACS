# /www/directory/index.tcl

ad_page_contract {
    let's users search and browse for each other
    also gives access to users with uploaded portraits

    @cvs-id index.tcl,v 3.4.2.4 2000/09/22 01:37:21 kevin Exp
    @author Philip Greenspun (philg@mit.edu)
    @creation-date early 1999
} {}

set user_id [ad_maybe_redirect_for_registration]

set simple_headline "<h2>Directory</h2>

[ad_context_bar_ws_or_index "User Directory"]
"

if ![empty_string_p [ad_parameter IndexPageDecoration directory]] {
    set full_headline "<table cellspacing=10><tr><td>[ad_parameter IndexPageDecoration directory]<td>$simple_headline</tr></table>"
} else {
    set full_headline $simple_headline
}


set body "
[ad_header "[ad_system_name] Directory"]

$full_headline

<hr>

Look up a fellow user:

<p>

<blockquote>

<form method=GET action=\"lookup\">

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
    append body "To get a feel for the community, you might want to simply 
<ul>
<li><a href=\"browse\">browse the [ad_system_name] directory</a>
<li>or <a href=\"portrait-browse\">look at user-uploaded portraits</a>
</ul>
<p>

"
}

append body  "

[ad_style_bodynote "Note: The only reason you are seeing this page at all is that you
are a logged-in authenticated user of [ad_system_name]; this
information is not available to tourists.  If you want to upload
a picture of yourself, visit [ad_pvt_home_link]."]

[ad_footer]
"

doc_return  200 text/html $body



