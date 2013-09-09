ad_page_contract {
    @cvs-id quota.tcl,v 3.3.2.4.2.3 2000/09/22 01:36:20 kevin Exp
    File:     /admin/users/quota.tcl
    Date:     Thu Jan 27 03:57:32 EST 2000
    Location: 42��21'N 71��04'W
    Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
    Author:   mobin@mit.edu (Usman Y. Mobin)
    Purpose:  User Quota Management
} {
    user_id:integer,notnull
}


db_1row unused "
select users.first_names as first_names,
       users.last_name as last_name,
       users_special_quotas.max_quota as max_quota
from users_special_quotas, users
where users_special_quotas.user_id(+) = users.user_id
and users.user_id = :user_id"

# Checking for site-wide administration status
set admin_p [ad_administrator_p $user_id]

set sql "
select (select count(*) * [ad_parameter DirectorySpaceRequirement users]
        from users_files
        where directory_p='t'
        and owner_id = :user_id) +
       (select nvl(sum(file_size),0)
        from users_files
        where directory_p = 'f'
        and owner_id = :user_id) as quota_used,
       (decode((select count(*) from
                users_special_quotas
                where user_id = :user_id),
                0, [ad_parameter [ad_decode $admin_p \
			 0 NormalUserMaxQuota \
			 1 PrivelegedUserMaxQuota \
			 PrivelegedUserMaxQuota] users],
                (select max_quota from
                 users_special_quotas
                 where user_id = :user_id))) * power(2,20) as quota_max
from dual
"

# Extract results from the query
db_1row admin_users_quota_big_space_query $sql


set puny_mortal_quota [ad_parameter NormalUserMaxQuota users]
set macho_mortal_quota [ad_parameter PrivelegedUserMaxQuota users]

append whole_page "
[ad_admin_header "User Webspace Quota"]

<h2>User Webspace Quota</h2>

for $first_names $last_name

<hr>

Max Quota : [util_commify_number $quota_max] bytes<br>
Quota Used: [util_commify_number $quota_used] bytes<br>

<form method=POST action=\"quota-2\">
[export_form_vars user_id]

<table>

<tr>
 <th align=left>Normal Quota (megabytes):<td>$puny_mortal_quota (default for normal users)</td>
</tr>

<tr>
 <th align=left>Priveleged Quota (megabytes):<td>$macho_mortal_quota (default for priveleged users)</td>
</tr>

<tr>
 <th align=left>Give Special Quota (megabytes):<td><input type=text name=new_quota size=3 value=\"$max_quota\"> (leave blank to give default quota)</td>
</tr>
</table>

<br>
<br>
<center>
<input type=submit value=\"Update\">
</center>

[ad_admin_footer]
"



doc_return  200 text/html $whole_page
