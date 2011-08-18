# $Id: css-view.tcl,v 3.0 2000/02/06 03:54:53 ron Exp $
# File:        style-view.tcl
# Date:        13 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Shows the CSS code for a style.
# Inputs:      style_id (if editing)

set_the_usual_form_variables 0
set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]

wp_check_style_authorization $db $style_id $user_id

set selection [ns_db 1row $db "select * from wp_styles where style_id = $style_id"]
set_variables_after_query

ReturnHeaders "text/plain"
ns_write $css

#ReturnHeaders
#ns_write "[wp_header_form "name=f action=style-edit-2.tcl method=post enctype=multipart/form-data" \
#           [list "" "WimpyPoint"] [list "style-list.tcl" "Your Styles"] [list "style-view.tcl?style_id=$style_id" $name] "View CSS"]
#[export_form_vars style_id]
#
#<blockquote><pre>[ns_quotehtml $css]</pre></blockquote>
#
#[wp_footer]
#"