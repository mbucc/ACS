ad_page_contract { 
    Installs or upgrades to a new version of a package.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 9 May 2000
    @cvs-id version-install-3.tcl,v 1.6.2.6 2001/01/15 22:40:06 kevin Exp
} {
    {version_id:integer}
    cvs_p
    {sql_file_id:multiple,optional}
}

set user_id [ad_verify_and_get_user_id]

db_1row apm_package_by_version_id {
    select package_name, version_name, package_key, imported_p
    from apm_package_version_info where version_id = :version_id
}

set nanalyze_dir [ns_mktemp "[acs_root_dir]/apm-workspace/analyze-XXXXXX"]

doc_body_append "[apm_header "Install $package_name $version_name"]

<ul><li>Extracting the archive into $analyze_dir...<li>
"
doc_body_flush

set apm_file [ns_tmpnam]

#db_blob_get_file apm_retrieve_tarball "
#    select distribution_tarball from apm_package_versions where version_id = $version_id" -file $apm_file

db_with_handle db { 
    # not sure how to replicate this with new db api
    ns_ora blob_get_file $db "select distribution_tarball from apm_package_versions where version_id = $version_id" $apm_file
}

file mkdir $analyze_dir
exec sh -c "cd $analyze_dir ; [ad_parameter GzipExecutableDirectory "" /usr/local/bin]/gunzip -c $apm_file | tar xf -"

doc_body_append "Ensuring that all files are present...<li>\n"
doc_body_flush

foreach file [apm_version_file_list $version_id] {
    if { ![file isfile "$analyze_dir/$package_key/$file"] } {
	lappend missing_files $file
    }
}

if { [info exists missing_files] } {
    doc_body_append "The following files are missing:
<ul><li>[join $missing_files "\n<li>"]</ul></ul>
[ad_footer]
"
    return
}

if { $cvs_p } {
    set cvs [ad_parameter CvsPath vc]
    regsub -all {\.} [string toupper "$package_key-$version_name"] "-" release_tag

    if { $imported_p == "t" } {
	# It's already been imported - don't want to do that twice. Just pull the results
	# of the import from the database.

	set cvs_result [db_string apm_import_results {
            select cvs_import_results
            from   apm_package_versions
            where  version_id = :version_id
	}]

	doc_body_append "This version has already been imported into CVS. The results were:"
    } else {
	set root [vc_fetch_root]
	set repository [vc_fetch_repository -relative 1]
	set comment "Import of $package_name $version_name by [db_string get_email {
	select email from users where user_id = :user_id}]"

	doc_body_append "
Importing files with

<blockquote><pre>cd $analyze_dir/$package_key
cvs -d [vc_fetch_root] import \\
    -m \"$comment\" \\
    $repository/packages/$package_key APM-DIST $release_tag</pre></blockquote>
"
        doc_body_flush

        if { [catch {
	    set cvs_result [ad_chdir_and_exec "$analyze_dir/$package_key" \
		    [list $cvs -q -d [vc_fetch_root] import -m $comment $repository/packages/$package_key APM_DIST $release_tag]]
	    db_with_handle db {
		ns_ora clob_dml $db "
                    update apm_package_versions
                    set    imported_p = 't', cvs_import_results = empty_clob()
                    where  version_id = $version_id
                    returning cvs_import_results into :1
                " $cvs_result
	    }
	} error] } {
	    doc_body_append "<p><font color=red>Error: <blockquote><pre>$error</pre></blockquote></font>
[ad_footer]
"
            return
        }
	doc_body_append "Results:"
    }

    set lines [split $cvs_result "\n\r"]
    doc_body_append "</p><ul type=disc>\n"
    set n_conflicts 0
    foreach line $lines {
	if { [regexp {^([A-Z]) (.+)$} $line "" status file] } {
	    switch $status {
		U { doc_body_append "<li>$file: upgraded to new version\n" }
		N { doc_body_append "<li>$file: added\n" }
		C {
		    doc_body_append "<li><font color=red>$file: detected conflict</font>\n"
		    incr n_conflicts
		}
		I { doc_body_append "<li>$file: ignored\n" }
		L { doc_body_append "<li>$file: symbolic link\n" }
		default { doc_body_append "<li>$file: unknown status \"$status\"\n" }
	    }
	}
    }
    doc_body_append "</ul>\n"
    doc_body_flush
    if { $n_conflicts == 0 } {
	doc_body_append "</p>No conflicts have been detected, so you can use the following
command to load the package into the filesystem:

<blockquote><pre>cd [acs_root_dir]/packages
cvs -d [vc_fetch_root] update -A -d $package_key</pre></blockquote>

Once that is done, <a href=\"version-install-4?[export_url_vars version_id cvs_p sql_file_id]\">click here to proceed</a>.
</ul>
"
    } else {
	# Figure out the installed version of this package (since it's the one we're
	# going to want to join against).
	if { [db_0or1row apm_installed_version_name {
	    select version_name installed_version_name
	    from   apm_package_versions
            where  package_id = :package_id
            and    installed_p = 't'
	}] } {
	    regsub -all {\.} [string toupper "$package_key-$installed_version_name"] "-" installed_release_tag
	}
	  
        db_1row apm_package_by_version_id {
	select package_name, version_name 
	from apm_package_version_info 
	where version_id = :version_id
	}
  
	# Obtain the portion of the email address before the at sign. We'll use this in the
	# name of the directory for the merge.
	regsub {@.+} [db_string email_get {select email from users where user_id = :user_id}] "" my_email_name

	set merge_dir "[acs_root_dir]/apm-workspace/$package_key-merge-$my_email_name-[ns_fmttime [ns_time] "%Y%m%d-%H:%M"]"
	if { [file exists $merge_dir] } {
	    set counter 2
	    while { [file exists "$merge_dir-$counter"] } {
		incr counter
	    }
	    set merge_dir "$merge_dir-$counter"
	}

	set root [vc_fetch_root]
	set repository [vc_fetch_repository -relative 1]

	doc_body_append "</p>During the import, conflicts were detected in 
[ad_decode $n_conflicts 1 "one file" "$n_conflicts files"] (listed in red above).
This means that you've made local changes to the package.
In order for your changes to be propagated into the new version, you'll need to resolve
these conflicts.

<p>I'll now try to join your local modifications with changes made between versions
$installed_version_name and $version_name of the package. I'll place this in
the $merge_dir directory. Here goes:

<blockquote><pre>mkdir $merge_dir
cd $merge_dir
cvs -q -d [vc_fetch_root] checkout -d . \\
    -j $installed_release_tag -j $release_tag $repository/packages/$package_key</pre></blockquote>
"
        doc_body_flush

        file mkdir $merge_dir
        set command [list $cvs -q -d [vc_fetch_root] checkout -d . \
		-j $installed_release_tag -j $release_tag \
		$repository/packages/$package_key]

        if { [catch { set cvs_result [ad_chdir_and_exec $merge_dir $command] } error] } {
	    set cvs_result $error
	}

	doc_body_append "Result: <blockquote><pre>[ns_quotehtml $cvs_result]</pre></blockquote>

Now, go to the $merge_dir directory:

<blockquote><pre>cd $merge_dir</pre></blockquote>

and resolve any conflicts by editing the files in red above.
When you are satisfied, type 

<blockquote><pre>cd $merge_dir
cvs commit</pre></blockquote>

to commit your changes into CVS, and then

<blockquote><pre>cd [acs_root_dir]/packages
cvs -d $root update -A -d $package_key</pre></blockquote>

to load the package into the filesystem. Once that is done, you may
<a href=\"version-install-4?[export_ns_set_vars]\">click here to proceed</a>.

</ul>
</ul>

[ad_footer]
"
        return
    }
} else {
    doc_body_append "Installing files into [acs_package_root_dir $package_key]:\n<ul>"
    foreach file [apm_version_file_list $version_id] {
	set src_path "$analyze_dir/$package_key/$file"
	set dest_path "[acs_package_root_dir $package_key]/$file"

	doc_body_append "<li>$file\n"

	if { [catch {
	    if { [file exists $dest_path] } {
		set backup_path "$analyze_dir.old/$package_key/$file"
		file mkdir [file dirname $backup_path]
		file rename $dest_path $backup_path
		doc_body_append "(saved backup copy as $backup_path)\n"
	    }
	    file mkdir [file dirname $dest_path]
	    catch { file delete $dest_path }
	    file rename $src_path $dest_path
	} error] } {
	    doc_body_append "<br><font color=red><b>Error: $error</b></font>\n"
	}
	
	doc_body_flush
    }
    doc_body_append "</ul>\n"

    doc_body_append "</uL>
Next,
<a href=\"version-install-4?[export_ns_set_vars]\">proceed with data model installation</a>."
}

doc_body_append "

[ad_footer]
"

