# File: /www/admin/content-tagging/test.tcl
ad_page_contract {
    Tests the Content Tagging Package
    
    @param testarea block of text
    @param table_name
    @the_key

    @author unknown
    @cvs-id test.tcl,v 3.1.2.4 2000/09/22 01:34:35 kevin Exp
} {
    testarea
    table_name:optional
    the_key:optional
}
ad_maybe_redirect_for_registration
set user_id [ad_get_user_id] 


set title "Testing the Content Tagging Package"

append page_content "[ad_admin_header $title ]

<h2>$title</h2>

[ad_admin_context_bar [ list index.tcl "Content Tagging Package"] $title ]

<hr>

"

if {![info exists the_key]} {
    set the_key ""
}
if {![info exists table_name]} {
    set table_name ""
}

append page_content "Testing... <blockquote>$testarea </blockquote> 
<p> Running content_string_ok_for_site_p results in: "

if {[content_string_ok_for_site_p $testarea $table_name $the_key]} {
    append page_content "This site would allow the text."
} else {
    append page_content "This site would bounce the text."
}

set tag [tag_content $testarea]

append page_content "<p> tag_content yields \"$tag\"
<p>
"
set deleted  "apply_content_mask yields \"\[apply_content_mask $tag\]\"
<p>
"

append page_content "
bowdlerize_text yields:
<blockquote>[bowdlerize_text $testarea]</blockquote>
user id is $user_id
[ad_admin_footer]"



doc_return  200 text/html $page_content
