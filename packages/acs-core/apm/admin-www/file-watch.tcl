ad_page_contract {
    Schedules a file to be watched.


    @param file_id The id of the file to watch.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id file-watch.tcl,v 1.3.2.6 2000/07/21 03:55:42 ron Exp
} {
    file_id:integer
}

db_1row apm_get_file_to_watch {
    select p.package_key, p.package_url, v.package_name, v.version_name, v.package_id, v.installed_p, v.
    distribution_url, f.path, f.version_id
    from   apm_packages p, apm_package_versions v, apm_package_files f
    where  f.file_id = :file_id
    and    f.version_id = v.version_id
    and    v.package_id = p.package_id
}


doc_body_append "[apm_header -form "method=post action=\"file-add-2.tcl\"" [list "version-view.tcl?version_id=$version_id" "$package_name $version_name"] [list "version-files.tcl?version_id=$version_id" "Files"] "Watch file"]

"

db_1row apm_get_path_from_file_id {
    select path from apm_package_files where file_id = :file_id
}

nsv_set apm_reload_watch "packages/$package_key/$path" 1
doc_body_append "Marking the following file to be watched:<ul><li>$path</ul>

<a href=\"version-files.tcl?version_id=$version_id\">Return to the list of files for $package_name $version_name</a><br>
<a href=\"\">Return to the Package Manager</a>

[ad_footer]
"

