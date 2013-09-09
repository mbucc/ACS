# /www/manuals/admin/figures.tcl
ad_page_contract {
    Maintain the figures for a manual

    @param manual_id the manual whose figures we are looking at
    
    @author Ron Henderson (ron@arsdigita.com)
    @creation-date Feb 2000
    @cvs-id figures.tcl,v 1.4.2.3 2000/07/21 04:02:50 ron Exp
} {
    manual_id:integer,notnull
}

# -----------------------------------------------------------------------------

# Verify the editor

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to edit this manual"
    }
}

# Generate the list of figures for this manual

set manual_title [db_string manual_title "
select title from manuals 
where manual_id = :manual_id"]

set figure_list ""

db_foreach figures "
select figure_id, 
       sort_key,
       numbered_p,
       caption,
       label,
       decode(file_type,'image/gif','gif','jpg') as ext
from   manual_figures
where  manual_id = :manual_id 
order by sort_key" {

    append figure_list "
    <tr>
    <td valign=top align=center>
    <a href=figure-edit?[export_url_vars manual_id figure_id]>
    <img border=1 
         src=/manuals/figures/${manual_id}.${figure_id}.$ext height=60 width=60 
         alt=\"$label\"><br>$label</a>
    </td>
    <td valign=top>[expr {$numbered_p == "t" ? $sort_key : ""}]</td>
    <td valign=top>$caption</td>
    </tr>"
}

if [empty_string_p $figure_list] {
    set figures "</ul>
    <p>There are no figures in this manual</p>"
} else {
    set figures "
    <p>
    <li><a href=\"manual-printable?manual_id=$manual_id&return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]\">Regenerate figure numbers</a>
    </ul>

    <p>Click on a thumbnail to edit the figure:</p>
    <table>
    $figure_list
    </table>"
}

# -----------------------------------------------------------------------------

doc_set_property title "Figures"
doc_set_property navbar [list \
	[list "../" [manual_system_name]] \
	[list "index.tcl" "Admin"] \
	[list "manual-view.tcl?manual_id=$manual_id" "$manual_title"] \
	"Figures"]

doc_body_append "
<ul>
<li><a href=figure-add?manual_id=$manual_id>Add a new figure</a>

$figures

"





