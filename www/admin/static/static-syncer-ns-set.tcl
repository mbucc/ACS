ad_page_contract {
    This program crawls through all of your Web content and finds pages to 
    stuff into the static_pages table.

    @author Jin Choi [jsc@arsdigita.com]
    @author Philip Greenspun [philg@mit.edu]
    @cvs-id static-syncer-ns-set.tcl,v 3.3.2.7 2000/09/22 01:36:09 kevin Exp
} {
}

set page_content "<html>
<head>
<title>Syncing Pages at [ns_conn location]</title>
</head>
<body bgcolor=white text=black>
<h2>Syncing Pages</h2>

[ad_admin_context_bar [list "index.tcl" "Static Content"] "Syncing Static Pages"]

<hr>

All HTML files:
<ul>
"

# exclusion patterns
set exclude_patterns [list]

foreach pattern [ad_parameter_all_values_as_list "ExcludePattern" "static"] {
    lappend exclude_patterns "[ns_info pageroot]$pattern"
}

# the include_pattern regexp defaults to .htm and .html
set inclusion_regexp [ad_parameter IncludeRegexp "static" {\.html?$}]

append page_content [walk_tree [ns_info pageroot] ad_check_file_for_sync [ns_set new] $inclusion_regexp $exclude_patterns]

append page_content "</ul><hr>
<address><a href=\"http://photo.net/philg/\">philg@mit.edu</a></address>
</body></html>
"


doc_return  200 text/html $page_content