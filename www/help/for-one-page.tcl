# /help/for-one-page.tcl 
#

ad_page_contract {
    Displays the help file associated with a particular URL.
    Typically called by help_link (defined in /tcl/help-defs.tcl).

    Tries to find the best help file according to the user's language
    preference.

    @cvs-id for-one-page.tcl,v 3.0.12.4 2000/09/22 01:38:15 kevin Exp

    @author philg@mit.edu on July 2, 1999
} {
    url:notnull
}


set pageroot [ns_info pageroot]
set helproot [ad_parameter HelpPageRoot help ""]
set helproot_fullpath "$pageroot$helproot"

set full_url $url
set just_the_dir [file dirname $full_url]
set just_the_filename [file rootname [file tail $full_url]]
set help_file_directory "$helproot_fullpath$just_the_dir"
set glob_pattern "${help_file_directory}/${just_the_filename}*.help"
set available_help_files [glob -nocomplain $glob_pattern]

if { [llength $available_help_files] == 0 } {
    ns_log Notice "$helproot/for-one-page reports that User requested help for \"$url\" but no .help file found"
    ad_return_error "No help available" "No help is available for this page (\"$url\"), contrary to what you presumably were told.  This is either our programming bug or (maybe) a bug in your browser."
    return
}

set list_of_lists [ad_style_score_templates $available_help_files]
set sorted_list [lsort -decreasing -command ad_style_sort_by_score $list_of_lists]

set top_scoring_help_file_filename [lindex [lindex $sorted_list 0] 1]
set fully_qualified_help_file_filename $top_scoring_help_file_filename

doc_return  200 text/html [ns_adp_parse -file $fully_qualified_help_file_filename]




