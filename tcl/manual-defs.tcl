# /tcl/manual-defs.tcl

ad_library {

    Routines used by the manuals system

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Jan 2000
    @cvs-id manual-defs.tcl,v 3.4.2.5 2000/07/25 09:19:07 ron Exp
}

# -----------------------------------------------------------------------------

# Schedule proc to generate printable copies of all manuals each night

ns_schedule_daily -thread 5 15 manual_assemble_all

# -----------------------------------------------------------------------------

proc manual_header {page_title} {
    return [ad_header $page_title]
}

proc manual_footer { {signatory ""} } {
    return [ad_footer $signatory]
}

proc_doc manual_system_name {} {returns the system name for the manual
system for context bars, using either the value supplied in the ini
file or a default value of Manuals} {
    return [ad_parameter SystemName manuals "[ad_parameter SystemName] Manuals"]
}

ad_proc -private manual_toc {
    {-type "full"} 
    {-prefix ""}
    manual_id 
} {
    Returns a table of contents of type "full" or "limited"
} {  

    if { $type == "limited" } {
	set display_str "and display_in_toc_p = 't'"
    } else {
	set display_str ""
    }

    # Grab the basic section information using prefix to select out
    # the appropriate sub-tree from the full table of contents
    # then convert to an html list

    set output ""
    set depth  [string length $prefix]
    set prefix_search_term "$prefix%"

    db_foreach get_section_info "
    select sort_key, 
           section_id, 
           section_title,
           content_p
    from   manual_sections
    where  active_p  = 't'
    and    manual_id = :manual_id $display_str
    and    sort_key like :prefix_search_term
    order by sort_key" {

	# Are we changing section levels?

	if { [string length $sort_key] != $depth } {
	    if { [string length $sort_key] > $depth } {
		append output "<ul>\n"
		incr depth 2
	    } else {
		# reduce depth until we get back to the same level
		while { [string length $sort_key] < $depth } {
		    append output "</ul>\n"
		    incr depth -2
		}
	    }
	}

	# Now insert a link to view the section if it has content,
	# otherwise just list it in the TOC.
	#
	# Potential problems: if display_in_toc_p is turned off for a
	# section that has no content but does have subsections, there
	# will be no way to navigate to the subsections from the
	# top-level TOC.

	if {$content_p == "t"} {
	    append output "<li><a href=section-view?[export_url_vars section_id manual_id]>
	    $section_title</a>"
	} else {
	    append output "<li>$section_title</li>"
	}
    }

    # Make sure we close all the open tags

    while { [string length $prefix] != $depth } {
	append output "</ul>"
	incr depth -2
    }

    return $output

}

proc_doc manual_get_parent {key} "Returns the sort_key for the parent" {
    return [string range $key 0 [expr [string length $key]-3]]
}

proc_doc manual_get_image_file {figure_id} {Returns the correct image file for a figure} {

    db_1row get_figure_info "
    select manual_id,
           decode(file_type,'image/gif','gif','jpg') as ext
    from   manual_figures
    where  figure_id = :figure_id"

    return "/manuals/figures/${manual_id}.${figure_id}.$ext"
}

proc_doc manual_get_content {manual_id section_id} "Retrieves the
contents of the HTML file associated with a section" {  

    set filename "[ns_info pageroot]/manuals/sections/$manual_id.$section_id.html"

    set stream [open $filename r]
    set output [read $stream]
    close $stream

    return $output
}

proc_doc manual_chapter_list {manual_id} "Returns a chapter list to be
included on section-view pages as a navigational aid" {

    set output "
    <table width=20% cellpadding=1 cellspacing=5 border=0 bgcolor=black 
           align=[ad_parameter ChapterListSide manuals]>
    <tr>
    <td>
    <table width=100% cellpadding=2 cellspacing=0 border=0 bgcolor=white>"

    db_foreach get_manual_sections "
    select section_id, 
           section_title
    from   chapters 
    where  manual_id = :manual_id" {

	append output "
	<tr>
	<td valign=top><li>&nbsp;</td>
	<td valign=top>
	<a href=/manuals/section-view?[export_url_vars section_id manual_id]>$section_title</a> 
	</td>
	</tr>"
    }
    
    return [concat $output "\n</table></td></tr></table>"]
}

proc_doc manual_parse_section {manual_id section_id} "Returns the
HTML content for a section with special reference tags for sections
and images expanded into proper HTML" {

    # Grab the content for this section

    set content [manual_get_content $manual_id $section_id]

    # Create arrays for figures and sections keyed on the appropriate
    # label. 

    set figure_row [ns_set create]
    db_foreach figure_info "
    select label, 
           figure_id, 
           height, 
           width, 
           caption,
           sort_key, 
           numbered_p, 
           decode(file_type,'image/gif','gif','jpg') as ext
    from   manual_figures
    where  manual_id = :manual_id
    " -column_set figure_row {

	set figures([ns_set get $figure_row label]) [ns_set copy $figure_row]
    }

    set section_row [ns_set create]
    db_foreach section_info "
    select label, 
           section_id, 
           section_title,
           manual_id as other_manual_id
    from   manual_sections
    " -column_set section_row {

	set sections([ns_set get $section_row label]) [ns_set copy $section_row]
    }

    # Split the content into pieces based on what we expect to be HTML tags

    set figure_list    [list]
    set content_buffer [split $content "<"]
    set content_parsed [list]

    # First pass: replace figure and section references

    foreach piece $content_buffer {

	if {[regexp -nocase {^SECREF[^>]*NAME=\"([^\"]*)\"} $piece match label]} {

	    if {[lsearch -exact [array names sections] $label] != -1} {
		ad_ns_set_to_tcl_vars $sections($label)

		regsub -nocase "^SECREF\[^>\]*NAME=\"$label\"\[^>\]*>" $piece \
			"A HREF=/manuals/section-view?section_id=$section_id\\&manual_id=$other_manual_id>
		         $section_title</A>" piece
	    } 

	} elseif {[regexp -nocase {^FIGURE[^>]*NAME=\"([^\"]*)\"} $piece match label]} {
		
	    if {[lsearch -exact [array names figures] $label] != -1} {
		ad_ns_set_to_tcl_vars $figures($label)

		if {$numbered_p == "t"} {
		    set replace "A NAME=\"$label\">
		    <IMG SRC=/manuals/figures/$manual_id.$figure_id.$ext ALT=\"$label\" 
		         HEIGHT=$height WIDTH=$width>
		    <br>Figure $sort_key : $caption"
		} else {
		    set replace "IMG SRC=/manuals/figures/$manual_id.$figure_id.$ext
		    ALT=\"$label\" HEIGHT=$height WIDTH=$width>"

		    if ![empty_string_p $caption] {
			append replace "<br>$caption"
		    }
		}
		regsub -nocase "^FIGURE\[^>\]*NAME=\"$label\"\[^>\]*>" $piece $replace piece
	    
		# Add this figure to the list of figures for this section
		lappend figure_list $label

	    }

	} 
	
	lappend content_parsed $piece
    }

    # Second pass: update the figure references

    set content_buffer $content_parsed
    set content_parsed [list]

    foreach piece $content_buffer {

	if [regexp -nocase {^FIGREF[^>]*NAME=\"([^\"]*)\"} $piece match label] {
	    if {[lsearch -exact [array names figures] $label] != -1} {
		ad_ns_set_to_tcl_vars $figures($label)

		if {[lsearch -exact $figure_list $label] != -1} {
		    set replace "A HREF=\"\#$label\">Figure $sort_key</A>"
		} else {
		    set replace "A TARGET=OTHER HREF=/manuals/figure-view?figure_id=$figure_id>
		    Figure $sort_key</A>"
		}
		regsub -nocase "^FIGREF\[^>\]*NAME=\"$label\"\[^>\]*>" $piece $replace piece
	    }
	    
	}

	lappend content_parsed $piece
    }

    return [join $content_parsed "<"]
}


proc_doc manual_parse_special_tags {html} "Finds the special tags for
the reference system in an HTML document." { 

    set sec_list [list]
    set fig_list [list]
    set fig_ref_list [list]

    set pieces [split $html "<"]

    foreach piece $pieces {
	
	if [regexp -nocase {^[^>]*NAME=\"([^\"]*)\"} $piece match label] {
	    if {[regexp -nocase "^SECREF" $piece match] && \
		    [lsearch -exact $sec_list $label] == -1} {
		lappend sec_list $label
	    } elseif {[regexp -nocase "^FIGREF" $piece match] && \
		    [lsearch -exact $fig_ref_list $label] == -1} {
		lappend fig_ref_list $label
	    } elseif {[regexp -nocase "^FIGURE" $piece match] && \
		    [lsearch -exact $fig_list $label] == -1} {
		lappend fig_list $label
	    }
	}
    }

    return [list $sec_list $fig_list $fig_ref_list]
}



proc_doc manual_assemble {manual_id} "Assembles an entire 
manual in HTML suitable for printing from a browser or feeding to
HTMLDOC. Writes the output to the export directory and returns a list
of undefined references." {

    # Assemble the document from its constituent pieces

    db_1row get_manual_info "
    select title, 
           short_name, 
           author, 
           copyright,
           version
    from   manuals
    where  manual_id = :manual_id"

    set output "
    <html>
    <head>
    <title>$title</title>
    <meta name=author    content=\"$author\">
    <meta name=copyright content=\"$copyright\">
    <meta name=docnumber content=\"$version\">
    </head>
    <body>
    "

    db_foreach get_section_info "
    select section_title, 
           section_id, 
           length(sort_key)/2 as depth,
           label, 
           content_p
    from   manual_sections
    where  manual_id = :manual_id
    and    active_p = 't'
    order by sort_key" {

	# insert an internal anchor
	if ![empty_string_p $label] {
	    append output "\n<a name=\"$label\">\n"
	}

	# grab the content for this section if it has any
	if { $content_p == "t" } {
	    set content [manual_get_content $manual_id $section_id]
	} else {
	    set content ""
	}

	append output "<H${depth}>$section_title</H${depth}>\n$content"
    }

    # Now we have the entire document assembled in output, but we
    # still have to parse it to handle section and figure reference
    # tags. 

    set output_buffer [split $output "<"]

    # Regenerate all the figure numbers

    manual_update_figure_numbers $manual_id $output_buffer

    # load all the labels in the database into arrays

    set figure_row [ns_set create]
    db_foreach figure_info "
    select label, 
           figure_id, 
           height, 
           width, 
           caption,
           sort_key, 
           numbered_p, 
           decode(file_type,'image/gif','gif','jpg') as ext
    from   manual_figures
    where  manual_id = :manual_id
    " -column_set figure_row {

	set figures([ns_set get $figure_row label]) [ns_set copy $figure_row]
    }

    set section_row [ns_set create]
    db_foreach section_info "
    select label, 
           section_id, 
           manual_id, 
           section_title
    from   manual_sections
    " -column_set section_row {

	set sections([ns_set get $section_row label]) [ns_set copy $section_row]
    }

    # Go through the document and replace special tags with the
    # correct references

    set output_parsed [list]
    set bad_sections  [list]
    set bad_figures   [list]

    foreach piece $output_buffer {
	
	if [regexp -nocase {^SECREF[^>]*NAME=\"([^\"]*)\"} $piece match label] {

	    if {[lsearch -exact [array names sections] $label] != -1} {
		ad_ns_set_to_tcl_vars $sections($label)

		regsub -nocase "^SECREF\[^>\]*NAME=\"$label\"\[^>\]*>" \
			$piece "A HREF=\"\#$label\">$section_title</A>" piece
	    } else {
		if {[lsearch -exact $bad_sections $label] == -1} {
		    lappend $bad_sections $label
		}
	    }

	} elseif [regexp -nocase {^FIGURE[^>]*NAME=\"([^\"]*)\"} $piece match label] {

	    if {[lsearch -exact [array names figures] $label] != -1} {
		ad_ns_set_to_tcl_vars $figures($label)
	
		set file_name "../figures/${manual_id}.${figure_id}.$ext"
		
		if {$numbered_p == "t"} {
		    set replace "A NAME=\"$label\">
		    <IMG SRC=$file_name ALT=\"$label\" HEIGHT=$height WIDTH=$width>
		    <br>Figure $sort_key : $caption</P>"
		} else {
		    set replace "IMG SRC=\"$file_name\" ALT=\"$label\" HEIGHT=$height WIDTH=$width>"

		    if ![empty_string_p $caption] {
			append replace "<br>$caption"
		    }
		}

		regsub -nocase "^FIGURE\[^>\]*NAME=\"$label\"\[^>\]*>" $piece $replace piece
		
	    } else {
		if {[lsearch -exact $bad_figures $label] == -1} {
		    lappend bad_figures $label
		}
	    }

	} elseif [regexp -nocase {^FIGREF[^>]*NAME=\"([^\"]*)\"} \
		$piece match label] {
	    
	    if {[lsearch -exact [array names figures] $label] != -1} {
		ad_ns_set_to_tcl_vars $figures($label)

		regsub -nocase "^FIGREF\[^>\]*NAME=\"$label\"\[^>\]*>" $piece\
			"A HREF=\"\#$label\">Figure $sort_key</A>" piece

	    }
	}

	lappend output_parsed $piece
    }

    set output [join $output_parsed "<"]

    append output "
    </body>
    </html>
    "

    # save the end result

    set html_name "[ns_info pageroot]/manuals/export/$short_name.html"

    set ostream [open $html_name w]
    puts $ostream $output
    close $ostream

    # While we're at it, generate PS and PDF versions

    if [ad_parameter UseHtmldocP manuals] {
	set htmldoc "[ns_info pageroot]/../bin/htmldoc"

	regsub {.html$} $html_name {.pdf} pdf_name
	exec $htmldoc -f $pdf_name $html_name

	if [ad_parameter GeneratePsP manuals] {
	    regsub {.html$} $html_name {.ps} ps_name
	    exec $htmldoc -f $ps_name $html_name
	}
    }

    # Return the (possibly empty) list of bad sections and figures
    return [list $bad_sections $bad_figures]
}

# This proc takes the entire manual as an HTML document split into
# tokens delimited by "<" and updates the manual_figures table.    

proc manual_update_figure_numbers {manual_id pieces} {
    
    db_transaction {
	
	# Grab the information we need processing the figures

	set figure_list [list]
	db_foreach get_figure_numbers "
	select label, 
	figure_id, 
	numbered_p 
	from   manual_figures
	where  manual_id = :manual_id for update" {

	    set figures($label) [list $figure_id $numbered_p]
	}
    }

    foreach piece $pieces {
	if [regexp -nocase {^FIGURE[^>]*NAME=\"([^\"]*)\"} $piece match label] {
	    if {[info exists figures($label)] && \
		    [lsearch -exact $figure_list $figures($label)] == -1} {
		lappend figure_list $figures($label)
	    }
	}
    }

    # Assign numbers to each figure that as numbered_p = 't', and set
    # all other figure numbers to 0
    
    set figure_number 1

    foreach figure $figure_list {
	set figure_id  [lindex $figure 0]
	set numbered_p [lindex $figure 1]

	if {$numbered_p == "t" } {
	    db_dml update_numbered_figure "
	    update manual_figures
	    set    sort_key  = :figure_number
	    where  figure_id = :figure_id"
	    
	    incr figure_number
	} else {
	    db_dml update_unnumbered_figure "
	    update manual_figures
	    set    sort_key  = 0
	    where  figure_id = :figure_id"
	}
    }
}


proc_doc manual_assemble_all {} "Assemble all the manuals.  Intended to be
ns_schedule'd for once a night or so." { 

    set manuals [db_list get_active_manuals "
    select manual_id from manuals where active_p = 't'"]

    foreach manual_id $manuals {
	set undefined_labels [manual_assemble $manual_id]
	
	set bad_sections [lindex $undefined_labels 0]
	set bad_figures  [lindex $undefined_labels 1]

	if {[llength $bad_sections] > 0} {
	    set section_msg "Sections: [join $bad_sections ", "]"
	} else {
	    set section_msg ""
	}

	if {[llength $bad_figures] > 0 } {
	    set figure_msg "Figures: [join $bad_figures ", "]"
	} else {
	    set figure_msg ""
	}

	if {![empty_string_p $section_msg] || ![empty_string_p $figure_msg]} {

	    # Notify the manual owner about problems with this manual

	    db_1row owner_info_for_one_manual "
	    select email,
                   title 
	    from   manuals, users
	    where  manual_id = :manual_id
	    and    owner_id  = users.user_id
	    "

	    ns_sendmail $email [ad_parameter AdminOwner] "Bad references" "
	    Some references that aren't in the database were
	    discovered during the nightly generation of the printable
	    version of $title.   

	    $section_msg

	    $figure_msg
	    "
	}
    }
}


proc_doc manual_check_content {manual_id content} "This proceedure returns 
an error message specifying anything about the content that we don't like." {

    set exception_text ""

    # Heading tags confuse HTMLDOC

    if [regexp -nocase {<H[1-7]} $content match] {
	append exception_text "
	<li>Sections cannot contain heading tags, e.g. &lt;H2&gt;; these
	are inserted by the system automatically.\n"
    }

    # Make them refer to images using our figure tag rather than IMG
    
    if [regexp -nocase {<IMG} $content match] {
	append exception_text "<li>This section contains IMG tags.  You should
	use the FIGURE tag so we can keep track of references.\n"  
    }

    set tag_lists    [manual_parse_special_tags $content]
    set sec_list     [lindex $tag_lists 0]
    set fig_list     [lindex $tag_lists 1]
    set fig_ref_list [lindex $tag_lists 2]

    # Look for bad tags

    set known_sections [db_list labels_for_all_sections "
    select label from manual_sections"]
    
    set known_figures  [db_list labels_for_all_figures "
    select label from manual_figures"]

    set bad_sections [list]
    foreach sec_ref $sec_list {
	if {[lsearch -exact $known_sections $sec_ref] == -1} {
	    lappend bad_sections $sec_ref
	} 
    }

    if {[llength $bad_sections] > 0} {
	append exception_text "<li>This section contains one or more 
	unrecognized section references:<br>[join $bad_sections ","]\n" 
    }

    set bad_figures [list]
    foreach figure $fig_list {
	if {[lsearch -exact $known_figures $figure] == -1} {
	    lappend bad_figures $figure
	}
    }

    if {[llength $bad_figures] > 0} {
	append exception_text "<li>This section contains one or more
	undefined figures:<br>[join $bad_figures ","]<br>
	Correct these references or 
	<a target=other
	href=\"/manuals/admin/figure-add?manual_id=$manual_id&names=[ns_urlencode [join $bad_figures ","]]\">add them to the database</a> and reload this page.\n"
    }

    set bad_fig_refs [list]
    foreach fig_ref $fig_ref_list {
	if {[lsearch -exact $known_figures $fig_ref] == -1} {
	    lappend bad_fig_refs $fig_ref
	}
    }

    if {[llength $bad_fig_refs] > 0 } {
	append exception_text "<li>This section contains one or more
	unrecognized figure references: [join $bad_fig_refs ","].\n" 
    }

    return $exception_text
}

# Build a scope selection menu.  This gives the option of making manuals
# viewable by the public or restricted to members of a certain user group.
# The only groups offered are those for which the user is a member.

proc manual_scope_widget {{default_group ""}} {
    # Available groups are specific to each user

    set user_id [ad_verify_and_get_user_id]

    # For group-only administrators just offer the groups for which
    # they have administrative priviledges

    if {[ad_administrator_p $user_id] } {
	set restrictions ""
    } else {
	set restrictions "
	and group_id in 
           (select group_id
	    from   user_group_map
            where  user_group_map.user_id     = :user_id
	    and    lower(user_group_map.role) = 'administrator')"
    }

    # Get the list of available user groups for this user

    if {[empty_string_p $default_group]} {
	set scope_items "<option value=\"\" selected> Public"
    } else {
	set scope_items "<option value=\"\"> Public"
    }

    db_foreach group_info "
    select   group_id, group_name
    from     user_groups
    where    user_groups.group_type <> 'administration'
    $restrictions
    order by group_name" {

	if {$group_id == $default_group} {
	    append scope_items \
		    "<option value=$group_id selected> Restricted to $group_name\n"
	} else {
	    append scope_items \
		    "<option value=$group_id> Restricted to $group_name\n"
	}
    }

    return "
    <tr>
     <th align=right>Scope:</th>
     <td>
     <select name=group_id>$scope_items</select>
     </td>
    </tr>"
}

# Build a radio select for true/false question

proc manual_radio_widget {varname description {default "f"}} {
    upvar $varname current_value

    if {[info exists current_value]} {	
	if {$current_value == "t"} {
	    set checked_t "checked"
	    set checked_f ""
	} else {
	    set checked_t ""
	    set checked_f "checked"
	}
    } else {
	if {$default == "t"} {
	    set checked_t "checked"
	    set checked_f ""
	} else {
	    set checked_t ""
	    set checked_f "checked"
	}
    }

    return "
    <tr>
    <th align=right>$description:</th>
    <td>
    <input type=radio name=$varname value=t $checked_t> Yes
    <input type=radio name=$varname value=f $checked_f> No
    </td>
    </tr>"
}

# -----------------------------------------------------------------------------

# Inserts spacing for the admin TOC

proc manual_spacer {depth} {
    set spacer ""
    for {set i 0} {$i < $depth} {incr i} {
	append spacer "&nbsp;&nbsp;"
    }
    return $spacer
}

# Generates the table of contents for the admin pages

proc manual_toc_admin {manual_id} {

    # get all of the active sections for this manual

    set count 0
    set toc "
    <table cellspacing=0 cellpadding=2 border=0>
    <tr bgcolor=white>
    <td>Top</td>
    <td align=right colspan=4>
    <a href=section-add?manual_id=$manual_id>Add a top-level section</a>
    </td>
    </tr>"

    db_foreach toc_info "
    select   s1.section_id,
             s1.section_title,
             s1.sort_key,
             nvl((select 1 from dual where exists
                  (select *
 	  	   from   manual_sections s2
		   where  s2.manual_id = $manual_id
                   and    s2.active_p  = 't'
		   and    s2.sort_key like substr(s1.sort_key,0,length(s1.sort_key)-2)||'__'
		   and    s2.sort_key > s1.sort_key)),0) as more_children_p
    from     manual_sections s1
    where    s1.manual_id = :manual_id
    and      s1.active_p  = 't'
    order by s1.sort_key" {

	incr count

	if {[expr $count % 2]==0} {
	    set color "white"
	} else {
	    set color "#eeeeee"
	}

	append toc "
	<tr bgcolor=$color>
	<td>[manual_spacer [expr [string length $sort_key]]]<a 
	href=section-edit?[export_url_vars section_id manual_id]>$section_title</a></td>
	<td>&nbsp;</td>"
	
	if {$more_children_p != 0} {
	    append toc "
	    <td>
	    <a href=section-move-2?[export_url_vars section_id manual_id]&move=down>
	    swap with next</a>
	    </td>"
	} else {
	    append toc "<td>&nbsp;</td>"
	}

	append toc "
	<td>
	<a href=section-move?[export_url_vars section_id manual_id]>move</a>
	</td>
	<td>
	<a href=section-add?manual_id=$manual_id&parent_key=$sort_key>add subsection</a>
	</td>
	</tr>"
    }

    return [concat $toc "\n</table>\n"]
}
