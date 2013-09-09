ad_page_contract {
    Enables user to see a .sql file without encountering the 
    AOLserver's db module magic (offering to load the SQL into a database) .

    Patched by philg at Jeff Banks's request on 12/5/99
    to close the security hole whereby a client adds extra form
    vars.

    Patched on 07/06/2000 by deison to restrict access to only
    .sql files and only files in /doc or /pageroot.

    @param url The full relative path of the file to display the source for.
    @param package_key The key of the package the file is part of.

    @creation-date 12/19/98
    @author philg@mit.edu
    @cvs-id display-sql.tcl,v 3.2.2.2 2000/09/22 01:37:25 kevin Exp
} {
    url:notnull
    {package_key ""}
}

# this is normally a password-protected page, but to be safe let's
# check the incoming URL for ".." to make sure that someone isn't 
# doing 
# https://photo.net/doc/sql/display-sql.tcl?url=/../../../../etc/passwd
# for example

if { [string match "*..*" $url] || [string match "*..*" $package_key] } {
    ad_return_error "Can't back up beyond the pageroot" "You can't use display-sql.tcl to look at files underneath the pageroot."
    return
}

if {[exists_and_not_null package_key]} {
    set safe_p [regexp {/?(.*)} $url package_url]
} else {
    set safe_p [regexp {doc/(.*)} $url doc_url]
}

if {! $safe_p} {
    ad_return_error "Invalid file location" "Can only display files in package or doc directory"
    return
}

if { [empty_string_p $package_key] } {
    ad_returnfile 200 text/plain "[ns_info pageroot]/$doc_url"
} else {
    ad_returnfile 200 text/plain "[acs_package_root_dir $package_key]/$package_url"
}
