# /file-storage/search.tcl
# 
# by aure@arsdigita.com, July 1999
#
# looks through file names, version descriptions, client file names
# case-insensitive but stupid
#
# modified by randyg@arsdigita.com to use the general permissions system
#
# $Id: search.tcl,v 3.2.2.1 2000/04/03 16:38:15 carsten Exp $

ad_page_variables {
    {search_text "" qq}
    {return_url}
    {group_id ""}
}

set db [ns_db gethandle]

set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

set title "Search for \"$search_text\""

set page_content "[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws [list $return_url [ad_parameter SystemName fs]] $title]
<hr>
<blockquote>\n"

# Parameterize for interMedia
if { [ad_parameter UseIntermediaP fs 0] } {
    set score_column "score(1) as the_score,"
    set intermedia_clause " or contains(version_content, '$QQsearch_text', 1) > 0"
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
    set order_clause "order by decode(owner_id, $user_id, 0, 1), file_title"
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

set sql_query "
select distinct file_title, $score_column 
       f.file_id, 
       round(n_bytes/1024) as n_kbytes, 
       file_type, 
       to_char(v.creation_date,'[fs_date_picture]') as creation_date,
       decode(owner_id,$user_id,0,1) as belongs_to_someone_else_p, 
       owner_id, folder_p
from   fs_files f, fs_versions v
where  f.file_id = v.file_id
and    v.superseded_by_id is null
and    ad_general_permissions.user_has_row_permission_p ($user_id, 'read', v.version_id, 'FS_VERSIONS') = 't'
and deleted_p='f'
and (upper(version_description) like upper('%$QQsearch_text%')
     or upper(file_title) like upper('%$QQsearch_text%')
     or upper(client_file_name) like upper('%$QQsearch_text%')
     $intermedia_clause)
group by file_title, f.file_id, n_bytes, file_type, v.creation_date, owner_id, folder_p
$order_clause"

set selection [ns_db select $db $sql_query]

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

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    if { $belongs_to_someone_else_p == 0 && !$wrote_personal_header_p } {
	set wrote_personal_header_p 1
	append file_html "
          <tr><td colspan=4 bgcolor=#666666>
              $font &nbsp;<font color=white> Personal files matching \"$search_text\"
              </td>
          </tr>\n"
	append file_html [fs_header_row_for_files]
    }
    if { $belongs_to_someone_else_p == 1 && !$wrote_other_header_p } {
	set wrote_other_header_p 1
	append file_html "
          <tr><td colspan=4 bgcolor=#666666>
              $font &nbsp;<font color=white> Other readable files matching \"$search_text\"
              </td>
          </tr>\n"
	append file_html [fs_header_row_for_files]
    }

    if { $folder_p == "t" } {
	set file_url "one-folder?[export_url_vars file_id group_id]"
	set image "ftv2folderclosed.gif"
    } else {
	set file_url "one-file?[export_url_vars file_id group_id]"
	set image "ftv2doc.gif"
    }

    append file_html "
    <tr>
    <td valign=top>&nbsp; $font
    <a href=\"$file_url\">
    <img border=0 src=/graphics/file-storage/$image align=top></a>
    <a href=\"$file_url\">$file_title</a>&nbsp;</td>
    <td align=right>"

    if { $folder_p == "f" } { append file_html "$font &nbsp; $n_kbytes KB &nbsp;" }

    append file_html "
    </td><td>$font &nbsp; [fs_pretty_file_type $file_type] &nbsp;</td>
    <td>$font &nbsp; $creation_date &nbsp;</td>
    </tr>\n"    
     
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

# release the database handle

ns_db releasehandle $db

# serve the page

ns_return 200 text/html $page_content

