# /www/custom-sections/index.tcl
ad_page_contract {
    This serves the custom section index page 

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author Contact:  ahmeds@arsdigita.com
    @creation-date    12/28/99

    @param section_id

    @cvs-id index.tcl,v 3.1.2.6 2000/09/22 01:37:19 kevin Exp
} {
    section_id:integer
}


ad_scope_error_check
ad_scope_authorize $scope all all none

db_1row select_body "
select body, html_p, section_pretty_name 
 from content_sections 
 where section_id = :section_id" 

set page_title $section_pretty_name


append html "
[ad_scope_header $page_title]
[ad_scope_page_title $page_title]
[ad_scope_context_bar_ws "$page_title"]
<hr>
[ad_scope_navbar]
"

set query_sql "
select file_name, page_pretty_name 
 from content_files 
 where section_id = :section_id 
 and file_type = 'text/html' 
 order by file_name 
"
    
set page_counter 0
db_foreach select_query $query_sql {
    append page_links " 
    <li><a href=\"$file_name\">$page_pretty_name</a>
    <br> "
    
    incr page_counter
}

db_release_unused_handles    

if { $page_counter==0 } {
    append html "
    <p>
    "     
} else {
    append html "
    <p>
    <ul>
    $page_links
    </ul>
    <p>
	"
}

if { ![empty_string_p $body] } {    
    append html "
    [util_maybe_convert_to_html $body $html_p]	
    "
}

doc_return  200 text/html "
$html
[ad_scope_footer ]
"


