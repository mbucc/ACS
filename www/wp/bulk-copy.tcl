# $Id: bulk-copy.tcl,v 3.0 2000/02/06 03:54:52 ron Exp $
# File:        bulk-copy.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Displays a frameset allowing the user to pick a presentation to
#              bulk-copy slides from.
# Inputs:      presentation_id
#              user_id (optional)

set_the_usual_form_variables

if { [info exists user_id] } {
    set bottom_src "index.tcl?bulk_copy=$presentation_id&show_user=&show_age=14"
} else {
    set bottom_src "index.tcl?bulk_copy=$presentation_id&show_user=all&show_age=14"
}

ReturnHeaders
ns_write "
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
