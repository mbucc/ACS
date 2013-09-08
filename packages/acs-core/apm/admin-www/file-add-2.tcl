ad_page_contract {
    Add files to a package.

    @param version_id The identifier for the package.
    @param file_index The files to be added.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id file-add-2.tcl,v 1.3.2.3 2000/07/21 03:55:41 ron Exp
} {
    {version_id:integer}
    {file_index:multiple}
}

# Grab the property we set in the previous page, containing a list of files to add.
set file_list [ad_get_client_property apm file_list]

db_transaction {
    foreach index $file_index {
	set info [lindex $file_list $index]
	set index_path [lindex $info 0]
	set file_type [lindex $info 1]
	db_dml apm_add_file {
            insert into apm_package_files(file_id, version_id, path, file_type)
            values(apm_package_file_id_seq.nextval, :version_id, :index_path, :file_type)
	}
    }

    # Reset the property (so we don't end up here again accidentally!)
    ad_set_client_property apm file_list ""
}

apm_install_package_spec $version_id

db_release_unused_handles
ad_returnredirect "version-files.tcl?version_id=$version_id"

