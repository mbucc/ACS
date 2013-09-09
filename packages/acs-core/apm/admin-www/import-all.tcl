ad_page_contract {
    Brings all non-locally-generated packages under source control.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id import-all.tcl,v 1.4.2.2 2000/07/21 03:55:42 ron Exp
} {
}

doc_body_append "[apm_header -form "action=import-all-2 method=post" "Import All"]

"
doc_body_flush

set checkboxes ""

db_foreach apm_get_all_non_cvs_packages {
    select package_key, package_name, version_name
    from   apm_package_version_info
    where  installed_p = 't'
    and    imported_p = 'f'
    and    distribution_url is not null
    order by package_key
} {
    append checkboxes "<input type=checkbox name=package_key value=\"$package_key\"> $package_name $version_name<br>"
}

if { [empty_string_p $checkboxes] } {
    doc_body_append "All downloaded packages are already under source control."
} else {
    doc_body_append "<blockquote>
$checkboxes
</blockquote>

<center><input type=submit value=\"CVS Import Checked Packages\"></center>
"
}

doc_body_append [ad_footer]

