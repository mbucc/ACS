ad_page_contract {
    Add files to a package.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id file-add-3.tcl,v 1.2.2.3 2000/07/21 03:55:41 ron Exp
} {
    {version_id:integer}
}

# Grab the property we set in the previous page, containing a list of files to add.
array set path_array [ad_get_client_property apm file_list]

# Reset the property (so we don't end up here again accidentally!)
ad_set_client_property apm file_list ""

set paths [lsort [array names path_array]]

db_transaction {
    # Register the files in batches of 50 at a time.
    for { set i 0 } { $i < [llength $paths] } { incr i $j } {
	set dml "begin\n"
	for { set j 0 } { $j < 50 && $i + $j < [llength $paths] } { incr j } {
	    set path [lindex $paths [expr { $i + $j }]]
	    append dml "    apm_register_file($version_id, '[db_quote $path]', '$path_array($path)');\n"
	}
	append dml "end;\n"
	db_dml apm_register_50_files $dml
    }
}
db_release_unused_handles
ad_returnredirect "version-files.tcl?version_id=$version_id"

