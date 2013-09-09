# /admin/links/blacklist.tcl

ad_page_contract {
    Keep a URL from reappearing, on one page or all pages

    @param page_id The ID of the page the blacklist came from
    @param url The URL to blacklist

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id blacklist.tcl,v 3.3.2.7 2000/09/22 01:35:29 kevin Exp
} {
    page_id:notnull,naturalnum
    url:notnull
}

set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}


set url_stub [db_string select_url_stub "select url_stub from static_pages where page_id = :page_id"]

set pattern_id [db_string select_patern_id "select link_kill_pattern_id.nextval from dual"]

db_release_unused_handles

set page_content "[ad_admin_header "Blacklist $url"]

<h2>Blacklist $url</h2>

on <a href=\"$url_stub\">$url_stub</a> (or everywhere)

<hr>

<form method=POST action=\"blacklist-2\">
[export_form_vars pattern_id]
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

doc_return  200 text/html $page_content
