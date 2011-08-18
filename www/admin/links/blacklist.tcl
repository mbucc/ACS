# $Id: blacklist.tcl,v 3.0.4.1 2000/04/28 15:09:09 carsten Exp $
set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}

set_the_usual_form_variables

# page_id, url

set db [ns_db gethandle]
set url_stub [database_to_tcl_string $db "select url_stub from static_pages where page_id = $page_id"]

ns_return 200 text/html "[ad_admin_header "Blacklist $url"]

<h2>Blacklist $url</h2>

on <a href=\"$url_stub\">$url_stub</a> (or everywhere)

<hr>

<form method=POST action=blacklist-2.tcl>
<input type=radio name=page_id value=\"*\" CHECKED> On all pages
<input type=radio name=page_id value=\"$page_id\"> Just on $url_stub
<p>
Kill Pattern:  <input type=text name=glob_pattern size=50 value=\"$url\">
<br>

Note: This uses Unix \"glob-style\" matching.  * matches zero or more
characters.  ? matches any single character.  \"\[a9\]\" matches a lower
case letter A or the number 9.  You can use a backslash if you want one of
these special characters to be matched.

<br>
<br>

<center>

<input type=submit value=Confirm>

</center>

</form>

<p>

<h3>Example patterns</h3>

<ul>
<li>\"*mit.edu*\" will match any URL that includes \"mit.edu\".  This
would be useful to exclude all Web sites served off MIT machines, but
would also falsely trigger on random other sites that had \"mit.edu\"
as part of a URL, like \"http://bozo.com/hermit.education.in.caves.html\"

<li>\"http://www.microsoft.com*\" would exclude the entire Microsoft
main Web server.

<li>\"http://photo.net/photo/nudes.html\" would exclude only this one
naughty document.
</ul>

[ad_admin_footer]
"
