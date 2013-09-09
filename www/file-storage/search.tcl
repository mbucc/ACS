# /file-storage/search.tcl
ad_page_contract {
    looks through file names, version descriptions, client file names
    case-insensitive but stupid
 
    @author aure@arsdigita.com
    @creation-date July 1999
    @cvs-id search.tcl,v 3.7.6.5 2000/09/22 01:37:48 kevin Exp

    modified by randyg@arsdigita.com to use the general permissions system
} {
    {search_text ""}
    {return_url}
    {group_id ""}
}

set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

set title "Search for \"$search_text\""

set page_content "[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws [list $return_url [ad_parameter SystemName fs]] $title]
<hr align=left>
<blockquote>\n"

# Parameterize for interMedia
if { [ad_parameter UseIntermediaP fs 0] } {
    set score_column "score(1) as the_score,"
    set intermedia_clause " or contains(fsvl.version_content, '$QQsearch_text', 1) > 0"
    set order_clause "order by decode(owner_id, $user_id, 0, 1), 1 desc"
    set search_explanation "We do a case-insensitive phrase search through
file titles, client filenames (what these files were called on the
original system), and any version descriptions or comments.

<p>

In addition, we do a full-text search through the bodies of all
uploaded documents.

<p>

[ad_intermedia_text_searching_hints]
" } else {
    set score_column ""
    set intermedia_clause ""
    set order_clause "order by decode(fsf.owner_id, $user_id, 0, 1), fsf.file_title"
    set search_explanation "We do a case-insensitive phrase search through
file titles, client filenames (what these files were called on the
original system), and any version descriptions or comments."
}

# this select gets readable files that match user's request 
# (one's belonging to the user first)

# the ways a user can see a file
# 1. the user is the owner (f.owner_id = $user_id)
# 2. the public is allowed to read the file (public_read_p = 't')
# 3. there is a permissions record to allow someone to read (pum.read_p = 't')
#    4. and that somone is the user (map.user_id = $user_id)
#    5. and that somone if a group that the user belongs to

set search_pattern %$search_text%

set sql_query "
select fsf.file_title, :score_column, 
       fsf.file_id, 
       round(fsvl.n_bytes/1024) as n_kbytes, 
       nvl ( fsvl.file_type, upper ( fsvl.file_extension ) || ' File' ) as file_type,
       to_char(fsvl.creation_date,'[fs_date_picture]') as creation_date,
       fsf.owner_id,
       u.first_names || ' ' || u.last_name as owner_name,
       fsf.folder_p,
       decode(fsf.owner_id,:user_id,0,1) as belongs_to_someone_else_p, 
       fsvl.url,
       fsvl.version_id,
       fsvl.client_file_name
from   fs_files fsf,
       fs_versions_latest fsvl,
       users u
where  fsf.file_id = fsvl.file_id
and    fsf.owner_id = u.user_id
and    ad_general_permissions.user_has_row_permission_p (:user_id, 'read', fsvl.version_id, 'FS_VERSIONS') = 't'
and fsf.deleted_p='f'
and (upper(fsvl.version_description) like upper(:search_pattern)
     or upper(fsf.file_title) like upper(:search_pattern)
     or upper(fsvl.client_file_name) like upper(:search_pattern)
     $intermedia_clause)
$order_clause"

set file_count 0
set file_html ""

set font "<nobr>[ad_parameter FileInfoDisplayFontTag fs]"
set header_color [ad_parameter HeaderColor fs]

# we start with an outer table to get little white lines in 
# between the elements 

set wrote_personal_header_p 0
set wrote_other_header_p 0

append page_content "<table border=1 bgcolor=white  cellpadding=0 cellspacing=0>
<tr>
  <td>
  <table bgcolor=white cellspacing=1 border=0 cellpadding=0>
" 

db_foreach file_list $sql_query {
    if { $belongs_to_someone_else_p == 0 && !$wrote_personal_header_p } {
	set wrote_personal_header_p 1
	append file_html [fs_header_row_for_files -title "Personal files matching \"$search_text\"" -author_p 1]
    }
    if { $belongs_to_someone_else_p == 1 && !$wrote_other_header_p } {
	set wrote_other_header_p 1

	# This if was added to avoid confusion.  It won't say "Other readable files..." unless there were personal
	# files displayed.  It will just say "Readable files..."
	if { !$wrote_personal_header_p } {
	    set readable_beginning "R"
	} else {
	    set readable_beginning "Other r"
	}
	append file_html [fs_header_row_for_files -title "${readable_beginning}eadable files matching \"$search_text\"" -author_p 1]
    }

    append file_html [fs_row_for_one_file \
	    -file_id $file_id \
	    -folder_p $folder_p -client_file_name $client_file_name \
	    -n_kbytes $n_kbytes -file_title $file_title -url $url -creation_date $creation_date \
	    -version_id $version_id -file_type $file_type \
	    -export_url_vars [export_url_vars file_id group_id] \
	    -owner_id $owner_id -owner_name $owner_name -author_p 1]

    incr file_count
}

if {$file_count!=0} {
    append page_content "$file_html"
} else {
    append page_content "<tr><td>No files matched your search. </td></tr>"
}
append page_content "
</table></td></tr></table></blockquote>

<p>

<blockquote>
$search_explanation
</blockquote>

[ad_footer [fs_system_owner]]"

# serve the page

doc_return  200 text/html $page_content

