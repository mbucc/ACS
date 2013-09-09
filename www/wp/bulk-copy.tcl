# /wp/bulk-copy.tcl
ad_page_contract {
    Displays a frameset allowing the user to pick a presentation to \
    bulk-copy slides from.
    @cvs-id bulk-copy.tcl,v 3.0.12.6 2000/09/22 01:39:29 kevin Exp
    @creation-date  28 Nov 1999
    @author  Jon Salz <jsalz@mit.edu>
    @param presentation_id
    @param user_id (optional)
} {
    presentation_id:naturalnum,notnull
    user_id:naturalnum,optional
}
# modified by jwong@arsdigita.com on 11 Jul 2000 for ACS 3.4 upgrade

if { [info exists user_id] } {
    set bottom_src "index.tcl?bulk_copy=$presentation_id&show_user=&show_age=14"
} else {
    set bottom_src "index.tcl?bulk_copy=$presentation_id&show_user=all&show_age=14"
}

set page_output "
<html>
<head>
<title>Bulk Copy</title>
</head>
<frameset rows=\"75,*\" border=0>
<frame src=\"bulk-copy-top.tcl?presentation_id=$presentation_id\" scrolling=no>
<frame src=\"$bottom_src\">
</frameset>
</html>
"



doc_return  200 "text/html" $page_output
