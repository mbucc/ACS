# /wp/style-view.tcl
ad_page_contract {
    Shows the CSS code for a style.
    @cvs-id css-view.tcl,v 3.0.12.7 2000/09/22 01:39:30 kevin Exp
    @creation-date  13 Nov 1999
    @author  Jon Salz <jsalz@mit.edu>
    @param  style_id (if editing)
} {
    style_id:naturalnum,optional
}
# modified by jwong@arsdigita.com on 13 Jul 2000 for ACS 3.4 upgrade

set user_id [ad_maybe_redirect_for_registration]

wp_check_style_authorization $style_id $user_id

db_1row css_select "select css from wp_styles where style_id = :style_id"



doc_return  200 "text/plain" "$css\n"

#ReturnHeaders
#ns_write "[wp_header_form "name=f action=style-edit-2.tcl method=post enctype=multipart/form-data" \
#           [list "" "WimpyPoint"] [list "style-list.tcl" "Your Styles"] [list "style-view.tcl?style_id=$style_id" $name] "View CSS"]
#[export_form_vars style_id]
#
#<blockquote><pre>[ns_quotehtml $css]</pre></blockquote>
#
#[wp_footer]
#"