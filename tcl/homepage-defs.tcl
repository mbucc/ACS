# namin@arsdigita.com

ad_library {
    Homepage Module Private Tcl

    @creation-date     Mon Jan 10 21:06:26 EST 2000
    @author Usman Y. Mobin (mobin@mit.edu)
    @cvs-id homepage-defs.tcl,v 3.5.2.10 2000/09/25 14:51:21 kevin Exp
}

ad_register_proc -noinherit t GET /users hp_serve_index

# This will register the procedure users_serve
# to serve all requested files starting with
# /users
ad_register_proc GET /users/* hp_serve

proc hp_serve { conn context } {

    set url_stub [ns_conn url]
    if {[regexp {/users/([^/]*)(.*)/*} $url_stub match scr_name relative_filename]} {
	# we have a valid match
	
	#ns_log Notice "select user_id as uid 
	#from users 
	#where screen_name='$scr_name'"

	# get the user_id of the owner
	if { ![db_0or1row user_info {
	    select user_id as u_id,
	    first_names as f_nm,
	    last_name as l_nm,
	    email as u_email
	    from users 
	    where screen_name=:scr_name
	}] } {
	    db_release_unused_handles

	    # no rows returned
	    ns_returnnotfound
	    return	
	}
	# retrieve the portrait information
	set portrait_original_width ""
	set portrait_original_height ""
	set portrait_p [db_0or1row portrait_info {
	    select portrait_id, 
	           portrait_upload_date,
	           portrait_original_width,
	           portrait_original_height
	    from   general_portraits
            where  on_what_id = :u_id
	    and    upper(on_which_table) = 'USERS'
	    and    approved_p = 't'
	    and    portrait_primary_p = 't' 
	}]
	    
	if { ![empty_string_p $portrait_original_width] && ![empty_string_p $portrait_original_height] } {
	    set widthheight "width=$portrait_original_width height=$portrait_original_height"
	} else {
	    set widthheight ""
	}
	    
	if {![info exists u_id] || [empty_string_p $u_id]} {
	    
	    db_release_unused_handles
	    
	    # if u_id is null then the above query gave no results
	    # which implies that the screen name was invalid
		ad_return_error "Error in obtaining file" "There was an error in obtaining the requested file"
	    # And we also log the error
	    ns_log Error "/tcl/homepage-defs.tcl: Function hp_serve failed to find the requested file"
	    # And since we have nothing else better to do, we'll return
	    return
	    
	}
	
	if {![info exists relative_filename] || [empty_string_p $relative_filename]} {
	    set relative_filename ""
	}
	
	set full_filename "[ad_parameter ContentRoot users]$u_id$relative_filename"
	
	set file_exists_p [file exists $full_filename]
	if {$file_exists_p == 0} {
	    db_release_unused_handles
	    ns_returnnotfound
	    return
	}   
	
	set u_root_node [db_string u_root_node {
	    select hp_get_filesystem_root_node(:u_id)
	    from dual
	}]
		
	set dir_node [db_string dir_node {
	    select hp_fs_node_from_rel_name(:u_root_node,:relative_filename)
	    from dual
	}]
		    
	set top_node [db_string top_node {
	    select hp_onelevelup_content_node(:dir_node) 
	    from dual
	}]
			
	set managed_p [db_string managed_p {
	    select managed_p 
	    from users_files
	    where file_id=:dir_node
	}]
			    
	if {$managed_p} {
	    db_1row select_content_title {
		select hp_onelevelup_content_title(:dir_node) as content_title,
		(select type_name 
		from users_content_types
		where type_id = (select content_type
		from users_files
		where file_id=:top_node)) as content_type,
		(select sub_type_name 
		from users_content_types
		where type_id = (select content_type
		from users_files
		where file_id=:top_node)) as content_sub_type
		from dual
	    }
	}
	
	# Are we serving a directory?
	set dir_p [file isdirectory $full_filename]
	
	# Are we serving the user's home directory?
	set userhome_p 0
	
	if {$relative_filename == ""} {
	    set userhome_p 1
	}
	
	# mobin: debug code
	# ad_return_error "[ns_guesstype $full_filename]" "[ns_guesstype $full_filename]"
	
	# This where we serve the files.
	
	if {!$dir_p} {
	    # If we're not serving a directory
	    
	    if {$managed_p} {
		
		db_1row select_hp_serve_file_info {
		    select filename, file_pretty_name
		    from   users_files
		    where  file_id=:dir_node
		    and owner_id=:u_id
		}
		
		db_release_unused_handles
		
		set html ""
		
		set text_file "$full_filename"
		
		if {[file exists $text_file]} {
		    set texthandle [open $text_file r]
		    set text_text [read $texthandle]
		    close $texthandle
		    append html $text_text
		}

		set generated_title "$filename - $file_pretty_name"
		# Generate page.
		doc_return  200 text/html "
		[hp_header "$generated_title" $u_id 0]
		[hp_page_title "$content_title" $u_id "$generated_title" 0]
		<hr>
		$html
		[ad_footer "$u_email"]
		"		
		
		
	    } else {
		# This line will return the file with its guessed
		# mimetype.
		ad_returnfile 200 [ns_guesstype $full_filename] $full_filename
	    }
	} else {
	    
	    db_release_unused_handles
	    
	    # serve directory. Generate index page.
	    
	    if {[expr [string last "/" $full_filename] + 1] != [string length $full_filename]} {
		set full_filename "$full_filename/"
		set relative_filename "$relative_filename/"
		ad_returnredirect "/users/$scr_name$relative_filename"
		return
	    }
	    
	    # mobin debug code
	    # doc_return  200 text/plain "$full_filename $scr_name $relative_filename"
	    # return
	    
	    set index_page ""
	    
	    set index_file_candidacy_list [ad_parameter IndexFilenameCandidacyList users]
	    
	    set index_file_candidacy_list_length [llength $index_file_candidacy_list]
	    
	    set index_flag 0
	    set counter 0
	    while {$index_flag == 0 && $counter < $index_file_candidacy_list_length} {
		set index_file_candidate [lindex $index_file_candidacy_list $counter]
		if {[file exists "$full_filename$index_file_candidate"]} {
		    set index_page $index_file_candidate
		    set index_flag 1
		} else {
		    set counter [expr $counter + 1]
		}
	    }
	    
	    if {$index_page == ""} {
		set index_page_p 0
	    } else {
		set index_page_p 1
	    }
	    
	    # If this is managed content then we ignore index files
	    if {$managed_p} {
		set index_page_p 0
	    }
	    
	    # This is where it comes to when we are serving a directory
	    if {$index_page_p == 1} {
		# We have an index page. Well and Good. We don't have to
		# generate one for this directory.
		set file_to_serve "$full_filename$index_page"
		ad_returnfile 200 [ns_guesstype $file_to_serve] $file_to_serve
		
	    } else {

		# If the directory we're serving is managed
		if {$managed_p} {
		    # We have extra variables
		    # content_title, content_type, content_sub_type		
		    set html ""

		    set intro_file "$full_filename"
		    append intro_file "Introductory Text"

		    if {[file exists $intro_file]} {
			set introhandle [open $intro_file r]
			set intro_text [read $introhandle]
			close $introhandle
			append html $intro_text
		    }

		    append html "<blockquote>
		    <font size=+2>Table of Contents:</font>
		    <p>"
		    
		    db_foreach content_listing {
			select filename, file_pretty_name, directory_p
			from users_files
			where parent_id=:dir_node
			and owner_id=:u_id
			and managed_p='t'
			and modifyable_p='t'
			order by directory_p desc, filename asc
		    } {
			if {$directory_p} {
			    append html "
			    <a href=\"/users/$scr_name$relative_filename$filename\">$filename</a> - $file_pretty_name<br>"
			} else {
			    append html "
			    <a href=\"/users/$scr_name$relative_filename$filename\">$filename</a> - $file_pretty_name<br>"
			}
		    } if_no_rows {
			append html "<br>There is not a single $content_sub_type in this $content_type"
		    }
		    
		    db_release_unused_handles

		    append html "</blockquote>
		    "

		    set generated_title "$content_title"
		    # Generate an index page.
		    doc_return  200 text/html "
		    [hp_header "$generated_title" $u_id 0]
		    [hp_page_title "A $content_type at $f_nm $l_nm's webspace at [ad_parameter SystemName]" $u_id $content_title 0]
		    <hr>
		    $html
		    [ad_footer "$u_email"]
		    "		

		} else {
		    # If the directory we're serving is not managed and
		    # does not have an index page

		    # We need to generate the page
		    set html "
		    Contents of this folder:<br>
		    <ul>"
		    
		    if {$dir_node != $u_root_node} {
			append html "<img src=/homepage/back.gif>
			<a href=\"/users/$scr_name$relative_filename../\">Parent Directory</a><font size=-1> \[click here to go one level up\]</font><br>"
		    }
		    
		    db_foreach files_list {
			select filename, file_pretty_name, directory_p
			from users_files
			where parent_id=:dir_node
			and owner_id=:u_id
			order by directory_p desc, filename asc
		    } {
			if {$directory_p} {
			    append html "<img src=/homepage/dir.gif>
			    <a href=\"/users/$scr_name$relative_filename$filename\">$filename</a> - $file_pretty_name<br>"
			} else {
			    append html "<img src=/homepage/doc.gif>
			    <a href=\"/users/$scr_name$relative_filename$filename\">$filename</a> - $file_pretty_name<br>"
			}
		    } if_no_rows {
			append html "<br>nothing here.<br>"
		    }

		    db_release_unused_handles

		    append html "</ul>"
		    
		    # Get the full name of the user
		    set full_username "$f_nm $l_nm"
		    
		    set generated_title "$full_username's homepage"
		    # Generate an index page.
		    doc_return  200 text/html "
		    [hp_header "$generated_title" $u_id 0]
		    [hp_page_title "webspace at [ad_parameter SystemName]" $u_id $full_username $portrait_p "$widthheight"]
		    <hr>
		    $html
		    [ad_footer "$u_email"]
		    "		
		}
	    }
	}

	# remove this return if you want to log file accesses
	# I don't want to right now.
	# return
	# I do want to, now!

	# And now, we need to get th IP address of the user
	set user_ip [ns_conn peeraddr]

	# Update the log table by inserting the log entry for
	# this particular download.

	db_dml access_log_insert {
	    insert into users_files_access_log
	    (access_id, file_id, relative_filename, owner_id, access_date,ip_address)
	    values
	    (users_access_id_sequence.nextval, :dir_node,
	    :relative_filename,:u_id,sysdate,:user_ip)
	}
	
	db_release_unused_handles

	# And we're also done with serving this file.
	return
	
    } else {
	db_release_unused_handles
	
	# regexp didn't match => not a valid filename
	# Since we can't do anything useful here, let's just
	# throw an error for fun
	ad_return_error "Invalid Filename" "The filename requested does not exist."
	# And log the error also
	ns_log Error "/tcl/users.tcl: 
	Function users_serve failed to map the url to a valid filename"
	# And there's nothing else to do, so we return.
	return
    }
    
}

# This procedure validates a date. <mobin>never tested this one</mobin>
proc hp_date_valid_p {input_date} {

    with_catch errmsg {
	db_string valid_date_test {
	    select to_date(:input_date, 'YYYY-MM-DD') from dual
	}

	set date_valid_p 1
    } {
	set date_valid_p 0
    }

    db_release_unused_handles
    return $date_valid_p

}

proc hp_page_title {page_title user_id user_fullname {show_portrait_p 0} {widthheight ""}} {

    if {$show_portrait_p == 1} {
	# show the portrait. It must exist!
	return [ad_decorate_top "<h2><b>$user_fullname</b></h2><h4>$page_title<h4>" \
		"<img $widthheight src=\"/shared/portrait-bits?[export_url_vars user_id]\" ALT=Portrait>"]
    } else {

	# portrait does not exist and is not being shown
	return "
	<h2><b>$user_fullname</b></h2>
	$page_title
	"
    }
}

proc hp_header {title user_id {maint_p 0}} {

    return "
    <html>
    <head>
    <title>$title</title>
    <LINK REL=stylesheet TYPE=\"text/css\" HREF=\"/homepage/get-display?user_id=$user_id&maint_p=$maint_p\">
    </head>
    <body>
    "

}

proc mobin_number_to_letter { letter_no } {

    set letter [ad_decode $letter_no 1 A 2 B 3 C 4 D 5 E 6 F 7 G 8 H 9 I 10 J 11 K 12 L 13 M 14 N 15 O 16 P 17 Q 18 R 19 S 20 T 21 U 22 V 23 W 24 X 25 Y Z]
    return $letter

}

proc hp_serve_index { conn context } {

    set neighbourhood_p [ad_parameter SubdivisionByNeighborhoodP users]

    # The database handle (a thoroughly useless comment)
    
    
    if {$neighbourhood_p} {

	ad_returnredirect "/homepage/neighborhoods"
	return	

    } else {

	ad_returnredirect "/homepage/all"
	return

	# code deactivated by mobin Mon Jan 31 11:53:32 EST 2000,
	# day of the release.

	# http headers
	#ReturnHeaders
	#
	#set title "Homepages at [ad_parameter SystemName]"

	# packet of html
	#ns_write "
	#[ad_header $title]
	#<h2>$title</h2>
	#<hr>
	#"
	#
	#set selection [ns_db select $db "
	#select uh.user_id as user_id,
	#       u.screen_name as screen_name,
	#       u.first_names as first_names,
	#       u.last_name as last_name
	#from users_homepages uh, users u
	#where uh.user_id=u.user_id
	#order by last_name desc, first_names desc"]
	#
	#append html "
	#<table>
	#"
	#
	#while {[ns_db getrow $db $selection]} {
	    #    set_variables_after_query
	    #    append html "
	    #    <tr>
	    #      <td><a href=\"/users/$screen_name\">$last_name, $first_names</a>
	    #      </td>
	    #    </tr>
	    #    "
	    #}
	    #
	    #
	    #append html "
	    #</table>
	    #"
	    #
	    #ns_write "
	    #<blockquote>
	    #$html
	    #</blockquote>
	    #[ad_footer]
	    #"
	    #
	    #return
    }
	
}



