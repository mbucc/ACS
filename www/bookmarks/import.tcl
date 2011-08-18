# /bookmarks/import.tcl
#
# by aure@arsdita.com and dh.arsdigita.com, June 1999
#
# static html page for importing bookmarks in a variety of ways
#
# although this is mostly static html, we need it to be in tcl
# for setting the return_url and grabbing the next bookmark_id
# from the database
#
# $Id: import.tcl,v 3.0.4.2 2000/03/15 05:22:00 aure Exp $

ad_page_variables {return_url}

# (return_url is needed because this page could be called from either the 
# index page or the javascript window and we need to eventually send the 
# user back to the right place)

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

# we grab the bookmark_id now for double click protection
set bookmark_id [database_to_tcl_string $db "
select bm_bookmark_id_seq.nextval from dual"]

# release the database handle
ns_db releasehandle $db 

set page_title "Add/Import Bookmarks"

ns_return 200 text/html "
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

<h3>Import multiple bookmarks from Netscape-style bookmark.htm file</h3>

<form enctype=multipart/form-data method=POST action=import-from-netscape>
[export_form_vars bookmark_id return_url]
Use the browse button to locate your bookmark.htm file 
(the default location for Netscape users is 
c:\\Program Files\\Netscape\\Users\\<i>your_name</i>\\bookmark.htm )<br>

Bookmarks File: <input type=file name=upload_file size=10>
<input type=submit value=\"Import from bookmark.htm\">

<p> 

Note: For Internet Explorer users, you may convert your favorites into a 
bookmarks.htm file using <a href=favtool.exe>favtool.exe</a>, a free tool 
created by Microsoft to solve this problem.

</form>

<h3>Import one bookmark from IE shortcut file</h3>

<form enctype=multipart/form-data method=POST action=import-from-shortcut>
[export_form_vars return_url]
Use the browse button to locate an IE favorites shortcut 
(the default directory for these files  is c:\\Windows\\Favorites\\)<br>
Favorite Shortcut: <input type=file name=upload_file size=10>
<input type=submit value=\"Import from Shortcut\">

</form>

[bm_footer]"










