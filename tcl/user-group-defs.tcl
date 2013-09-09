# /tcl/user-group-defs.tcl

ad_library {
    User group related functions
    
    @author Tarik Alatovic [tarik@arsdigita.com]
    @date 12/19/99
    @cvs-id user-group-defs.tcl,v 3.12.2.14 2000/09/22 01:34:05 kevin Exp
}

proc_doc ug_url {} "returns groups url directory: /[ad_parameter GroupsDirectory ug]" {
    return /[ad_parameter GroupsDirectory ug]
}

proc_doc ug_admin_url {} "returns groups admin url directory: /[ad_parameter GroupsDirectory ug]/[ad_parameter GroupsAdminDirectory ug]" {
    return /[ad_parameter GroupsDirectory ug]/[ad_parameter GroupsAdminDirectory ug]
}

proc_doc ug_parse_url { url_string } {

    this procedure takes url in the form /A/B/C and returns tcl list
    whose members are A, B and C. if the last element of this tcl list
    is /, then this / will be added as the last element in the list
    (e.g. /A/B/C/ will have elements A, B, C and /). if url_string is
    empty, procedure will return an empty list

} {
    set url_list [list]
    
    set url_string_length [string length $url_string]    
    if { $url_string_length == 0 } {
	return $url_list
    }

    set last_url_char [string range $url_string [expr $url_string_length - 1] [expr $url_string_length - 1]]

    if { [string compare $last_url_char /]==0 } {
	set include_final_slash_p 1
	set url_without_initial_and_final_slash [string range $url_string 1 [expr $url_string_length - 2]]
    } else {
	set include_final_slash_p 0
	set url_without_initial_and_final_slash [string range $url_string 1 [expr $url_string_length - 1]]
    }
    
    set url_list [split $url_without_initial_and_final_slash /]
    if { $include_final_slash_p } {
	lappend url_list /
    }

    return $url_list
}

proc_doc url_from_list { url_list } "given url list as described in ug_parse_url this procedure puts back the url from the list. thus, if list contains elements A, B and C, this procedure will return A/B/C. if list contains elements A, B, C and / than this procedure will return A/B/C/" {
    set url_list_length [llength $url_list]

    if { $url_list_length < 1 } {
	return ""
    } 

    set first_url_element [lindex $url_list 0]
    if { [string compare $first_url_element /]==0 } {
	return "/"
    }

    set last_url_element [lindex $url_list [expr $url_list_length - 1]]
    if { [string compare $last_url_element /]==0 } {
	return "[join [lrange $url_list 0 [expr $url_list_length - 2]] /]/"
    } else {
	return "[join [lrange $url_list 0 [expr $url_list_length - 1]] /]"
    }
}

ns_share -init { set ug_initialization_done 0 } ug_initialization_done  
          
if { !$ug_initialization_done } {
    set ug_initialization_done 1
    ad_schedule_proc -once t 1 ug_init_serve_group_pages
}

# initialize ug_serve_group_pages
proc ug_init_serve_group_pages {} {
    
    ad_register_proc GET  [ug_url] ug_serve_group_pages
    ad_register_proc POST [ug_url] ug_serve_group_pages

    set sql_qry "
    select '/' || group_type as group_type_url from user_group_types 
    where has_virtual_directory_p='t'"
    
    db_foreach register_procs $sql_qry {
	ad_register_proc GET  $group_type_url ug_serve_group_pages
	ad_register_proc POST $group_type_url ug_serve_group_pages
    }
}

proc ug_source { info } {
    set action [lindex $info 0]
    set predicate [lindex $info 1]

    if { $action == "redirect" } {
	ad_returnredirect $predicate
    } else {
	set file $predicate
	set extension [file extension $file]
	if { $extension == ".tcl" } {
	    # Tcl file - use source.
	    uplevel [list source $file]
	} elseif { $extension == ".adp" } {
	    # ADP file - parse and return the ADP.
	    set adp [ns_adp_parse -file $file]
	    set content_type [ns_set iget [ns_conn outputheaders] "content-type"]
	    if { [empty_string_p $content_type] } {
		set content_type "text/html"
	    }
	    uplevel [list doc_return  200 $content_type $adp]
	} else {
	    # Some other random kind of find - return it.
	    ad_returnfile 200 [ns_guesstype $file] $file
	}
    }
}

proc ug_file_to_source { dir name } {
    set path [ns_url2file "$dir/$name"]
    if { [file isdirectory $path] } {
	if { ![regexp {/$} $path] } {
	    # Directory name with no trailing slash. Redirect to the same URL but with
	    # a trailing slash.

	    set url "[ns_conn url]/"
	    if { [ns_conn query] != "" } {
		append url "?[ns_conn query]"
	    }
	    return [list redirect $url]
	} else {
	    # Directory name with trailing slash. Search for an index.* file.
	    append path "index"
	}
    }

    if { ![file isfile $path] } {
	# It doesn't exist - glob for the right file.
	if { ![file isdirectory [file dirname $path]] } {
	    return ""
	}

	# Sub out funky characters in the pathname, so the user can't request
	# http://www.arsdigita.com/*/index (causing a potentially expensive glob
	# and bypassing registered procedures)!
	regsub -all {[^0-9a-zA-Z_/.]} $path {\\&} path_glob
	
	# Grab a list of all available files with extensions.
	set files [glob -nocomplain "$path_glob.*"]

	# Search for files in the order specified in ExtensionPrecedence.
	set precedence [ad_parameter "ExtensionPrecedence" "abstract-url" "tcl"]
	foreach extension [split [string trim $precedence] ","] {
	    if { [lsearch $files "$path.$extension"] != -1 } {
		return [list file "$path.$extension"]
	    }
	}

	# None of the extensions from ExtensionPrecedence were found - just pick
	# the first in alphabetical order.
	if { ![info exists ad_conn(file)] && [llength $files] > 0 } {
	    set files [lsort $files]
	    return [list file [lindex $files 0]]
	}

	return ""
    }

    return [list file $path]
}

proc ug_serve_group_pages { conn context } {
    set url_stub [ns_conn url]
    set url_list [ug_parse_url $url_stub]
    set url_list_length [llength $url_list]

    if { $url_list_length < 1 } {
	# this should never happen, so return an error to indicate that something went wrong
	ad_return_error "Error in serving group pages" "Error in serving group pages. If the problem persists, please contact the system administrator."
	ns_log Error "/tcl/user-group-defs.tcl: function ug_serve_group_pages: got url_list_length less than 1"
	return
    }


    # when we set scope and group_id before sourcing the tcl page, ad_page_contract
    # will complain if they are also present as url or form variables.  so we set
    # this flag to prevent the scoping code from generating links that contain
    # those variables.  luke@arsdigita.com 2000-10-06
    set do_not_export_group_scope_vars 1

        

    set url_first_element [lindex $url_list 0]
    if { [string compare $url_first_element [ad_parameter GroupsDirectory ug]]== 0 } {
	# we are serving /groups directory, so set the appropriate directories where files are located
	set groups_public_dir /groups
	set groups_admin_dir /groups/admin
	set group_public_dir /groups/group
	set group_admin_dir /groups/admin/group

	set group_public_root_url /[ad_parameter GroupsDirectory ug]
	set group_admin_root_url /[ad_parameter GroupsDirectory ug]/[ad_parameter GroupsAdminDirectory ug]

	# this flag indicates that page was accessed through generic /groups pages as opposed to /$group_type pages
	set group_type_url_p 0

	# just initialize group_type, group_type_pretty_name and group_type_pretty_plural to empty string
#	set group_type ""
#	set group_type_pretty_name ""
#	set group_type_pretty_plural ""

    } else {
	# let's check if we are dealing with one of the group type virtual directories
	set sql_qry "
	select group_type, pretty_name as group_type_pretty_name, pretty_plural as group_type_pretty_plural,
               group_type_public_directory, group_type_admin_directory, group_public_directory, group_admin_directory
	from user_group_types 
	where has_virtual_directory_p='t'
	and group_type=:url_first_element"
	if { ![db_0or1row "ug_group_virtual_dirs" $sql_qry] } { 
	    # this should never happen since this procedure is called only with url's 
	    # registered with ad_register_proc to handle group type directories
	    ad_return_error "Error in serving group pages" "Error in serving group pages. If the problem persists, please contact the system administrator."
	    ns_log Error "/tcl/user-group-defs.tcl: function ug_serve_group_pages: first element in url_list is not \[ad_parameter GroupsDirectory ug\]"
	    return
	}

	set groups_public_dir [ad_decode $group_type_public_directory "" /groups $group_type_public_directory]
	set groups_admin_dir [ad_decode $group_type_admin_directory "" /groups/admin $group_type_admin_directory]
	set group_public_dir [ad_decode $group_public_directory "" /groups/group $group_public_directory]
	set group_admin_dir [ad_decode $group_admin_directory "" /groups/admin/group $group_admin_directory]

	set group_public_root_url /[ad_urlencode $group_type]
	set group_admin_root_url /[ad_urlencode $group_type]/[ad_parameter GroupsAdminDirectory ug]

	# this flag indicates that page was accessed through /$group_type pages as opposed to generic /groups pages
	set group_type_url_p 1
    }
 
    if { $url_list_length==1 } {
	# this means that url is /groups or /$group_type
	# than just redirect url to the directory /groups/ or /$group_type/
	# note that this is necessary in order to establish the correct default directory
	ad_returnredirect "$url_stub/"
	return
    }

    set url_second_element [lindex $url_list 1]
    if { [string compare $url_second_element /]==0 } {
	# this is groups public directory, so serve the appropriate groups index page
	db_release_unused_handles
	ug_export_to_form groups_public_dir group_type_url_p group_type group_type_pretty_name group_type_pretty_plural group_public_root_url group_admin_root_url
	ug_source_with_env [list file [ns_info pageroot]$groups_public_dir/index.tcl]
	return
    }

    if { [string compare $url_second_element [ad_parameter GroupsAdminDirectory ug]]==0 } {
	#these are /groups/admin pages
	if { $url_list_length==2 } {
	    # this is to set correct default directory
	    ad_returnredirect "$url_stub/"
	    return
	}
	
	# THIS PORTION OF THIS PROC SERVES THE ADMIN PAGES
	
	if { $url_list_length < 3 } {
	    # this should never happen, so return an error to indicate that something went wrong
	    ad_return_error "Error" "Error in serving group pages. If the problem persists, please contact the system administrator."
	    ns_log Error "/tcl/user-group-defs.tcl: function ug_serve_admin_group_pages: got url_list_length less than 3"
	    return
	}
	
	set url_third_element [lindex $url_list 2]
	if { [string compare $url_third_element /]==0 } {
	    # this is /groups/admin/ so serve the groups admin index page
	    db_release_unused_handles
	    ug_export_to_form group_type_url_p group_type group_type_pretty_name group_type_pretty_plural group_public_root_url group_admin_root_url
	    ug_source_with_env [list file [ns_info pageroot]$groups_admin_dir/index.tcl]
	    return
	}
	
	# appending groups listing page link to the context bar list
	lappend group_context_bar_list [list "$group_admin_root_url/" "Groups Admin"]
	
	set file_to_source [ug_file_to_source $groups_admin_dir $url_third_element]
	if { $file_to_source != "" } {
	    db_release_unused_handles
	    ug_export_to_form groups_admin_dir group_type_url_p group_type group_type_pretty_name group_type_pretty_plural group_public_root_url group_admin_root_url
	    ug_source_with_env $file_to_source
	    return
	}

	set sql_qry "
	select group_id, short_name, admin_email, group_name
	from user_groups
	where short_name=:url_third_element"
	if { ![db_0or1row "ug_page_existence_p" $sql_qry] } {	       
	    ug_page_does_not_exist [url_from_list [lrange $url_list 2 [expr $url_list_length - 1]]] $group_admin_root_url/ "Go to groups administration main page"
	    return
	} 
	
	# all scope related variables are stored in this set and passed down to the module files
	# elements of group_vars_set are group_id, group_short_name, group_name, group_admin_email, 
	# group_public_root_url, group_admin_root_url, group_context_bar_list and group_navbar_list
	set group_vars_set [ns_set create]
	
	ns_set put $group_vars_set group_id $group_id
	ns_set put $group_vars_set group_short_name $short_name
	ns_set put $group_vars_set group_name $group_name
	ns_set put $group_vars_set group_admin_email $admin_email
	ns_set put $group_vars_set group_public_url $group_public_root_url/[ad_urlencode $short_name]
	ns_set put $group_vars_set group_admin_url $group_admin_root_url/[ad_urlencode $short_name]
	ns_set put $group_vars_set group_public_root_url $group_public_root_url
	ns_set put $group_vars_set group_admin_root_url $group_admin_root_url
	ns_set put $group_vars_set group_type_url_p $group_type_url_p
	ns_set put $group_vars_set group_context_bar_list $group_context_bar_list
	ns_set put $group_vars_set group_navbar_list [list]
	
	set scope group
	
	if { $url_list_length==3 } {
	    # this means that url is $group_admin_root_url/short_name
	    # than just redirect url to the directory $group_admin_root_url/short_name/
	    # note that this is necessary in order to establish the correct default directory
	    ad_returnredirect "$url_stub/"
	    return
	}
	
	set url_fourth_element [lindex $url_list 3]
	if { [string compare $url_fourth_element /]==0 } {
	    # this is /groups/admin/short_name/ so serve the admin index page of that group
	    db_release_unused_handles
	    ug_source_with_env [list file [ns_info pageroot]$group_admin_dir/index.tcl ] { scope group_id group_vars_set do_not_export_group_scope_vars }
	    return
	}
	
	# appending groups listing page link to the context bar list
	lappend group_context_bar_list [list "$group_admin_root_url/[ad_urlencode $short_name]/" "One Group Admin"]
	ns_set update $group_vars_set group_context_bar_list $group_context_bar_list

	set file_to_source [ug_file_to_source $group_admin_dir $url_fourth_element]
	if { $file_to_source != "" } {
	    db_release_unused_handles
	    ug_source_with_env $file_to_source { scope group_id group_vars_set do_not_export_group_scope_vars }
	    return
	}
	
	# in the query below, notice that we only have content section administration for 
	# sections of section_type admin, system and custom
	set sql_qry "select section_type, section_key, module_key
	from content_sections
	where scope='group' and group_id=$group_id
	and (section_type='admin' or section_type='system' or section_type='custom')
	and section_key=:url_fourth_element
	"

	if { ![db_0or1row "ug_content_section_administration_p" $sql_qry] } {
	    ug_group_page_does_not_exist $group_id $group_name $admin_email \
		[url_from_list [lrange $url_list 3 [expr $url_list_length - 1]]] \
		$group_admin_root_url/[ad_urlencode $short_name]/ "Go to $group_name main administration page"
	    return
	} 
		
	if { $url_list_length==4 } {
	    # this means that url is $group_admin_root_url/short_name/section_key
	    # than just redirect url to the directory $group_admin_root_url/short_name/section_key/
	    # note that this is necessary in order to establish the correct default directory
	    ad_returnredirect "$url_stub/"
	    return
	}
	
	set url_fifth_element [lindex $url_list 4]

	if { ([string compare $section_type admin]==0) || ([string compare $section_type system]==0) } {
	    set sql_qry "select admin_directory from acs_modules where module_key=:module_key"
	    set admin_dir [db_string "ug_admin_directory" $sql_qry]
	} else {
	    # this is the case when section_type=custom
	    set admin_dir [db_string "ug_admin_directory_custom_sections" "
	    select admin_directory from acs_modules where module_key='custom-sections'"]
	}
	
	if { [string compare $url_fifth_element /]==0 } {
	    # this is /groups/admin/short_name/section_key/ so serve the admin index page of that section
	    # if it exists (otherwise announce that page does not exist)
	    cd [ns_info pageroot]$admin_dir
	    if { [file exists index.tcl] } {
		db_release_unused_handles
		ug_source_with_env [list file [ns_info pageroot]$admin_dir/index.tcl] { scope group_id group_vars_set do_not_export_group_scope_vars }
		return
	    }
	    
	    # index.tcl does not exist for this admin directory, so return page does not exist message
	    ug_group_page_does_not_exist $group_id $group_name $admin_email \
		    [url_from_list [lrange $url_list 3 [expr $url_list_length - 1]]] \
		    $group_admin_root_url/[ad_urlencode $short_name]/ "Go to $group_name main administration page"
	    return
	}
	
	set file_to_source [ug_file_to_source $admin_dir $url_fifth_element]
	if { $file_to_source != "" } {
	    db_release_unused_handles
	    ug_source_with_env $file_to_source { scope group_id group_vars_set do_not_export_group_scope_vars }
	    return
	}
	
	# reaching this point code means that requested page does not exist
	
	ug_group_page_does_not_exist $group_id $group_name $admin_email \
		[url_from_list [lrange $url_list 3 [expr $url_list_length - 1]]] \
		$group_admin_root_url/[ad_urlencode $short_name]/ "Go to $group_name main administration page"
	return
	
	# END OF CODE SERVING ADMIN PAGES
    }
    
    # appending groups listing page link to the context bar list
    if { [string compare $url_first_element [ad_parameter GroupsDirectory ug]]== 0 } {
	lappend group_context_bar_list [list "$group_public_root_url/" Groups]
    } else {
	lappend group_context_bar_list [list "$group_public_root_url/" $group_type_pretty_plural]
    }

    set file_to_source [ug_file_to_source $groups_public_dir $url_second_element]
    if { $file_to_source != "" } {
	db_release_unused_handles
	ug_export_to_form group_type_url_p group_type group_type_pretty_name group_type_pretty_plural group_public_root_url group_admin_root_url group_vars_set
	ug_source_with_env $file_to_source
	return
    }

    set sql_qry "
    select group_id, short_name, group_name, admin_email
    from user_groups
    where short_name=:url_second_element
    "

    if { ![db_0or1row "ug_url_second_element" $sql_qry] } {
	ug_page_does_not_exist [url_from_list [lrange $url_list 1 [expr $url_list_length - 1]]] $group_public_root_url/ "Go to groups main page"
	return
    } 
        
    # all scope related variables are stored in this set and passed down to the module files
    # elements of group_vars_set are group_id, group_short_name, group_name, group_admin_email, 
    # group_public_root_url, group_admin_root_url, group_public_url, group_admin_url,
    # group_context_bar_list and group_navbar_list
    set group_vars_set [ns_set create]

    ns_set put $group_vars_set group_id $group_id
    ns_set put $group_vars_set group_short_name $short_name
    ns_set put $group_vars_set group_name $group_name
    ns_set put $group_vars_set group_admin_email $admin_email
    ns_set put $group_vars_set group_public_url $group_public_root_url/[ad_urlencode $short_name]
    ns_set put $group_vars_set group_admin_url $group_admin_root_url/[ad_urlencode $short_name]
    ns_set put $group_vars_set group_public_root_url $group_public_root_url
    ns_set put $group_vars_set group_admin_root_url $group_admin_root_url
    ns_set put $group_vars_set group_type_url_p $group_type_url_p
    ns_set put $group_vars_set group_context_bar_list $group_context_bar_list
    ns_set put $group_vars_set group_navbar_list [list]

    set scope group

    if { $url_list_length==2 } {
	# this means that url is $group_public_root_url/short_name
	# than just redirect url to the directory $group_public_root_url/short_name/
	# note that this is necessary in order to establish the correct default directory
	ad_returnredirect "$url_stub/"
	return
    }

    set url_third_element [lindex $url_list 2]
    
    if { [string compare $url_third_element /]==0 } {
	# this is /groups/short_name/ so serve the index page of that group
	db_release_unused_handles
	
	ug_source_with_env [list file  [ns_info pageroot]$group_public_dir/index.tcl] { scope group_id group_vars_set do_not_export_group_scope_vars }
	return
    }

    # appending group index page link to the context bar list
    if { [string compare $url_first_element [ad_parameter GroupsDirectory ug]]== 0 } {
	lappend group_context_bar_list [list "$group_public_root_url/[ad_urlencode $short_name]/" "One Group"]
    } else {
	lappend group_context_bar_list [list "$group_public_root_url/[ad_urlencode $short_name]/" "One $group_type_pretty_name"]
    }
    ns_set update $group_vars_set group_context_bar_list $group_context_bar_list

    set file_to_source [ug_file_to_source $group_public_dir $url_third_element]
    if { $file_to_source != "" } {
	db_release_unused_handles
	ug_source_with_env $file_to_source { scope group_id group_vars_set do_not_export_group_scope_vars }
	return
    }

    set sql_qry "
    select section_id, scope, section_type, section_pretty_name, section_key, 
           section_url_stub, module_key, requires_registration_p, visibility
    from content_sections
    where scope='group' and group_id=:group_id
    and section_key=:url_third_element
    and section_type!='admin'
    and enabled_p='t'
    "
    if { ![db_0or1row "ug_group_sections" $sql_qry] } {
	ug_group_page_does_not_exist $group_id $group_name $admin_email \
		[url_from_list [lrange $url_list 2 [expr $url_list_length - 1]]] \
		$group_public_root_url/[ad_urlencode $short_name]/ "Go to $group_name main page"
	return
    } 

    # if section is custom or static, let's see if the user is allowed to see that section 
    # this is determined using requires_registration_p and visibility
    if { $section_type=="static" || $section_type=="custom" } {
	if { $visibility=="private" } {
	    ad_scope_authorize group none group_member none 
	} else {
	    if { $requires_registration_p=="t" } {
		ad_scope_authorize group none registered none 
	    }
	}
    }
    
    if { $url_list_length==3 } {
	# this means that url is $group_public_root_url/short_name/section_key
	# than just redirect url to the directory $group_public_root_url/short_name/section_key/
	# note that this is necessary in order to establish the correct default directory
	ad_returnredirect "$url_stub/"
	return
    }

    set url_fourth_element [lindex $url_list 3]

    if { [string compare $section_type system]==0 || [string compare $section_type custom]==0 } {
	if { [string compare $section_type custom]==0 } {
	    set module_key "custom-sections"
	}
	set public_dir [db_string "ug_acs_public_directory" "
	select public_directory from acs_modules where module_key=:module_key"]
    } 

    # let's figure out the navigation bars 
    set sql_qry "
    select cs.section_key as to_section_key,
           cs.section_pretty_name as to_section_pretty_name
    from content_section_links csl, content_sections cs
    where csl.from_section_id=:section_id
    and csl.to_section_id=cs.section_id
    order by cs.section_key"

    set group_navbar_list [list]
    db_foreach ug_navigation_bars $sql_qry {
	lappend group_navbar_list \
		[list "$group_public_root_url/[ad_urlencode $short_name]/[ad_urlencode $to_section_key]/" $to_section_pretty_name]
    }
    ns_set update $group_vars_set group_navbar_list $group_navbar_list
    
    
    if { [string compare $url_fourth_element /]==0 } {
	# this is /groups/short_name/section_key/

	# it this is the system section serve the index page of that section if it exists
	# (otherwise announce that page does not exist)
	if { [string compare $section_type system]==0 } {
	    cd [ns_info pageroot]$public_dir
	    if { [file exists index.tcl] } {
		db_release_unused_handles
		ug_source_with_env [list file [ns_info pageroot]$public_dir/index.tcl] { scope group_id group_vars_set do_not_export_group_scope_vars }
		return
	    }

	    # index.tcl does not exist for this system section, so return page does not exist message
	    ug_group_page_does_not_exist $group_id $group_name $admin_email \
		    [url_from_list [lrange $url_list 2 [expr $url_list_length - 1]]] \
		    $group_public_root_url/[ad_urlencode $short_name]/ "Go to $group_name main page"
	    return
	}

	if { [string compare $section_type custom]==0 } {
	    # serve custom section index page
	    db_release_unused_handles
	    ug_export_to_form section_id section_key
	    ug_source_with_env [list file [ns_info pageroot]$public_dir/index.tcl] { scope group_id group_vars_set do_not_export_group_scope_vars }
	    return
	}

	if { [string compare $section_type static]==0 } {
	    # this is just a static page
	    # if the page is adp, tcl, htm or html page than just parse it and display the content
	    # otherwise redirect to the url_stub (this way we can kind of handle url directories and
	    # images being used as content sections)

	    set file_extension [file extension $section_url_stub]
	    if { [empty_string_p $file_extension] } {
		ad_returnredirect $section_url_stub		
		return
	    } 

	    if { [string compare $file_extension .tcl]==0 } {
		db_release_unused_handles
		ug_export_to_form section_url_stub
		ug_source_with_env [list file [ns_info pageroot]$section_url_stub] { scope group_id group_vars_set do_not_export_group_scope_vars }
		return
	    }
	    if { [string compare $file_extension .adp]==0 } {
		db_release_unused_handles
		ns_adp_parse -file [ns_info pageroot]$section_url_stub
		return
	    }

	    if { ([string compare $file_extension .htm]==0) || \
		    ([string compare $file_extension .html]==0) } {
		set html_page [ns_httpget [ad_parameter SystemURL]$section_url_stub]
		doc_return  200 text/html $html_page
		return
	    }

	    # unrecognized extension, could be image or something else, so just redirect to that url location
	    ad_returnredirect $section_url_stub
	    return
	}
    }

    # static sections cannot have files associated with them, so for sections of section_type static, reaching this point
    # in code means that requested page does not exist
    if { [string compare $section_type static]==0 } {
	ug_group_page_does_not_exist $group_id $group_name $admin_email \
		[url_from_list [lrange $url_list 2 [expr $url_list_length - 1]]] \
		$group_public_root_url/[ad_urlencode $short_name]/ "Go to $group_name main page"
	return
    }

    # appending group section index page link to the context bar list
    if { [string compare $section_type custom]==0 } {
	lappend group_context_bar_list [list "$group_public_root_url/[ad_urlencode $short_name]/[ad_urlencode $section_key]/" $section_pretty_name]
	ns_set update $group_vars_set group_context_bar_list $group_context_bar_list
    }

    # now we still have to deal with the sytem section and custom sections assocated files

    if { [string compare $section_type system]==0 } {
	set file_to_source [ug_file_to_source $public_dir $url_fourth_element]
	if { $file_to_source != "" } {
	    db_release_unused_handles
	    ug_export_to_form group_public_dir 
	    ug_source_with_env $file_to_source { scope group_id group_vars_set do_not_export_group_scope_vars }
	    return
	}
    }

    set sql_qry "
    select content_file_id, file_type
    from content_files
    where section_id=$section_id
    and file_name= :url_fourth_element"

    if { ![db_0or1row "ug_fourth_element" $sql_qry]} {
	# unrecognized file, so return the page not exists
	ug_group_page_does_not_exist $group_id $group_name $admin_email \
		[url_from_list [lrange $url_list 2 [expr $url_list_length - 1]]] \
		$group_public_root_url/[ad_urlencode $short_name]/ "Go to $group_name main page"
	return
    }

    # so, we have identified the file, go ahead and serve the file
    db_release_unused_handles
    if { [string compare $file_type "text/html"]==0 } {
	set file_to_source [list file [ns_info pageroot]/custom-sections/file/index.tcl]
    } else { 
	set file_to_source [list file [ns_info pageroot]/custom-sections/file/get-binary-file.tcl]
    }
    ug_export_to_form content_file_id
    ug_source_with_env $file_to_source { scope group_id group_vars_set do_not_export_group_scope_vars }
    return
}

proc_doc ug_page_does_not_exist { page_name link_target link_name } "this procedures return message to the user that a page does not exist. it uses ad_header and ad_footer.  user is redirected to appropriate page with name link_name and link target link_target" {

    set page_title "Page does not exist"
	
    doc_return  200 text/html "
    [ad_header $page_title]
    <h2>$page_title</h2>
    <hr>

    <blockquote>
    <h4>Page $page_name does not exist.</h4>
    <h4><a href=\"$link_target\">$link_name</a></h4>
    </blockquote>

    [ad_footer]
    "
}

proc_doc ug_group_page_does_not_exist { group_id group_name group_admin_email page_name link_target link_name } "this procedures return message to the user that a page does not exist. the page display is customized for group pages and uses ug_header and ug_footer. user is redirected to appropriate page with name link_name and link target link_target" {

    set page_title "Page does not exist"
	
    doc_return  200 text/html "
    [ug_header $page_title $group_id]
    [ug_page_title $page_title $group_id $group_name]
    <hr>

    <blockquote>
    <h4>Page $page_name does not exist.</h4>
    <h4><a href=\"$link_target\">$link_name</a></h4>
    </blockquote>

    [ug_footer $group_admin_email]
    "
}

proc_doc ug_header { page_title group_id } "Header for group user pages. It needs group id in order to get the groups cascaded style sheet information." {
    
    set sql_qry  "select 1 as one from content_sections where scope='group' and group_id=:group_id and module_key='display'"
    if { [db_0or1row "content_sections_p" $sql_qry] } {
	set css_enabled_p 1
    } else {
	set css_enabled_p 0
    }
    set scope group
    
    if { $css_enabled_p } {
	return "
	<html>
	<head>
	<title>$page_title</title>
	<LINK REL=stylesheet TYPE=\"text/css\" HREF=\"/display/get-simple-css.tcl?[export_url_vars scope group_id]\">
	</head>
	<body>
	"
    } else {
	return [ad_header $page_title ""]
    }
}

proc_doc ug_footer { admin_email } "
Signs pages with group administrator email.  Group administrator is person who administer groups content. " {
    append result "
    <hr>
    "
    
    if { ![empty_string_p $admin_email] } {
	append result "
	<a href=\"mailto:$admin_email\"><address>$admin_email</address></a>
	"
    } else {
	append result "
	<a href=\"mailto:[ad_system_owner]\"><address>[ad_system_owner]</address></a>
	"
    }

    append result "
    </body>
    </html>
    "

    return $result
}

proc_doc ug_admin_header { page_title group_id } "Header for group admin pages. Neeeds group id in order to get the groups cascaded style sheet information." {
    set sql_qry "select 1 as one from content_sections where scope='group' and group_id=:group_id and module_key='display'"
    if { ![db_0or1row "ug_group_admin_pages" $sql_qry] } {
	set css_enabled_p 0
    } else { 
	set css_enabled_p 1
    }

    set scope group
    
    if { $css_enabled_p } {
	return "
	<html>
	<head>
	<title>$page_title</title>
	<LINK REL=stylesheet TYPE=\"text/css\" HREF=\"/display/get-simple-css.tcl?[export_url_vars scope group_id]\">
	</head>
	<body>
	"
    } else {
	return [ad_header $page_title]
    }
}

proc_doc ug_admin_footer {} "This pages are signed by the SystemOwner, because group administrators should be able to complain to programmer who can fix the bugs." {
    return "
    <hr>
    <a href=\"mailto:[ad_system_owner]\"><address>[ad_system_owner]</address></a>
    </body>
    </html>
    "
}

proc_doc ug_page_title { page_title group_id group_name {show_logo_p 1}} "formats the page title for the user group. if show_logo_p is 1, logo will be displayed (given that the logo is enabled for this page), else logo will not be displayed." {
    set sql_qry "select decode(logo_enabled_p, 't', 1, 0) as logo_enabled_p, scope from page_logos where scope='group' and group_id= :group_id"
    # default added so would not crash while testing initial 3.4 release.  Maybe good to have.
    set logo_viewable_p [db_string "ug_logo_enabled_p" $sql_qry -default 0]
    # set logo_viewable_p $logo_enabled_p  # previous, seems in error

    if { $logo_viewable_p } {
	# logo is enabled
	return [ad_decorate_top "<font size=4><b>$group_name</b></font><br><br><font size=4>$page_title" \
		"<img src=\"/display/get-logo.tcl?[export_url_vars scope group_id]\" ALT=Logo>"]
    } else {

	# logo disabled either by system or group administrator, so return plain text page title
	return "
	<font size=5><b>$group_name</b></font>
	[ad_space 2] 
	<font size=4>$page_title</font>
	<br><br>
	"
    }
}

proc_doc ug_admin_page_title { page_title group_id group_name } "formats the page title for the user groups admin pages." {
    return "
    <font size=5><b>$group_name</b></font>
    [ad_space 2] 
    <font size=4>$page_title</font>
    <br><br>
    "
}

proc_doc ug_return_complaint { exception_count exception_text group_id group_name admin_email } "Return a page complaining about the user's input (as opposed to an error in our software, for which ug_return_error is more appropriate). This pages are changed in order to use ug_header and ug_footer" {
    # there was an error in the user input 
    if { $exception_count == 1 } {
	set problem_string "a problem"
	set please_correct "it"
    } else {
	set problem_string "some problems"
	set please_correct "them"
    }
	    
    doc_return  200 text/html "
    [ug_header "Problem with Your Input" $group_id]
    [ug_page_title "Problem with Your Input" $group_id $group_name]
    <hr>

    We had $problem_string processing your entry:
    <ul> 
    $exception_text
    </ul>
    
    Please back up using your browser, correct $please_correct, and
    resubmit your entry.
	
    <p>
	
    Thank you.
    
    [ug_footer $admin_email]
    "
}

proc_doc ug_return_warning { title explanation group_id group_name admin_email } "it returns  properly formatted warning message to the user. this procedure is appropriate for messages like not authorized to access this page." {
    doc_return  200 text/html "
    [ug_header $title $group_id]
    [ug_page_title $title $group_id $group_name]
    <hr>
    <blockquote>
    $explanation
    </blockquote>
    [ug_footer $admin_email]"
}

proc_doc ug_return_error { title explanation group_id group_name admin_email } "this function should be used if we want to indicate an error to the user, which was produced by bug in our code. it returns error message properly formatted for user_groups." {
    doc_return  500 text/html "
    [ug_header $title $group_id]
    [ug_page_title $title $group_id $group_name]
    <hr>
    <blockquote>
    $explanation
    </blockquote>
    [ug_footer $admin_email]"
}

proc_doc util_unset_local_vars args "this procedure will unset all the
local variables in the callers environment except the variables specified
in the args" { 
    set local_vars_list [uplevel {info locals}]

    foreach arg $args {
	set index [lsearch -exact $local_vars_list $arg]
	if {$index>=0} {
	    set local_vars_list [lreplace $local_vars_list $index $index]
	}
    }

    foreach var $local_vars_list {
	uplevel "unset $var"
    }
}

proc_doc ug_export_to_form args "Given a list of variable names, put each name 
and its value in the caller's environment into the connections form. This gives 
a file you are going to source the impression that the variables had been passed 
through a GET or POST." {
    # If the request didn't contain any variables, AOLServer is not going to
    # create an empty set for the form. We do it now by assigning to the
    # global var _ns_form
    global _ns_form
    if { [empty_string_p [ns_getform]] } {
	set _ns_form [ns_set create]
    }

    set skipped_args [list]
    foreach arg $args {
	upvar $arg var
	# Using update, so if $arg is already provided in the form, it
	# will be overwritten.
	if [info exists var] {
	    ns_set update [ns_getform] $arg $var
	} else {
	    lappend skipped_args $arg
	}
    }
    if { [llength $skipped_args] > 0 } {
	ns_log Warning "ug_export_to_form: skipped unset variables [join $skipped_args ", "]"
    }
}

proc_doc ug_source_with_env { info {vars_to_keep ""} } "Source the file as specified by INFO 
(same as for ug_source). Before sourcing, all variables in the callers environment are unset 
except for the ones given in the list VARS_TO_KEEP." {
    if { [empty_string_p $vars_to_keep] } {
	uplevel { util_unset_local_vars }
    } else {
	uplevel [linsert $vars_to_keep 0 util_unset_local_vars]
    }
    uplevel [list ug_source $info]
}

# This procedure is called to send a group spam message with the 
# given spam_id which only sends approved spam out

proc_doc send_one_group_spam_message { spam_id } {This procedure sends out a group spam message with the given spam_id, provided the spam is approved ( i.e. either the spam policy of the group is "open", or policy is "wait" and the group administrator approved it)} {

    ns_log Notice "running send_one_group_spam_message"   

    # Get information related to this spam from the group_spam_history_table
    
    set sql_qry "select group_id, sender_id, from_address, subject, body, send_to
    from group_spam_history
    where spam_id = :spam_id
    and approved_p = 't'
    and send_date is null"
    if { ![db_0or1row "one_spam" $sql_qry]} {
	# no sendable spam 
	db_release_unused_handles
	ns_log Notice "send_one_group_spam_message : no spam to send"
 	return 
    }
	 

    db_1row spam_group_name_admin_email "select group_name, admin_email
                                         from user_groups
                                         where group_id = :group_id"

    set group_spam_removal_string "[group_spam_removal_blurb $group_id]"

    if { [lsearch $send_to "all"] != -1 } {
	set role_clause ""
    } else {
	foreach recipient_role $send_to {
	    append ug_role_clause "ug.role='$recipient_role' "
	}
	set role_clause "and ("
	append role_clause [join $ug_role_clause " or "] 
    }
    
    set sql_query "select distinct u.email as receiver_email,
                          u.user_id as receiver_id ,
                          u.first_names as receiver_first_names,
                          u.last_name as receiver_last_name
	from user_group_map ug, users_spammable u
	where ug.group_id = :group_id
	$role_clause
	and ug.user_id = u.user_id
	and not exists ( select 1 
	                 from group_member_email_preferences
                         where group_id = :group_id
	                 and user_id =  u.user_id 
                         and dont_spam_me_p = 't')
        and not exists ( select 1 
	                 from user_user_bozo_filter
                         where origin_user_id = u.user_id 
	                 and target_user_id =  :sender_id)"

    set selection_list [db_list_of_lists "spam_all_receivers" $sql_query]

    # Release the handle while sending mail
    db_release_unused_handles 

    # query sets email for each recipient
    regsub -all "\r" $body "" body_stripped

    # we want to keep track of how many emails are actually sent out
    set n_receivers_actual 0

    foreach row $selection_list {
	set receiver_email [lindex $row 0]
	set receiver_id [lindex $row 1]
	set receiver_first_names [lindex $row 2]
	set receiver_last_name [lindex $row 3]

	set message_body $body_stripped

	# This appends group-wide removal blurb
	append message_body $group_spam_removal_string 

	# This appends site-wide bozo-filter blurb,
	# so, the receiver doesn't get any more email from sender
	append message_body "[bozo_filter_blurb $sender_id]"

	# substitute all user/group specific data in the message body

	regsub -all "<first_names>" $message_body $receiver_first_names message_body
	regsub -all "<last_name>" $message_body $receiver_last_name message_body
	regsub -all "<email>" $message_body $receiver_email message_body
	regsub -all "<group_name>" $message_body $group_name message_body
	regsub -all "<admin_email>" $message_body $admin_email message_body

	if { [catch {ns_sendmail $receiver_email $from_address $subject $message_body} err_msg] } {
	    ns_log Error "user-group-defs: Error sending spam to $receiver_email: $err_msg"
	} else {
	    incr n_receivers_actual	
	}
    }

    # Log that the emails went out

    db_dml spam_record_receivers "
    update group_spam_history
    set    n_receivers_actual = :n_receivers_actual,
           send_date =  sysdate
    where  spam_id   = :spam_id"

    db_release_unused_handles
    ns_log Notice "send_one_group_spam_message : finished sending group spam id $spam_id"
}



# This procedure is called to send all approved spam messages  
# for a specific group

proc_doc send_all_group_spam_messages { group_id } {This procedure sends all approved spam messages of a specific group} {

    ns_log Notice "running send_all_group_spam_messages"
    
    # Get information related to these spams from the group_spam_history table
    set sql_qry "select spam_id
		from group_spam_history
                where group_id = :group_id
                and approved_p = 't'
                 and send_date is null"

    set counter 0
    set spam_id_list [list]

    # build a list of spam_ids to send 

    db_foreach spam_all_history $sql_qry {
	lappend spam_id_list $spam_id
    } if_no_rows {
	ns_log Notice "send_all_group_spam_messages : no spam to send"
	return 
    }
    
    db_release_unused_handles
    
    foreach spam_id $spam_id_list {
	# send each spam message
	send_one_group_spam_message $spam_id 
    }
    
    ns_log Notice "send_all_group_spam_messages : finished sending group spams for group id $group_id"
}

proc_doc group_spam_removal_blurb {group_id} {A blurb to append to group spam messages, telling users why they got the spam and how to avoid getting it in the future} {

    db_1row "names_from_user_groups" "select group_name, short_name
    from user_groups
    where group_id=:group_id"

    return "

--------------
To stop receiving any future spam from the $group_name group :
click <a href=\"[ad_url]/groups/$short_name/edit-preference?dont_spam_me_p=t\">here</a>"
}

proc_doc bozo_filter_blurb {sender_id} {A blurb to append to any spam message, letting the user avoid future emails from this specific sender} {
    return "

---------------
To stop receiving any future email from this specific sender :
click <a href=\"[ad_url]/user-user-bozo-filter?[export_url_vars sender_id]\">here</a>"
}
