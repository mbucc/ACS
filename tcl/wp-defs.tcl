# /tcl/wp-defs.tcl
#
# Author: Jon Salz <jsalz@mit.edu>, 28 Nov 1999
#
# Contains definitions for WimpyPoint.
#
# $Id: wp-defs.tcl,v 3.4.2.3 2000/04/28 15:08:20 carsten Exp $

# Hooks for new stuff and user contributions.

ns_share ad_new_stuff_module_list
ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_new_stuff_module_list] || [lsearch -glob $ad_new_stuff_module_list "*WimpyPoint*"] == -1 } {
    lappend ad_new_stuff_module_list [list "WimpyPoint Presentations" wp_new_stuff]
}
if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "WimpyPoint Presentations" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "WimpyPoint Presentations" wp_user_contributions 0]
}

proc wp_new_stuff { db since_when only_from_new_users_p purpose { include_date_p 0 } { include_comments_p 1 } } {
    if { $only_from_new_users_p == "t" } {
	set users_table "users_new"
    } else {
	set users_table "users"
    }

    if { $purpose == "site_admin" } {
	set and_public ""
    } else {
	set and_public "and public_p = 't'"
    }

    set selection [ns_db select $db "
        select p.presentation_id, p.title, to_char(creation_date, 'Mon DD, YYYY') as creation_date,
               p.public_p,
               u.user_id, u.first_names, u.last_name
        from wp_presentations p, $users_table u
        where p.creation_user = u.user_id
        and   creation_date > '$since_when' $and_public
        order by creation_date desc
    "]

    set counter 0
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	switch $purpose {
	    email_summary {
		if { $include_date_p } {
		    append items "$creation_date: "
		}
		append items "$title -- [ad_url][wp_presentation_url]/$presentation_id/\n"
	    }
	    default {
		append items "<li>"
		if { $include_date_p } {
		    append items "$creation_date: "
		}
		append items "<a href=\"[wp_presentation_url]/$presentation_id/\">$title</a> ($first_names $last_name"
		if { $public_p == "f" } {
		    append items " - private"
		}
		append items ")\n"
	    }
	}
    }

    if { ![empty_string_p $items] } { 
	return "<ul>$items</ul>" 
    } else {
	return ""
    }
}

proc wp_user_contributions { db user_id purpose } {
    if { $purpose == "site_admin" || $user_id == [ad_verify_and_get_user_id] } {
	set and_public ""
    } else {
	set and_public "and public_p = 't'"
    }

    set selection [ns_db select $db "
        select p.presentation_id, p.title, to_char(creation_date, 'Mon DD, YYYY') as creation_date,
               p.public_p,
               u.user_id, u.first_names, u.last_name
        from wp_presentations p, users u
        where p.creation_user = u.user_id $and_public
        and   u.user_id = $user_id
        order by creation_date desc
    "]

    set items ""
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query

	append items "<li><a href=\"[wp_presentation_url]/$presentation_id/\">$title</a>"
	if { $public_p == "f" } {
	    append items " (private)"
	}
	append items "\n"
    }

    #ns_log "Warning" "{{items is $items}}"

    if [empty_string_p $items] {
	return [list]
    } else {
	return [list 0 "WimpyPoint Presentations" "<ul>\n$items\n</ul>"]
    }
}

proc_doc wp_help_header { title } { Returns a help header for WimpyPoint. } {
    return "[ad_header $title]
<h2>$title</h2>
<a href=\"javascript:history.back()\">Return to WimpyPoint</a>
<hr>
"

}

proc_doc wp_header args { Returns a header for WimpyPoint. } {
    return [wp_header_intl "*NONE*" $args]
}

proc_doc wp_header_form { form args } { Returns a header for WimpyPoint. } {
    return [wp_header_intl $form $args]
}

proc wp_header_intl { form argv } {
    set title [lindex $argv end]

    set help [help_link]
    if { $help != "" } {
	set help "<table align=right cellspacing=0 cellpadding=0><tr><td>$help</td></tr></table>"
    } else {
	set help ""
    }

    return "[ad_header $title]
<form $form>
<h2>$title</h2>
[wp_context_bar $argv]
<hr>
$help
"
}

proc_doc wp_check_numeric { num } { Verifies that $num is numeric; otherwise bails (someone is playing games with us). } {
    expr double($num)
    return $num
}

proc_doc wp_footer {} { Returns a footer for WimpyPoint. } {
    set footer [ad_footer]

    return $footer
}

proc_doc wp_access { db presentation_id user_id { priv "read" } } { Returns the user's actual level, if the user can perform $priv roles on the presention. } {
    return [database_to_tcl_string $db "
        select wp_access(presentation_id, $user_id, '$priv', public_p, creation_user, group_id)
        from wp_presentations
        where presentation_id = $presentation_id
    "]
}

proc_doc wp_check_authorization { db presentation_id user_id { priv "read" } } { Verifies that the user can perform $priv roles on the presentation, returning an error and bailing if not. If authorized, returns the level at which the user is actually authorized. } {
    set auth [wp_access $db $presentation_id $user_id $priv]
    if { $auth == "" } {
	ad_return_error "Authorization Failed" "You do not have the proper authorization to access this feature."
	return -code return
    }
    return $auth
}

proc_doc wp_check_style_authorization { db style_id user_id } { Verifies that the user owns this style. } {
    if { [database_to_tcl_string $db "select owner from wp_styles where style_id = [wp_check_numeric $style_id]"] != $user_id } {
	ad_return_error "Authorization Failed" "You do not have the proper authorization to access this feature."
	return -code return
    }
}

proc_doc wp_ljoin { list values } { Appends each of values (a list) to the list. } {
    upvar $list ll
    foreach v $values {
	lappend ll $v
    }
}

proc_doc wp_select { db sql code { else "" } { elsecode "" } } { Performs a select, setting variables and executing code for each record. } {
    uplevel set selection [ns_db select $db $sql]
    set counter 0
    while { [uplevel "ns_db getrow $db " \$selection] } {
	uplevel set_variables_after_query
	uplevel $code
	incr counter
    }
    if { $else == "else" } {
	if { $elsecode == "" } {
	    error "no else code provided"
	} elseif { $counter == 0 } {
	    uplevel $elsecode
	}
    } elseif { $else != "" } {
	error "invalid syntax (expected else)"
    }
}

proc_doc wp_nextval { db seq } { Returns the next value of a sequence. } {
    return [database_to_tcl_string $db "select $seq.nextval from dual"]
}

proc_doc wp_prepare_dml { table names values { condition "" } } { Prepares a DML statement with columns names and value values. If condition is empty, does an insert - otherwise does an update. } {
    if { $condition == "" } {
	return "insert into ${table}([join $names ",\n  "])\nvalues([join $values ",\n  "])"
    } else {
	set sql "update $table set "
	for { set i 0 } { $i < [llength $names] } { incr i } {
	    if { $i != 0 } {
		append sql ",\n  "
	    }
	    append sql "[lindex $names $i] = [lindex $values $i]"
	}
	append sql "\nwhere $condition"
	return $sql
    }
}

proc_doc wp_clob_dml { db sql clobs } { Executes a DML, optionally with up to 3 clobs. } {
    if { [llength $clobs] == 0 } {
	ns_db dml $db $sql
    } else {
	set clist [list]

	set returning_names [list]
	set returning_vars [list]
	set counter 0
	foreach clob $clobs {
	    incr counter
	    lappend returning_names [lindex $clob 0]
	    lappend returning_vars ":$counter"
	    lappend clist [lindex $clob 1]
	}
	append sql " returning [join $returning_names ","] into [join $returning_vars ","]"
	switch [llength $clobs] {
	    1 { ns_ora clob_dml $db $sql [lindex $clist 0] }
	    2 { ns_ora clob_dml $db $sql [lindex $clist 0] [lindex $clist 1] }
	    3 { ns_ora clob_dml $db $sql [lindex $clist 0] [lindex $clist 1] [lindex $clist 2] }
	    default { error "wp_clob_dml support only up to 3 clobs." }
	}
    }
}

proc_doc wp_try_dml_or_break { db sql { clobs "" } } { Calls wp_try_dml, returning if it fails. } {
    if { [wp_try_dml $db $sql $clobs] } {
	return -code return
    }
}

proc_doc wp_try_dml { db sql { clobs "" } } { Tries to execute a DML statement, optionally with clobs. If it fails, ns_writes an error and returns 1. } {
    if { [catch { wp_clob_dml $db $sql $clobs } err] } {
	ad_return_error "Error" "The following error occurred while trying to write to the database:

<blockquote><pre>[philg_quote_double_quotes $err]</pre></blockquote>

Please <a href=\"javascript:history.back()\">back up and try again</a>."
        return 1
    }
    return 0
}

proc_doc wp_context_bar { argv } "Returns a Yahoo-style hierarchical navbar, starting with a link to workspace." {
    if { [ad_get_user_id] == 0 } {
	set choices [list]
    } else {
	set choices [list "<a href=\"[ad_pvt_home]\">Your Workspace</a>"]
    }
    set index 0
    foreach arg $argv {
	incr index
	if { $arg == "" } {
	    continue
	}
	if { $index == [llength $argv] } {
	    lappend choices $arg
	} else {
	    lappend choices "<a href=\"[lindex $arg 0]\">[lindex $arg 1]</a>"
	}
    }
    return [join $choices " : "]
}

proc wp_serve_style {} {
    set url [ns_conn url]

    # Grok the URL.
    if { ![regexp {/(default|[0-9]+)/((.+)\.css|(.+))$} $url all style_id filename serve_css serve_file] } {
	ns_returnnotfound
	return
    }
    set db [ns_db gethandle]
    if { $style_id == "default" } {
	set style_id -1
    }

    if { $serve_css != "" } {
	# Requested file "<something>.css" - serve up the CSS source.
	set css [database_to_tcl_string $db "select css from wp_styles where style_id = $style_id"]
	ns_return 200 "text/css" $css
    } else {
	# Requested a particular file. Find the mime type and send the file.
	ReturnHeaders [database_to_tcl_string $db "
            select mime_type
            from wp_style_images
            where style_id = $style_id
            and file_name = '[DoubleApos $serve_file]'
        "]
	ns_ora write_blob $db "
            select image
            from wp_style_images
            where style_id = $style_id
            and file_name = '[DoubleApos $serve_file]'
        "
    }

    ns_db releasehandle $db
}

proc_doc wp_slide_header { presentation_id title style text_color background_color background_image link_color vlink_color alink_color } { Generates a header for slides. } {
    if { $style == "" || $style == -1 } {
	set style "default"
    }

    set out "
<html>
<head>
  <link rel=stylesheet href=\"[wp_style_url]/$style/style.css\" type=\"text/css\">
  <title>$title</title>
</head>
<body"
    if { $background_image != "" } {
	append out " background=\"[wp_style_url]/$style/$background_image\""
    }
    foreach property {
	{ text text_color }
	{ bgcolor background_color }
	{ link link_color }
	{ vlink vlink_color }
	{ alink alink_color }
    } {
	set value [set [lindex $property 1]]
	if { $value != "" } {
	    append out " [lindex $property 0]=[ad_color_to_hex $value]"
	}
    }
    append out ">\n"
    return $out
}

proc_doc wp_slide_footer { presentation_id page_signature { timer_start "" } } { Generates a footer for slides, including a timer at the bottom. Use $timer_start of "style" for style selection instead. } {

    if { $timer_start == "" } {
	set time_str ""
    } elseif { $timer_start == "style" } {
	set time_str "<a href=\"javascript:window.open('../../override-style.tcl', '_blank', 'width=400,height=250').focus()\">change style</a>"
    } else {
	set elapsed [expr int(([ns_time] - $timer_start) / 60)]
	if { $elapsed >= 3 } {
	    set time_str "$elapsed minutes"
	} else {
	    set time_str ""
	}
    }

    return "
  <hr>

  <table width=100% cellspacing=0 cellpadding=0>
    <tr>
      <td align=left>$page_signature
      <td align=right>$time_str</td>
    </tr>
  </table>
</body>
</html>
"
}

proc_doc wp_break_attachments { attach which } { Searches through $attach, a list of id/file_size/file_name/display lists, for items where display = $which. If any are found, generates a <br clear=all>. } {
    foreach item $attach {
	if { [lindex $item 3] == $which } {
	    return "<br clear=all>"
	}
    }
    return ""
}

proc_doc wp_show_attachments { attach which align } { Searches through $attach, a list of id/file_size/file_name/display lists, for items where display = $which, and displays them aligned right or center or linked. } {
    set out ""
    foreach item $attach {
	if { [lindex $item 3] == $which } {
	    if { $align == "link" } {
		if { $out != "" } {
		    append out " / "
		}
		append out "<a href=\"[wp_attach_url]/[lindex $item 0]/[philg_quote_double_quotes [lindex $item 2]]\">[philg_quote_double_quotes [lindex $item 2]]
([expr { [lindex $item 1] / 1024 }]K)</a>"
	    } else {
		if { $align == "center" } {
		    append out "<center>"
		}
		append out "<img src=\"[wp_attach_url]/[lindex $item 0]/[philg_quote_double_quotes [lindex $item 2]]\""
		if { $align == "right" } {
		    append out " align=right>\n"
		} else {
		    append out "></center>\n"
		}
	    }
	}
    }
    if { $align == "link" && $out != "" } {
	append out "<p>\n"
    }
    return $out
}

proc wp_serve_presentation { conn edit } {
    set url [ns_conn url]
    if { ![regexp {/([0-9]+)(-v([0-9]+))?(/((break)?([0-9]+|index)\.wimpy)?)?$} $url \
           all presentation_id version_dot version after file_name break slide_id] } {
	ns_returnnotfound
	return
    }
    if { $after == "" } {
	ad_returnredirect "$presentation_id/"
	return
    }

    if { $version == "" } {
	set version_condition "max_checkpoint is null"
	set version_or_null "null"
    } else {
	set version_condition "wp_between_checkpoints_p($version, min_checkpoint, max_checkpoint) = 't'"
	set version_or_null $version
    }

    set db [ns_db gethandle]
    set auth [wp_check_authorization $db $presentation_id [ad_verify_and_get_user_id] "read"]

    set selection [ns_db 1row $db "
        select p.*, u.first_names, u.last_name
        from   wp_presentations p, users u
        where  p.presentation_id = $presentation_id
        and    p.creation_user = u.user_id
    "]
    set_variables_after_query

    # See if the user has overridden the style preferences.
    regexp {wp_override_style=(-?[0-9]+)} [ns_set get [ns_conn headers] Cookie] all style

    if { $style == "" } {
	set style -1
    }

    set selection [ns_db 1row $db "select * from wp_styles where style_id = $style"]
    set_variables_after_query

    set user_id [ad_verify_and_get_user_id]

    if { [regexp {wp_back=([^;]+)} [ns_set get [ns_conn headers] Cookie] all back] } {
	set back [ns_urldecode $back]
    } else {
	set back "../../"
    }

    # Set the timer cookie, if not already set.
    if { [regexp {wp_timer=([0-9]+),([0-9]+)} [ns_set get [ns_conn headers] Cookie] all timer_presentation_id timer_start] &&
         $timer_presentation_id == $presentation_id } {
	set cookie ""
    } else {
	set timer_start [ns_time]
	set cookie "Set-Cookie: wp_timer=$presentation_id,$timer_start; path=/\n"
    }

    set referer [ns_set get [ns_conn headers] Referer]
    if { $break != "break" && [regexp {(/wimpy/|/(index|one-user|search|presentation-top|presentations-by-date)\.tcl)(\?|$)} $referer] } {
	# Try to remember how the user got here.
	append cookie "Set-Cookie: wp_back=[ns_urlencode $referer]; path=/\n"
	set back $referer
    }

    if { $slide_id == "index" || $file_name == "" || $break == "break" } {
	# Serve a presentation index page.

	    ns_write "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: text/html
$cookie
[wp_slide_header $presentation_id $title $style $text_color $background_color $background_image $link_color $vlink_color $alink_color]

"

        set first ""
        set out ""

        # How should we get a list of slides in the presentation? Depends on
        # whether we're looking at the most recent version, or a historical
        # copy.
        if { $version == "" } {
	    set sql "
                select slide_id id, title slide_title
	        from wp_slides
	        where presentation_id = $presentation_id
                and   $version_condition
	        order by sort_key
            "
	} else {
	    set sql "
                select s.slide_id id, s.title slide_title
	        from wp_slides s, wp_historical_sort h
	        where s.slide_id = h.slide_id
                and   h.checkpoint = $version
                and   s.presentation_id = $presentation_id
                and   $version_condition
	        order by h.sort_key
	    "
	}
	set before_break ""
	set previous ""
	wp_select $db $sql {
	    if { $id == $slide_id } {
		set before_break $previous
	    }
	    set previous $id

	    append out "    <li>"
	    if { $break == "break" } {
		# Context break: the only slide linked is the next slide.
		if { $id == $slide_id } {
		    append out "<a href=\"$id.wimpy\"><font color=red><b>$slide_title</b></font></a>\n"
		} else {
		    append out "$slide_title\n"
		}
	    } else {
		append out "<a href=\"$id.wimpy\">$slide_title</a>\n"
	    }
	    if { $first == "" } {
		set first $id
	    }
	}

	set menu_items [list]

	if { $break == "break" } {
	    lappend menu_items "<a href=\"$before_break.wimpy\">previous</a>"
	    lappend menu_items "<a href=\"\">top</a>"
	} else {
	    lappend menu_items "<a href=\"$back\">done</a>"
	}
	if { $edit } {
	    lappend menu_items "<a href=\"../../presentation-top.tcl?presentation_id=$presentation_id\">edit</a>"
	}
	if { $break == "break" } {
	    if { $slide_id != "" } {
		lappend menu_items "<a href=\"$slide_id.wimpy\">next</a>"
	    }
	} else {
	    if { $first != "" } {
		lappend menu_items "<a href=\"$first.wimpy\">next</a>"
	    }
	}

	if { $edit && $auth != "read" } {
	    set comments [ad_general_comments_list $db $presentation_id "wp_presentations" $title "wp"]
	} else {
	    set comments ""
	}

	set collaborators ""
	wp_select $db "
	    select u.first_names collaborator_first, u.last_name collaborator_last, u.user_id collaborator_user
            from   users u, user_group_map m
            where  m.group_id = $group_id
            and    (m.role = 'write' or m.role = 'admin')
            and    m.user_id = u.user_id
        " {
	    lappend collaborators "<a href=\"/shared/community-member?user_id=$collaborator_user\">$collaborator_first $collaborator_last</a>"
	}
	if { [llength $collaborators] != 0 } {
	    if { [llength $collaborators] <= 2 } {
		set collaborators_str "<br>in collaboration with [join $collaborators " and "]"
	    } else {
		set collaborators [lreplace $collaborators end end "and [lindex $collaborators end]"]
		set collaborators_str "<br>in collaboration with [join $collaborators ", "]"
	    }
	} else {
	    set collaborators_str ""
	}

	ns_write "
<table cellspacing=0 cellpadding=0 align=right>
  <tr><td>[join $menu_items " | "]</td></tr>
</table>

<h2>$title</h2>
a <a href=\"$back\">WimpyPoint</a> presentation owned by <a href=\"/shared/community-member.tcl?user_id=$creation_user\">$first_names $last_name</a> $collaborators_str

<hr>
<ul>
$out
</ul>

[expr { $copyright_notice != "" ? "<p>$copyright_notice" : "" }]

$comments

[wp_slide_footer $presentation_id $page_signature [expr { $break == "break" ? $timer_start : "style" }]]
"
    } else {
	# Serve slide $slide_id.

	# Different ways of determining previous/next slide when versioning.
	# XXX: Consolidate these (they're almost identical).
	if { $version == "" } {
	    set selection [ns_db 1row $db "
                select title,
                       preamble, bullet_items, postamble,
                       include_in_outline_p, context_break_after_p, modification_date,
                       wp_previous_slide(sort_key, presentation_id, $version_or_null) previous, wp_next_slide(sort_key, presentation_id, $version_or_null) next,
	               nvl(original_slide_id, slide_id) original_slide_id
                from   wp_slides
                where  slide_id = [wp_check_numeric $slide_id]
                and    presentation_id = [wp_check_numeric $presentation_id]
            "]
	} else {
	    set selection [ns_db 1row $db "
                select title,
                       preamble, bullet_items, postamble,
                       include_in_outline_p, context_break_after_p, modification_date,
                       wp_previous_slide((select sort_key from wp_historical_sort where slide_id = $slide_id and checkpoint = $version), presentation_id, $version) previous,
                       wp_next_slide((select sort_key from wp_historical_sort where slide_id = $slide_id and checkpoint = $version), presentation_id, $version) next,
	               nvl(original_slide_id, slide_id) original_slide_id
                from   wp_slides
                where  slide_id = [wp_check_numeric $slide_id]
                and    presentation_id = [wp_check_numeric $presentation_id]
            "]
	}
	set_variables_after_query

	set menu_items [list]

	if { $previous != "" } {
	    lappend menu_items "<a href=\"$previous.wimpy\">previous</a>"
	}
	lappend menu_items "<a href=\"\">top</a>"
	if { $edit } {
	    lappend menu_items "<a href=\"../../slide-edit.tcl?presentation_id=$presentation_id&slide_id=$slide_id\">edit</a>"
	    lappend menu_items "<a href=\"../../slide-delete.tcl?presentation_id=$presentation_id&slide_id=$slide_id\">delete</a>"
	}
	if { $next != "" } {
	    if { $context_break_after_p == "t" } {
		lappend menu_items "<a href=\"break$next.wimpy\">next</a>"
	    } else {
		lappend menu_items "<a href=\"$next.wimpy\">next</a>"
	    }
	} elseif { $edit } {
	    lappend menu_items "<a href=\"../../presentation-top.tcl?presentation_id=$presentation_id\">done</a>"
	}

	ns_write "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: text/html
$cookie
[wp_slide_header $presentation_id $title $style $text_color $background_color $background_image $link_color $vlink_color $alink_color]

<table cellspacing=0 cellpadding=0 align=right>
  <tr><td>[join $menu_items " | "]</td></tr>
</table>

<h2>$title</h2>
"

	# Get attachments, if any.
	set attach [list]
	wp_select $db "
            select attach_id, file_size, file_name, display
            from   wp_attachments
            where  slide_id = $slide_id
            order by lower(file_name)
        " {
	    lappend attach [list $attach_id $file_size $file_name $display]
	}

	if { $edit && $auth != "read" } {
	    set comments [ad_general_comments_list $db $original_slide_id "wp_slides" $title "wp"]
	} else {
	    set comments ""
	}

	ns_write "

<hr>
[wp_show_attachments $attach "" "link"]

[wp_show_attachments $attach "top" "center"]
[wp_show_attachments $attach "preamble" "right"]

$preamble
[wp_break_attachments $attach "preamble"]
[wp_show_attachments $attach "after-preamble" "center"]
"

        ns_write "
[wp_show_attachments $attach "bullets" "right"]
[expr { $bullet_items != "" ? "<ul>\n<li>[join $bullet_items "<li>\n"]\n" : ""}]
"

        ns_write [wp_break_attachments $attach "bullets"]

ns_write "
[expr { $bullet_items != "" ? "</ul>" : "</p>" }]
"
        ns_write [wp_show_attachments $attach "after-bullets" "center"]

        ns_write "
[wp_show_attachments $attach "postamble" "right"]

$postamble

[wp_break_attachments $attach "postamble"]
[wp_show_attachments $attach "bottom" "center"]
"

        ns_write "
[expr { $show_modified_p == "t" ? "<p><i>Last modified $modification_date</i>" : "" }]
[expr { $copyright_notice != "" ? "<p>$copyright_notice" : "" }]

$comments

[wp_slide_footer $presentation_id $page_signature $timer_start]
"
    }

}

proc wp_serve_attach {} {
    set user_id [ad_verify_and_get_user_id]

    if { ![regexp {([^/]+)/([^/]+)$} [ns_conn url] match attach_id client_filename] } {
        ad_return_error "Malformed Attachment Request" "Your request for a file attachment was malformed."
        return
    }
    set db [ns_db gethandle]

    set selection [ns_db 1row $db "
        select s.presentation_id, a.slide_id, a.attach_id, a.mime_type
        from   wp_slides s, wp_attachments a
        where  attach_id = $attach_id
        and    s.slide_id = a.slide_id
    "]
    set_variables_after_query
    wp_check_authorization $db $presentation_id $user_id

    ReturnHeaders $mime_type

    ns_ora write_blob $db "select attachment from wp_attachments where attach_id = $attach_id"
    
    ns_db releasehandle $db
}


proc_doc wp_style_url {} { Returns the StyleURL parameter (no trailing slash). } {
    set url [ad_parameter "StyleURL" wp "/wp/style/"]
    regsub {/$} $url "" url
    return $url
}

proc_doc wp_presentation_url {} { Returns the PresentationURL parameter (no trailing slash). } {
    set url [ad_parameter "PresentationURL" wp "/wp/display/"]
    regsub {/$} $url "" url
    return $url
}

proc_doc wp_presentation_edit_url {} { Returns the PresentationEditURL parameter (no trailing slash). } {
    set url [ad_parameter "PresentationEditURL" wp "/wp/display-edit/"]
    regsub {/$} $url "" url
    return $url
}

proc_doc wp_attach_url {} { Returns the AttachURL parameter (no trailing slash). } {
    set url [ad_parameter "AttachURL" wp "/wp/attach/"]
    regsub {/$} $url "" url
    return $url
}

proc_doc wp_only_if { condition text { elsetext "" } } { If condition, returns text; otherwise returns elsetext. } {
    if [uplevel expr "{ $condition }"] {
	return $text
    } else {
	return $elsetext
    }
}

proc_doc wp_role_predicate { role { title "" } } { Returns a plain-English string describing an role (read/write/admin). } {
    if { $title != "" } {
	set space " "
    } else {
	set space ""
    }

    if { $role == "read" } {
	return "view the presentation$space$title"
    } elseif { $role == "write" } {
	return "view and make changes to the presentation$space$title"
    } elseif { $role == "admin" } {
	return "view and make changes to the presentation$space$title, and decide who gets to view/edit it"
    }
    error "role must be read, write, or admin"
}	

proc_doc wp_short_role_predicate { role { title "" } } { Returns a short plain-English string describing an role (read/write/admin). } {
    if { $title != "" } {
	set space " "
    } else {
	set space ""
    }

    if { $role == "read" } {
	return "view the presentation$space$title"
    } elseif { $role == "write" || $role == "admin" } {
	return "work on the presentation$space$title"
    }
    error "role must be read, write, or admin"
}

proc_doc wp_slider { which current items } { Generates a slider for form variable $which with items $items, of the form { { 1 "One" } { 2 "Two" } }, where 1/2 are the query values and One/Two are the corresponding labels. } {
    set choices ""

    regexp {/([^/]*)$} [ns_conn url] "" dest_url
    if { $dest_url == "" } {
	set dest_url "index.tcl"
    }

    foreach i $items {
	set newval [lindex $i 0]
	set label [lindex $i 1]

	if { $current != $newval } {
	    # Not currently selected - generate the link.
	    lappend choices "<a href=\"$dest_url?[ export_ns_set_vars "url" $which ]&$which=$newval\">$label</a>"
	} else {
	    # Currently selected.
	    lappend choices "<b>$label</b>"
	}
    }

    return "\[ [join $choices " | "] \]"
}

ns_register_proc GET [wp_style_url] wp_serve_style
ns_register_proc GET [wp_presentation_url] wp_serve_presentation 0
ns_register_proc GET [wp_presentation_edit_url] wp_serve_presentation 1
ns_register_proc GET [wp_attach_url] wp_serve_attach
