# /www/bookmarks/import-from-shortcut.tcl
ad_page_contract {
    a utility to grab info from shortcut
    @param upload_file file to be uploaded
    @param return_url URL for user to return to
    @author Aurelius Prochazka (aure@arsdigita.com)
    @creation-date June 1999  
    @cvs-id import-from-shortcut.tcl,v 3.4.2.9 2000/09/22 01:37:02 kevin Exp
} {
    {upload_file:tmpfile}
    {return_url:trim}
} 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set contents [read [open [ns_queryget upload_file.tmpfile r]]]

if [empty_string_p $contents] {
    ad_return_complaint 1 "You need to specify a file to upload"
    return
}

set folder_list 0
set parent_id 0
set lines [split $contents "\n"]

set bookmark_id [db_string bookmark_id "select bm_bookmark_id_seq.nextval from dual"]

set directory [db_null]

if { ![regexp {([^\\]*).url} $upload_file match local_title] } {
    ad_return_complaint 1 "<li>We had trouble parsing this shortcut to find the url you want in your bookmarks"
    return
} 

regexp {([^\\]*)\\[^\\]*.url} $upload_file match directory 

foreach line $lines {
    regexp {URL=([^ ]*)[ ]*} $line  match complete_url
}

set title "Choose Folder for \"$local_title\""

set page_content "[ad_header "$title"]

<h2>$title</h2>

[ad_context_bar_ws "$return_url [ad_parameter SystemName bm]" [list "import" "Import"] "$title"]

<hr>

You will be adding: 
<ul> 
<li>$local_title
<li><a href=$complete_url>$complete_url</a>
</ul>
If this is correct, choose which folder to place the bookmark in:
<ul>
<table>
<form action=insert-one-2 method=post>
<tr>
<td align=center>

[export_form_vars local_title complete_url bookmark_id return_url]

[bm_folder_selection $user_id $bookmark_id]
<br>
<input type=submit value=Submit></form>
</td>
</tr>
</table>
</ul>

[bm_footer]"

# release the database handle
db_release_unused_handles 

# serve the page
doc_return  200 text/html $page_content







