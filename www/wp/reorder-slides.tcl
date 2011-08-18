# $Id: reorder-slides.tcl,v 3.0 2000/02/06 03:55:30 ron Exp $
# File:        reorder-slides.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Allows an author to change the order of slides.
# Inputs:      presentation_id

set_the_usual_form_variables

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "write"

set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
set_variables_after_query

ReturnHeaders
ns_write "[wp_header_form "name=f" \
           [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
           [list "presentation-top.tcl?presentation_id=$presentation_id" "$title"] "Reorder Slides"]

To move a slide in your presentation, select its title and click the Up or Down arrow.
When you're done, click <i>Save Changes</i>.

<script language=javascript>

function up() {
    with (document.f.slides) {
        if (selectedIndex > 0) {
            var sel = selectedIndex;
            var selectedText = options\[sel\].text;
            var selectedValue = options\[sel\].value;
            options\[sel\].text = options\[sel-1\].text;
            options\[sel\].value = options\[sel-1\].value;
            options\[sel-1\].text = selectedText;
            options\[sel-1\].value = selectedValue;
            --selectedIndex;
        }
    }
}

function down() {
    with (document.f.slides) {
        if (selectedIndex < length - 1) {
            var sel = selectedIndex;
            var selectedText = options\[sel\].text;
            var selectedValue = options\[sel\].value;
            options\[sel\].text = options\[sel+1\].text;
            options\[sel\].value = options\[sel+1\].value;
            options\[sel+1\].text = selectedText;
            options\[sel+1\].value = selectedValue;
            ++selectedIndex;
        }
    }
}

function done() {
    var query = '';

    with (document.f.slides) {
        var i;
        for (i = 0; i < length; ++i)
            query += '&slide_id=' + options\[i\].value;
    }

    location.href = 'reorder-slides-2.tcl?presentation_id=$presentation_id' + query;
}
</script>

<center>

<p>
<table>
<tr><td rowspan=2>
<select name=slides size=10>
"

set counter 0

wp_select $db "
    select slide_id, title
    from wp_slides 
    where presentation_id = $presentation_id
    and max_checkpoint is null
    order by sort_key
" {
    incr counter
    append out "<option value=$slide_id>$counter. $title\n"
}

ns_write "$out
</select>
</td>
<td align=center valign=middle><a href=\"javascript:up()\"><img src=\"pics/up.gif\" border=0></a></td>
</tr>
<tr>
<td align=center valign=middle><a href=\"javascript:down()\"><img src=\"pics/down.gif\" border=0></a></td>
</tr>

<tr><td align=center><input type=button value=\"Save Changes\" onClick=\"done()\"></td></tr>

</table>
</center>

[wp_footer]
"
