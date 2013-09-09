# /www/admin/bookmarks/edit-bookmark.tcl

ad_page_contract {
    admin version
    edit a bookmark in your bookmark list
    @param bookmark_id 
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
    @creation-date June 1999  
    @cvs-id edit-bookmark.tcl,v 3.2.2.4 2000/09/22 01:34:24 kevin Exp
} {
    bookmark_id:integer
} 
 
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# --error-checking ---------------------------
 set exception_text ""
set exception_count 0

if {(![info exists bookmark_id])||([empty_string_p $bookmark_id])} {
    incr exception_count
    append exception_text "<li>No bookmark was specified"
}

# return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

# -----------------------------------------------
# get the owner_id, owner_name for this bookmark
db_1row owner_info "select owner_id, 
                           first_names||' '||last_name as owner_name 
                    from   users, bm_list 
                    where  bookmark_id = :bookmark_id 
                    and    owner_id = user_id"

# get all the current information about this bookmark
db_1row bm_info "select nvl(local_title, url_title) as title, 
                        complete_url, 
                        folder_p, 
                        parent_id, 
                        private_p, 
                        bookmark_id, 
                        hidden_p
                 from   bm_list,bm_urls
                 where  bookmark_id = :bookmark_id
                 and    bm_list.url_id=bm_urls.url_id(+)"

# --create the html to be served ---------------------------------------
set page_title "Edit Bookmark"

set html "
[ad_admin_header $page_title ]
<h2> $page_title </h2>
[ad_admin_context_bar [list index.tcl Bookmarks] [list one-user.tcl?[export_url_vars owner_id] "$owner_name's"] $page_title]
<hr>
"

# begin the form and table
append html "<form method=post action=edit-bookmark-2><table>"
 
# if the bookmark that is being edited is a real bookmark, ie. not a folder
if {$folder_p=="f"} {
    append html "
    <tr> 
      <td align=right valign=top>URL:</td> 
      <td align=left><input type=text size=40 name=complete_url value=\"[philg_quote_double_quotes $complete_url]\"></td>
    <tr>"
}

append html "
  <td align=right valign=top>Title:</td>
  <td align=left><input type=text size=40 name=local_title value=\"[philg_quote_double_quotes $title]\"></td>
</tr>
<tr>
  <td align=right valign=top>Parent Folder:</td>
  <td>[bm_folder_selection $owner_id $bookmark_id]</td>
</tr>
  <td align=right valign=top>Privacy:</td>
  <td align=left>"

# place the appropriate radio buttons given the privacy setting of the bookmark
if {$private_p=="f" } {
    append html "
    <input type=radio name=private_p value=f checked > Public <br> 
    <input type=radio name=private_p value=t> Private  "
} else {
    append html "
    <input type=radio name=private_p value=f > Public <br> 
    <input type=radio name=private_p value=t checked> Private"
}

# alert the user that public/private settings will mean nothing if the bookmark is within a private folder
if {$hidden_p} {
    append html "(A parent folder is private - so this file will automatically be hidden from the public)"
} else {
    append html "(None of the parent folders are private)"
}

# ending the form (note that /form is purposely put between /td and /tr to avoid any unnecessary
# implied paragraph breaks
append html "
  </td>
</tr>
<tr>
  <td></td>
  <td>[export_form_vars bookmark_id]<input type=submit value=\"Submit these updates\"></td>
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
append html "
<tr>
  <td valign=top align=right>Severe Actions:</td>
  <td><a href=delete-bookmark?[export_url_vars bookmark_id]>$delete_text</a></td>
</tr>
</table>"

# put a footer on the page
append html "[ad_admin_footer]"

# release the database handle before serving the page
db_release_unused_handles 

# --serve the page ------------------------------
doc_return  200 text/html $html 




