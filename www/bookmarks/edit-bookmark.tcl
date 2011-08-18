# $Id: edit-bookmark.tcl,v 3.0.4.3 2000/04/28 15:09:46 carsten Exp $
# edit-bookmark.tcl
#
# edit a bookmark in your bookmark list
#
# by aure@arsdigita.com and dh@arsdigita.com

set_the_usual_form_variables

# bookmark_id, return_url
 
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

# start error-checking
set exception_text ""
set exception_count 0

if {(![info exists bookmark_id])||([empty_string_p $bookmark_id])} {
    incr exception_count
    append exception_text "<li>No bookmark was specified"
}

# This conditional is needed to catch JavaScript when the user clicks on the folder by his name
if {$bookmark_id=="undefined"} {
    ad_returnredirect $return_url
}
# make sure that the user owns the bookmark
set  ownership_query "
        select count(*)
        from   bm_list
        where  owner_id=$user_id
        and bookmark_id=$bookmark_id"
set ownership_test [database_to_tcl_string $db $ownership_query]

if {$ownership_test==0} {
    incr exception_count
    append exception_text "<li>You can not edit this bookmark"
}

# return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

set page_title "Edit Bookmark"

set page_content "
[ad_header $page_title ]
<h2> $page_title </h2>
[ad_context_bar_ws [list $return_url [ad_parameter SystemName bm]] $page_title]
<hr>
"

set bm_info_query "
        select nvl(local_title, url_title) as title, complete_url, folder_p,
               parent_id, private_p, bookmark_id, hidden_p
        from   bm_list,bm_urls
        where  bookmark_id=$bookmark_id
        and    owner_id=$user_id
        and    bm_list.url_id=bm_urls.url_id(+)"

set selection [ns_db 1row $db $bm_info_query]
 
set_variables_after_query

# begin the form and table
append page_content "<form method=post action=edit-bookmark-2><table>"
 
# if the bookmark that is being edited is a real bookmark, ie. not a folder
if {$folder_p=="f"} {
    append page_content "
    <tr> 
      <td align=right valign=top>URL:</td> 
      <td align=left><input type=text size=40 name=complete_url value=\"[philg_quote_double_quotes $complete_url]\"></td>
    <tr>"
}

append page_content "
  <td align=right valign=top>Title:</td>
  <td align=left><input type=text size=40 name=local_title value=\"[philg_quote_double_quotes $title]\"></td>
</tr>
<tr>
  <td align=right valign=top>Parent Folder:</td>
  <td>[bm_folder_selection $db $user_id $bookmark_id]</td>
</tr>
  <td align=right valign=top>Privacy:</td>
  <td align=left>"

# place the appropriate radio buttons given the privacy setting of the bookmark
if {$private_p=="f" } {
    append page_content "
    <input type=radio name=private_p value=f checked > Public <br> 
    <input type=radio name=private_p value=t> Private  "
} else {
    append page_content "
    <input type=radio name=private_p value=f > Public <br> 
    <input type=radio name=private_p value=t checked> Private"
}

# alert the user that public/private settings will mean nothing 
# if the bookmark is within a private folder
if { ![empty_string_p $parent_id] && $hidden_p == "t" } {
    append page_content "<br>(At least one parent folder is private - so this file will always be hidden from the public)"
}

# ending the form (note that /form is purposely put between /td and /tr to avoid any unnecessary
# implied paragraph breaks
append page_content "
  </td>
</tr>
<tr>
  <td></td>
  <td>[export_form_vars bookmark_id return_url]<input type=submit value=\"Submit these updates\"></td>
  </form>
</tr>
"

# write the appropriate words on the delete submit button
if {$folder_p=="t"} {
    set delete_text "Delete folder and all its contents"
} else {
    set delete_text "Delete this bookmark"
}

# write out a link for deleting the bookmark, a link is used instead of a submit button
# to keep within the ACS style guidelines of having one submit button per page
append page_content "
<tr>
  <td valign=top align=right>Severe Actions:</td>
  <td><a href=delete-bookmark?[export_url_vars return_url bookmark_id]>$delete_text</a></td>
</tr>
</table>"

# put a footer on the page
append page_content "[bm_footer]"

# release the database handle before serving the page
ns_db releasehandle $db 

# serve the page
ns_return 200 text/html $page_content 









