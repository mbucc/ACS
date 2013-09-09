ad_page_contract {
    Deinstalls a package.
    @author kevin@caltech.edu
    @date 17 May 2000
    @cvs-id version-deinstall.tcl,v 1.4.2.4 2000/07/21 03:55:45 ron Exp
} {
    version_id:integer
}

set user_id [ad_get_user_id]
db_1row apm_package_info_by_version_id {
    select package_key, package_name, version_name from apm_package_version_info where version_id = :version_id
}

# Obtain the portion of the email address before the at sign. We'll use this in the name of
# the backup directory for the package.
regsub {@.+} [db_string apm_email {
    select email from users where user_id = :user_id
}] "" my_email_name

set backup_dir "[acs_root_dir]/apm-workspace/$package_key-removed-$my_email_name-[ns_fmttime [ns_time] "%Y%m%d-%H:%M:%S"]"

doc_body_append "[apm_header [list "version-view.tcl?version_id=$version_id" "$package_name $version_name"] "Deinstall"]

<ul>
<li>Moving <tt>packages/$package_key</tt> to $backup_dir... "

if { [catch { file rename "[acs_root_dir]/packages/$package_key" $backup_dir } error] } {
    doc_body_append "<font color=red>[ns_quotehtml $error]</font>"
} else {
    doc_body_append "moved."
}

db_dml apm_uninstall_record {
    update apm_package_versions
    set    installed_p = 'f', enabled_p = 'f', imported_p = 'f', cvs_import_results = ''
    where version_id = :version_id
}

doc_body_append "<li>Package marked as deinstalled.
</ul>

[ad_footer]
"

