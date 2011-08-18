# /bookmarks/import-from-shortcut.tcl
#
# a utility to grab info from shortcut
#
# by aure@arsdigita.com, June 1999
#
# $Id: import-from-shortcut.tcl,v 3.0.4.2 2000/04/18 16:35:19 carsten Exp $

ad_page_variables {
    upload_file
    return_url
}

set exception_text ""
set exception_count 0

if { [empty_string_p $upload_file] } {
    incr exception_count
    append exception_text "<li>Please specify the name of the shortcut file."
}

## return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set contents [read [open [ns_queryget upload_file.tmpfile r]]]

set folder_list 0
set parent_id 0
set lines [split $contents "\n"]

set db [ns_db gethandle]

set bookmark_id [database_to_tcl_string $db "
select bm_bookmark_id_seq.nextval from dual"]

# release the database handle
ns_db releasehandle $db 

set local_title $upload_file
set directory ""

regexp {([^\\]*).url} $upload_file match local_title
regexp {([^\\]*)\\[^\\]*.url} $upload_file match directory 

foreach line $lines {
    regexp {URL=([^ ]*)[ ]*} $line match complete_url
}

if { ![info exists complete_url] } {
    ad_return_error "No URL Found" \
	"Could not find a URL in the file you specified.
	 Please make sure that it is a valid Internet Explorer shortcut file."
    return
}

set title "Choose Folder for \"$local_title\""

ns_return 200 text/html "[ad_header "$title"]

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

[bm_folder_selection $db $user_id $bookmark_id]
<br>
<input type=submit value=Submit></form>
</td>
</tr>
</table>
</ul>

[bm_footer]
"
