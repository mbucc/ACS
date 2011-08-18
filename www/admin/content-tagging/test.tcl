# $Id: test.tcl,v 3.0 2000/02/06 03:15:31 ron Exp $
ad_maybe_redirect_for_registration

set_the_usual_form_variables

# testarea, optionally table_name, the_key

ReturnHeaders

set title "Testing the Content Tagging Package"

ns_write "[ad_admin_header $title ]

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


ns_write "Testing... <blockquote>$testarea </blockquote> 
<p> Running content_string_ok_for_site_p results in: "

if {[content_string_ok_for_site_p $testarea $table_name $the_key]} {
    ns_write "This site would allow the text."
} else {
    ns_write "This site would bounce the text."
}

set tag [tag_content $testarea]

ns_write "<p> tag_content yields \"$tag\"
<p>
"
set deleted  "apply_content_mask yields \"\[apply_content_mask $tag\]\"
<p>
"

ns_write "
bowdlerize_text yields:
<blockquote>[bowdlerize_text $testarea]</blockquote>
"

ns_write "[ad_admin_footer]"


