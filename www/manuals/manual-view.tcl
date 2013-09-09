# /www/manuals/manual-view.tcl
ad_page_contract {
    Display the TOC for one manual

    @param manual_id the ID of the manual we are viewing

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Jan 2000
    @cvs-id manual-view.tcl,v 1.3.2.3 2000/07/21 23:58:03 kevin Exp
} {
    manual_id:integer,notnull
}

# -----------------------------------------------------------------------------

# Check to see if this user can maintain the manual


if [ad_permission_p "manuals" $manual_id] {
    set helper_args [list "admin/manual-view.tcl?manual_id=$manual_id" "Maintain this manual"]
} else {
    set helper_args ""
}

db_1row info_for_one_manual "
    select title, 
           '/manuals/export/' || short_name as export_name
    from   manuals 
    where  manual_id = :manual_id"


if [ad_parameter UseHtmldocP manuals] {
    
    set htmldoc_msg "Download a printable version of this manual in
    <a href=\"${export_name}.pdf\">PDF</a>"


    if [ad_parameter GeneratePsP manuals] {
	append htmldoc_msg " or <a href=\"${export_name}.ps\">PS</a>,"
    }

    append htmldoc_msg " or view the entire manual as an <a
    href=\"${export_name}.html\">HTML</a> document."  

} else {
    set htmldoc_msg ""
}

# -----------------------------------------------------------------------------
# serve the page

doc_set_property title "$title"
doc_set_property navbar [list [list "index.tcl" [manual_system_name]] $title]

doc_body_append "

[help_upper_right_menu $helper_args]

[manual_toc -type "limited" $manual_id]

<p>$htmldoc_msg

<br clear=all>
"




