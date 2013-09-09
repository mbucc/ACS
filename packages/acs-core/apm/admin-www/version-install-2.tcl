ad_page_contract { 
    Installs or upgrades to a new version of a package.

    @param version_id The package to be processed.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 9 May 2000
    @cvs-id version-install-2.tcl,v 1.4.2.4 2000/07/22 08:45:13 ron Exp
} {
    {version_id:integer}
    cvs_p
}
set user_id [ad_verify_and_get_user_id]

db_1row apm_package_by_version_id {
    select package_name, version_name, package_id, package_key from apm_package_version_info where version_id = :version_id
}
db_1row apm_file_count {
    select count(*) n_files from apm_package_files where version_id = :version_id
}

db_0or1row apm_version_query {
    select version_id installed_version_id, version_name installed_version_name,
           apm_version_compare(version_name, :version_name) as installed_version_compare
    from   apm_package_versions
    where  package_id = :package_id
    and    installed_p = 't'
}


doc_body_append "[apm_header -form "action=version-install-3.tcl" "Install $package_name $version_name"]

[export_form_vars cvs_p version_id]
"

if { $cvs_p } {
    regsub -all {\.} [string toupper "$package_key-$version_name"] "-" release_tag

    set root [vc_fetch_root]
    set repository [vc_fetch_repository -relative 1]
    set email_address [db_string email_by_user_id {
	select email from users where user_id = :user_id
    }]
    
    set cvs_information "
Extracting the distribution file, importing the $n_files files contained in it into CVS with
<blockquote><pre>cvs -d [vc_fetch_root] import \\
    -m \"Import of $package_name $version_name by $email_address \" \\
    $repository/packages/$package_key APM-DIST $release_tag</pre></blockquote>

You will then be responsible for using <tt>cvs update</tt> or <tt>cvs checkout</tt>
to incorporate the changes
into the filesystem, resolving any conflicts, and checking in the changes (instructions will be
provided when the import is complete)."
}
    if { [info exists installed_version_id] } { 
	if { $version_id == $installed_version_id } {
	    doc_body_append "Version $version_name of the $package_name package is already installed."
	} else {
	    set version_text [ad_decode $installed_version_compare -1 "An older" "A newer"]
	    doc_body_append "$version_text version
of the $package_name package, version $installed_version_name,
is already installed."
	}
	doc_body_append "Installation will entail:
<ul><li>
"
	if { $cvs_p } {
	    doc_body_append $cvs_information
    } else {
	doc_body_append "Extracting the distribution file ($n_files files), replacing any local modifications you have made to the installed version $installed_version_name (saving a backup copy)."
    }
	
 	doc_body_append "</p>\n"
	
	
	if { $installed_version_compare < 0 } {
	    # We are upgrading to a newer version of the package. Figure out which data-model
	    # upgrade scripts to run.
	    set script_text ""
	    set any_checked_p 0
	    # Get a list of all the data-model upgrade scripts, checking the ones we
	    # think we have to run for this upgrade.
	    
	    db_foreach apm_all_data_model_upgrade {
	    select file_id, path, apm_upgrade_for_version_p(path,
                :installed_version_name,
                :version_name) checked_p
            from  apm_package_files
            where version_id = :version_id
            and   file_type = 'data_model_upgrade'
            order by apm_upgrade_order(path)
            } {
		if { $checked_p == "t" } {
		    set any_checked_p 1
		}
		set chkbox_name [ad_decode $checked_p "t" " checked" ""]
		append script_text "
<tr>
<td><input type=checkbox name=sql_file_id value=$file_id$chkbox_name>&nbsp;</td>
<td>$path</td>
</tr>
"	   		
	    }
 	    if { [empty_string_p $script_text] } {
		# There aren't any upgrade scripts registered with the package.
		doc_body_append "<li><i>Not</i> running any data model upgrade scripts (since there are none
present in the package).\n"
	    } else {
		if { $any_checked_p } {
		    doc_body_append "<li>Running the following data model upgrade script(s) in SQL*Plus: 
(you may adjust the set of scripts to run by checking/unchecking files)\n"
            } else {
 		doc_body_append "<li>If you check any of the following upgrade script(s), running
them in SQL*Plus:\n"
            }
 	    doc_body_append "<blockquote><table cellspacing=0 cellpadding=0>$script_text</table></blockquote>\n"
	}
    } else {
 	doc_body_append "<li><i>Not</i> running any data model upgrade scripts (since we are not upgrading
										to a newer version than the one installed).\n"
    }
    doc_body_append "</ul>"
} else {
     doc_body_append "Installing this package will entail:
<ul><li>
"
    if { $cvs_p } {
	doc_body_append $cvs_information
    } else {
	doc_body_append "Unpacking the distribution file ($n_files files)."
    }
    doc_body_append "</p>\n"

    # Provide a list of data-model scripts to run (potentially).
    set script_text ""

    db_foreach apm_data_model_scripts {
	select file_id, path
	from  apm_package_files
        where version_id = :version_id
        and   file_type = 'data_model'
	order by path
    } {
	append script_text "
<tr>
<td><input type=checkbox name=sql_file_id value=$file_id checked>&nbsp;</td>
<td>$path</td>
</tr>
"
    }

    if { [empty_string_p $script_text] } {
	# There aren't any data model scripts registered with the package.
	doc_body_append "<li><i>Not</i> running any data model scripts (since there are none
present in the package).\n"
    } else {
	doc_body_append "<li>Running the following data model script(s) in SQL*Plus:
(you may adjust the set of scripts to run by checking/unchecking scripts)

<blockquote><table cellspacing=0 cellpadding=0>$script_text</table></blockquote>
"
    }
    doc_body_append "</ul>"
}

doc_body_append "<p>Are you sure you want to install $package_name $version_name?

<p><center>
<input type=button value=\"No, I wish to cancel.\" onClick=\"location.href='version-view.tcl?version_id=$version_id'\">
<spacer type=horizontal size=50>
<input type=submit value=\"Yes, I wish to proceed.\">
</center>

[ad_footer]
"
