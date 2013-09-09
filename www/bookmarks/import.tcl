# /www/bookmarks/import.tcl

ad_page_contract {
    static html page for importing bookmarks in a variety of ways
    although this is mostly static html, we need it to be in tcl
    for setting the return_url and grabbing the next bookmark_id
    from the database

    @param return_url return_url is needed because this page could be called from either the index page or the javascript window and we need to eventually send the user back to the right place
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
    @creation-date June 1999  
    @cvs-id import.tcl,v 3.2.2.9 2001/01/09 22:54:44 khy Exp
} {
    return_url:trim
} 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# we grab the bookmark_id now for double click protection
set bookmark_id [db_string bm_id "select bm_bookmark_id_seq.nextval from dual"]

# release the database handle
db_release_unused_handles 

set page_title "Add/Import Bookmarks"

doc_return  200 text/html "
[ad_header $page_title]

<h2>$page_title</h2>

[ad_context_bar_ws [list $return_url [ad_parameter SystemName bm]] $page_title]

<hr>

<h3>Add manually</h3>
Insert the URL below.  If you leave the title blank, we will 
attempt to get the title from the web site.  

<form action=insert-one method=post name=topform>
[export_form_vars return_url]

<table>
<tr>
   <td valign=top align=right>URL:</td>
   <td align=left><input name=complete_url></td>
</tr>
<tr>
   <td valign=top align=right>Title (Optional):</td>
   <td align=left><input name=local_title></td>
</tr>
<tr>
   <td>
   </td>
   <td align=left>
   <input type=submit value=\"Add one manually\">
   </td>
</tr>
</table>
</form>

<h3>Import multiple bookmarks from Netscape or Microsoft Internet Explorer bookmark.htm file</h3>

<form enctype=multipart/form-data method=POST action=import-bookmarks>
[export_form_vars -sign bookmark_id]
[export_form_vars return_url]

Netscape users: Just specify your bookmark file<br>
Users of new versions of IE: Export your shortcuts to Netscape format, then
                             specify the file<br>
Users of old versions of IE: Use <a href=favtool.exe>this utility</a> to 
                             convert your shortcuts.

<p>
Bookmarks File: <input type=file name=upload_file size=10>
<input type=submit value=\"Import from bookmark.htm\">

<p> 

[bm_footer]"















