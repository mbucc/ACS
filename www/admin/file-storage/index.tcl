# /admin/file-storage/index.tcl
#
# at this point mostly by philg@mit.edu
#
# gives a site-admin a high-level view of who is using the file storage system
#
# $Id: index.tcl,v 3.1 2000/03/11 23:10:04 aure Exp $


set page_content  "
[ad_admin_header "[ad_parameter SystemName fs] Administration"]

<h2>[ad_parameter SystemName fs]</h2>

[ad_admin_context_bar [ad_parameter SystemName fs]]

<hr>

Documentation:  <a href=\"/doc/file-storage\">/doc/file-storage</a>

<p>

Users with files/folders in their personal directories: "

set db [ns_db gethandle subquery]


# get the names of users who have stuff in their personal space

set selection [ns_db select $db "
    select   users.user_id, users.first_names, users.last_name, 
             count(distinct fs_files.file_id) as n_files,
             round(sum(fs_versions.n_bytes)/1024) as n_kbytes
    from     users, fs_files, fs_versions
    where    users.user_id = fs_files.owner_id
    and      fs_files.file_id = fs_versions.file_id
    and      fs_files.group_id is NULL
    and      fs_files.deleted_p='f'
    group by users.user_id, users.first_names, users.last_name"]

set persons_html "" 

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append persons_html "
        <li><a href=personal-space?owner_id=$user_id>$first_names $last_name</a>: 
        $n_files files; $n_kbytes Kbytes\n"
}

append page_content "<ul> $persons_html </ul>"

set selection [ns_db select $db "
select user_groups.group_id, 
       group_name, 
       round(sum(fs_versions.n_bytes)/1024) as n_kbytes,
       count(distinct fs_files.file_id) as n_files
from   user_groups, fs_files, fs_versions
where  user_groups.group_id = fs_files.group_id
and    fs_files.file_id = fs_versions.file_id
group by user_groups.group_id, group_name"]

set group_html ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append group_html "
        <li><a href=\"group?[export_url_vars group_id]\">$group_name</a>:  
        $n_files files; $n_kbytes Kbytes\n"
}

if { ![empty_string_p $group_html] } {
    append page_content  "<nobr>Groups with files/folders stored: 
        <ul>$group_html</ul>\n"
} 

append page_content "[ad_admin_footer]"

# release the database handle

ns_db releasehandle $db 

# serve the page

ns_return 200 text/html $page_content








