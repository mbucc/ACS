ad_page_contract {
    at this point mostly by philg@mit.edu
    gives a site-admin a high-level view of who is using the file storage system
    @cvs-id index.tcl,v 3.2.2.4 2000/09/22 01:35:14 kevin Exp
}

set page_content  "
[ad_admin_header "[ad_parameter SystemName fs] Administration"]

<h2>[ad_parameter SystemName fs]</h2>

[ad_admin_context_bar [ad_parameter SystemName fs]]

<hr>

Documentation:  <a href=\"/doc/file-storage\">/doc/file-storage</a>

<p>

Users with files/folders in their personal directories: "

# get the names of users who have stuff in their personal space

set sql "
    select   users.user_id, users.first_names, users.last_name, 
             count(distinct fs_files.file_id) as n_files,
             round(sum(fs_versions.n_bytes)/1024) as n_kbytes
    from     users, fs_files, fs_versions
    where    users.user_id = fs_files.owner_id
    and      fs_files.file_id = fs_versions.file_id
    and      fs_files.group_id is NULL
    and      fs_files.deleted_p='f'
    group by users.user_id, users.first_names, users.last_name"

set persons_html "" 

db_foreach list_of_persons $sql {
    append persons_html "
        <li><a href=personal-space?owner_id=$user_id>$first_names $last_name</a>: 
        $n_files files; $n_kbytes Kbytes\n"
}

append page_content "<ul> $persons_html </ul>"

set sql "
select user_groups.group_id, 
       group_name, 
       round(sum(fs_versions.n_bytes)/1024) as n_kbytes,
       count(distinct fs_files.file_id) as n_files
from   user_groups, fs_files, fs_versions
where  user_groups.group_id = fs_files.group_id
and    fs_files.file_id = fs_versions.file_id
group by user_groups.group_id, group_name"

set group_html ""

db_foreach list_of_groups $sql {
    append group_html "
        <li><a href=\"group?[export_url_vars group_id]\">$group_name</a>:  
        $n_files files; $n_kbytes Kbytes\n"
}

if { ![empty_string_p $group_html] } {
    append page_content  "<nobr>Groups with files/folders stored: 
        <ul>$group_html</ul>\n"
} 

append page_content "[ad_admin_footer]"

# serve the page

doc_return  200 text/html $page_content


