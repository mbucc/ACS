# /wp/reorder-slides.tcl
ad_page_contract {
    Allows an author to change the order of slides.

    @param presentation_id

    @creation-date   28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @cvs-id reorder-slides.tcl,v 3.1.2.7 2000/09/22 01:39:34 kevin Exp
} {
    presentation_id:naturalnum,notnull
}


set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "write"

db_1row presentation_info_sel "select 
title, page_signature, copyright_notice, creation_date,
creation_user, style, show_modified_p, public_p,
audience, background, group_id
from wp_presentations where presentation_id = :presentation_id"

append whole_page "[wp_header_form "name=f" \
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
        if (selectedIndex >= 0 && selectedIndex < length - 1) {
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

db_foreach slides_sel "
    select slide_id, title
    from wp_slides 
    where presentation_id = :presentation_id
    and max_checkpoint is null
    order by sort_key
" {
    incr counter
    append out "<option value=$slide_id>$counter. $title\n"
}

append whole_page "$out
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


doc_return  200 text/html $whole_page