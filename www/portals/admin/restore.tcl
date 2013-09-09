# www/portals/admin/restore.tcl

ad_page_contract {
    This presents a list of old versions of a given portal_table
    (table_id) from portal_tables_audit allows user to view a given
    version and maybe make it the active version. 

    @author Aure aure@arsdigita.com 
    @author Dave Hill dh@arsdigita.com
    @param table_id: the table to restore.
    @cvs-id restore.tcl,v 3.3.2.7 2000/09/22 01:39:04 kevin Exp
} {
    {table_id:naturalnum,notnull}
}

# --------------------------------------------
# verify the user
set user_id [ad_verify_and_get_user_id]

if  {![info exists group_id]} {
    set group_id ""
}
portal_check_administrator_maybe_redirect $user_id $group_id
#---------------------------------------------

# get current table name
set current_table_name [portal_adp_parse \
   [db_string portals_admin_current_table_name " 
    select table_name 
    from   portal_tables 
    where  table_id = :table_id" -default "" ]]

if {[empty_string_p $current_table_name]} {
    set current_table_name "deleted table"
}

# get portal_tables_audit.modified_date 
set qry "select to_char(modified_date,' DD/MM/YY HH:MI AM') as modified_date, 
           table_name, 
           audit_id, 
           first_names||' '||last_name as username
    from   portal_tables_audit, users
    where  table_id = :table_id
    and    creation_user = user_id (+)
    order by modified_date desc"

set modified_list ""
set old_version_count 0

db_foreach portals_admin_table_list $qry {
    # modified_date, table_name, audit_id
    append modified_list "<tr><td><font size=-1>$modified_date</font></td><td>$username &nbsp;</td><td>[portal_adp_parse $table_name] &nbsp;</td><td><a href=restore-2?[export_url_vars audit_id]>View</a></td></tr> \n"
    incr old_version_count
}

if {$old_version_count == 0} {
    set modified_list "<tr><td colspan=4>There are no old versions of this portal table.</td></tr>"
}

#------------------------------------------------------
# serve the page

# get system display parameters
portal_display_info

set page_content "
[portal_admin_header "Versions of $current_table_name"]
[ad_context_bar [list /portals/ "Portals"] [list index "Administration" ]  "Versions"]
<hr>
Select a table version you would like to view:
<p>
$begin_table
<tr>
$header_td MODIFIED DATE</td>
$header_td MODIFIER</td>
$header_td TITLE </td>
$header_td </td>
</tr>
$modified_list
$end_table
[portal_admin_footer]"

# done with the database


doc_return  200 text/html $page_content

