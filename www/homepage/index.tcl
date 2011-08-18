# $Id: index.tcl,v 3.2.2.1 2000/04/28 15:11:01 carsten Exp $
# File:     /homepage/index.tcl
# Date:     Mon Jan 10 21:06:26 EST 2000
# Location: 42Å∞21'N 71Å∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  User Content Main Page

# Homepages should be enabled!
set enabled_p [ad_parameter HomepageEnabledP users]
# And if they're not... let's do nothing
if {$enabled_p == 0} {
    ns_return 200 text/plain "homepage module is disabled"
    return
}

set_form_variables 0
# filesystem_node

# ------------------------------ initialization codeBlock ----

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# If the user is not registered, we need to redirect him for
# registration
if { $user_id == 0 } {
    ad_redirect_for_registration
    return
}

# Check whether user's directory exists or not
set dir_p [file exists [ad_parameter ContentRoot users]$user_id]

# ------------------------ initialDatabaseQuery codeBlock ----

# The database handle (a thoroughly useless comment)
set db [ns_db gethandle]

# This query will extract information about the user from the
# database
set selection [ns_db 1row $db "
select first_names, last_name
from users
where user_id=$user_id"]

# This will assign the appropriate values to the appropriate
# variables based on the query results.
set_variables_after_query

# Checking for site-wide administration status
set admin_p [ad_administrator_p $db $user_id]

# This query will return the quota of the user
set sql "
select (hp_get_filesystem_root_node($user_id)) as fsid,
       (select count(*) * [ad_parameter DirectorySpaceRequirement users]
        from users_files
        where directory_p='t'
        and owner_id=$user_id) +
       (select nvl(sum(file_size),0)
        from users_files
        where directory_p='f'
        and owner_id=$user_id) as quota_used,
       (decode((select count(*) from
                users_special_quotas
                where user_id=$user_id),
                0, [ad_parameter [ad_decode $admin_p \
			 0 NormalUserMaxQuota \
			 1 PrivelegedUserMaxQuota \
			 PrivelegedUserMaxQuota] users],
                (select max_quota from
                 users_special_quotas
                 where user_id=$user_id))) * power(2,20) as quota_max,
       (select count(*)
        from users_files
        where filename='$user_id'
        and parent_id is null
        and owner_id=$user_id) as dir_p,
       (select screen_name
        from users
        where user_id=$user_id) as screen_name
from dual
"

# Extract results from the query
set selection [ns_db 1row $db $sql]

# This will  assign the  variables their appropriate values 
# based on the query.
set_variables_after_query

# If filesystem node is not specified, go to user's root directory
if {![info exists filesystem_node] || [empty_string_p $filesystem_node]} {
    set filesystem_node $fsid
}

set cookies [ns_set get [ns_conn headers] Cookie]
if {[regexp {.*homepage_view=([^ ;]*).*} $cookies match cookie_view]} {
    # we have a match
    set view $cookie_view
} else {
    set view [ad_parameter DefaultView users]
}

if {![info exists view] || [empty_string_p $view]} {
    set view "normal"
}

if {$dir_p != 0} {
    set access_denied_p [database_to_tcl_string $db "
    select hp_access_denied_p($filesystem_node,$user_id) from dual"]

    # Check to see whether the user is the owner of the filesystem node
    # for which access is requested.
    if {$access_denied_p} {
	# Aha! url surgery attempted!
	#    append exception_text "
	#    <li>Unauthorized Access to the FileSystem"
	#    ad_return_complaint 1 $exception_text
	#    return
	ad_returnredirect "dialog-class.tcl?title=Access Denied&text=Unauthorized access to the filesystem!&btn1=Okay&btn1target=index.tcl"
	return
    }
}

# And off with the handle!
ns_db releasehandle $db

# ----------------------- initialHtmlGeneration codeBlock ----

# Set the page title
set title "$first_names $last_name - Homepage Maintenance"

# Return the http headers. (an awefully useless comment)
ReturnHeaders

# Send the first packet of html. The reason for sending the
# first packet (with the page heading) as early as possible
# is that otherwise the user might find the system somewhat
# unresponsive if it takes too long to query the database.
ns_write "
[hp_header $title $user_id 1]	
<h2>$title</h2>
[ad_context_bar_ws_or_index $title]
<hr>
[help_upper_right_menu_b]
Your Max Quota: [util_commify_number $quota_max] bytes<br>
Quota Space Used: [util_commify_number $quota_used] bytes<br>
<br>
<blockquote>
"

if {$dir_p==0} {
    ns_write "Your webspace has not been activated yet.
    Click <a href=webspace-init.tcl>here</a> to set it up for the first time.
    </blockquote>
    [ad_footer]"
    return
}

if {[empty_string_p $screen_name]} {
    ns_write "
    You have not set up a screen name as yet. 
    Click <a href=/pvt/basic-info-update.tcl>here</a> to set one up.
    </blockquote>
    [ad_footer]"
    return
}

set home_url "[ad_parameter SystemURL]/users/$screen_name"
append html "
</blockquote>
Your homepage is at <a href=\"$home_url\">$home_url</a>
<blockquote>"

# The database handle (a thoroughly useless comment)
set db [ns_db gethandle]

set sql "
select (select parent_id
from users_files
where file_id=$filesystem_node) as parent_node
from dual
"

# Extract results from the query
set selection [ns_db 1row $db $sql]

# This will  assign the  variables their appropriate values 
# based on the query.
set_variables_after_query

set this_managed_p [database_to_tcl_string $db "
select managed_p from users_files where file_id=$filesystem_node"]

if {![info exists parent_node] || [empty_string_p $parent_node]} {
    set parent_html ""
} else {

	set parent_html "
	<tr><td><img src=back.gif>
	<a href=index.tcl?filesystem_node=$parent_node>Parent Folder</a>
	<font size=-1>\[level up\]</font>
	</td></tr>
	"

}

set curr_dir [database_to_tcl_string $db "
select hp_user_relative_filename($filesystem_node) from dual"]

set file_count [database_to_tcl_string $db "
select hp_get_filesystem_child_count($filesystem_node) from dual"]

if {$this_managed_p} {
    set selection [ns_db 1row $db "
    select type_name, sub_type_name
    from users_content_types
    where type_id = (select content_type 
                     from users_files
                     where file_id=$filesystem_node)"]
    set_variables_after_query
    set content_name [database_to_tcl_string $db "
    select file_pretty_name from users_files
    where file_id=$filesystem_node"]
}
# This menu displays a list of options which the user has
# available for the current filesystem_node (directory).
if {$this_managed_p} {
    set options_menu "
    \[ <a href=\"add-section.tcl?filesystem_node=$filesystem_node&section_type=$sub_type_name&master_type=$type_name\">add $sub_type_name</a> | <a href=publish-1.tcl?filesystem_node=$filesystem_node>publish sub-content</a> | <a href=upload-1.tcl?filesystem_node=$filesystem_node>upload picture</a> \]
    "
    append html "<i><font size=+2>$content_name</font></i> <font size=-1>($type_name)</font><p>"
} else {
    set options_menu "
    \[ <a href=mkdir-1.tcl?filesystem_node=$filesystem_node>create folder</a> | <a href=publish-1.tcl?filesystem_node=$filesystem_node>publish content</a> | <a href=upload-1.tcl?filesystem_node=$filesystem_node>upload file</a> | <a href=mkfile-1.tcl?filesystem_node=$filesystem_node>create file</a> \]
    "
}

# View Selection

if {$view == "tree"} {

    append html "
    <br>
    <table border=0 cellspacing=0 cellpadding=0 width=90%>
    <tr><td>$options_menu</td>
    <td align=right>\[ <a href=set-view.tcl?view=normal&filesystem_node=$filesystem_node>normal view</a> | tree view \]
    </td></tr>
    </table>
    <br>
    <table bgcolor=DDEEFF border=0 cellspacing=0 cellpadding=8 width=90%>
    <tr><td>
    <b>Contents rooted at /users/$screen_name$curr_dir :</b>
    <ul>
    <table border=0>
    $parent_html
    "

    set counter 0
    
    if {$file_count==0} {
	#append html "
	#<tr><td>There are no files in this directory</td></tr>"
	append html ""
    } else {
	set selection [ns_db select $db "
	select file_id as fid, filename, directory_p, file_size, level, file_pretty_name,
               parent_id, managed_p, content_type, modifyable_p, managed_p,
	       (decode(f.managed_p, 'f', 'folder', (select type_name 
                                                     from users_content_types
	                                             where type_id = f.content_type))) as type,
	hp_filesystem_node_sortkey_gen(f.file_id) as generated_sort_key,
	hp_user_relative_filename(f.file_id) as rel_filename
	from users_files f
	where owner_id=$user_id
	and level > 1
	connect by prior file_id = parent_id
	start with file_id=$filesystem_node
	order by generated_sort_key asc"]
	while {[ns_db getrow $db $selection]} {
	    incr counter
	    set_variables_after_query
	    set level [expr $level - 2]
	    if {$directory_p} {
		
		# Code deactivated but not removed because it is respectable code, man!
		# set dir_menu "
		# <font size=-1>\[ <a href=rmdir-1.tcl?filesystem_node=$filesystem_node&dir_node=$fid>remove</a> | rename \]</font>
		# "
		
		# This dir_menu uses the generic dialog box for confirmation
		set dir_menu "
		<font size=-1>\[ <a href=\"dialog-class.tcl?title=Filesystem Management&text=This will delete the folder `$filename' permanently.<br>Are you sure you would like to do that?&btn1=Yes&btn2=No&btn2target=index.tcl&btn2keyvalpairs=filesystem_node $filesystem_node&btn1target=rmdir-1.tcl&btn1keyvalpairs=filesystem_node $filesystem_node dir_node $fid\">remove</a> | <a href=\"rename-1.tcl?filesystem_node=$filesystem_node&rename_node=$fid\">rename</a> | <a href=move-1.tcl?filesystem_node=$filesystem_node&move_node=$fid>move</a> \]</font>
		"
		
		
		append html "<tr><td>[ad_space [expr $level * 8]]<img src=dir.gif>
		<a href=index.tcl?filesystem_node=$fid>$filename</a>
		<font size=-1>($type)</font>
		</td>
		<!--<td valign=bottom align=center>&nbsp</td>-->
		<td valign=bottom>&nbsp$dir_menu</td></tr>"
	    } else {
		# Deactivated by mobin Wed Jan 19 00:24:23 EST 2000
		# set file_menu_1 "
		# <font size=-1>\[ <a href=rmfile-1.tcl?filesystem_node=$filesystem_node&file_node=$fid>remove</a> | rename "
		
		set file_menu_2 "<a href=\"dialog-class.tcl?title=Filesystem Management&text=This will delete the file `$filename' permanently.<br>Are you sure you would like to do that?&btn1=Yes&btn2=No&btn2target=index.tcl&btn2keyvalpairs=filesystem_node $filesystem_node&btn1target=rmfile-1.tcl&btn1keyvalpairs=filesystem_node $filesystem_node file_node $fid\">remove</a> | <a href=\"rename-1.tcl?filesystem_node=$filesystem_node&rename_node=$fid\">rename</a> | <a href=move-1.tcl?filesystem_node=$filesystem_node&move_node=$fid>move</a> \]</font>"
		
		
		if {[regexp {text.*} [ns_guesstype $filename] match]} {
		    # The file is editable by a text editor.
		    set file_menu_1 "<font size=-1>\[ <a href=edit-1.tcl?filesystem_node=$filesystem_node&file_node=$fid>edit</a> | "
		} else {
		    if {$managed_p} {
			if {[file extension $filename] == ""} {
			    set file_menu_1 "<font size=-1>\[ <a href=edit-1.tcl?filesystem_node=$filesystem_node&file_node=$fid>edit</a> | "
			} else {
			    set file_menu_1 "<font size=-1>\[ "
			}
		    } else {
			set file_menu_1 "<font size=-1>\[ "
		    }
		}

		if {$modifyable_p == "f"} {
		    set file_menu_2 "<a href=\"dialog-class.tcl?title=Filesystem Management&text=This will delete the file `$filename' permanently.<br>Are you sure you would like to do that?&btn1=Yes&btn2=No&btn2target=index.tcl&btn2keyvalpairs=filesystem_node $filesystem_node&btn1target=rmfile-1.tcl&btn1keyvalpairs=filesystem_node $filesystem_node file_node $fid\">remove</a> \]</font>"
		}
		
		set file_menu "$file_menu_1$file_menu_2"
		
		set filesize_display "
		<font size=-1>[util_commify_number $file_size] bytes</font>
		"
		
		if {$managed_p} {
		    append html "<tr><td>[ad_space [expr $level * 8]]<img src=doc.gif>
		    <a href=\"/users/$screen_name$rel_filename\">$filename</a>
		    </td>
		    <td valign=bottom align=left>&nbsp<font size=-1>$file_pretty_name</font></td>
		    <td valign=bottom align=right>&nbsp$file_menu</td>
		    </tr>
		    "		    
		} else {
		    append html "<tr><td>[ad_space [expr $level * 8]]<img src=doc.gif>
		    <a href=\"/users/$screen_name$rel_filename\">$filename</a>
		    </td>
		    <td valign=bottom align=right>&nbsp<font size=-1>$filesize_display</font></td>
		    <td valign=bottom align=right>&nbsp$file_menu</td>
		    </tr>
		    "
		}
	    }
	}
    }
       
} else {

    # This is when the view is normal
    append html "
    <br>
    <table border=0 cellspacing=0 cellpadding=0 width=90%>
    <tr><td>$options_menu</td>
    <td align=right>\[ normal view | <a href=set-view.tcl?view=tree&filesystem_node=$filesystem_node>tree view</a> \]
    </td></tr>
    </table>
    <br>
    <table bgcolor=DDEEFF cellpadding=8 width=90%>
    <tr><td>
    <b>Contents of /users/$screen_name$curr_dir :</b>
    <ul>
    <table border=0>
    $parent_html
    "
    
    if {$file_count==0} {
	#append html "
	#<tr><td>There are no files in this directory</td></tr>"
	append html ""
    } else {
	set selection [ns_db select $db "
	select file_id as fid, filename, directory_p, file_size, content_type, 
	       managed_p, file_pretty_name, modifyable_p,
	       (decode(uf.managed_p, 'f', 'folder', (select type_name 
                                                     from users_content_types
	                                             where type_id = uf.content_type))) as type
	from users_files uf
	where parent_id=$filesystem_node
	and owner_id=$user_id
	order by directory_p desc, filename asc"]
	while {[ns_db getrow $db $selection]} {
	    set_variables_after_query
	    if {$directory_p} {
		
		# Code deactivated but not removed because it is respectable code, man!
		# set dir_menu "
		# <font size=-1>\[ <a href=rmdir-1.tcl?filesystem_node=$filesystem_node&dir_node=$fid>remove</a> | rename \]</font>
		# "
		
		# This dir_menu uses the generic dialog box for confirmation
		set dir_menu "
		<font size=-1>\[ <a href=\"dialog-class.tcl?title=Filesystem Management&text=This will delete the folder `$filename' permanently.<br>Are you sure you would like to do that?&btn1=Yes&btn2=No&btn2target=index.tcl&btn2keyvalpairs=filesystem_node $filesystem_node&btn1target=rmdir-1.tcl&btn1keyvalpairs=filesystem_node $filesystem_node dir_node $fid\">remove</a> | <a href=\"rename-1.tcl?filesystem_node=$filesystem_node&rename_node=$fid\">rename</a> | <a href=move-1.tcl?filesystem_node=$filesystem_node&move_node=$fid>move</a> \]</font>
		"
		
		
		append html "<tr><td><img src=dir.gif>
		<a href=index.tcl?filesystem_node=$fid>$filename</a>
		<font size=-1>($type)</font>
		</td>
		<!--<td valign=bottom align=center>&nbsp</td>-->
		<td valign=bottom>&nbsp$dir_menu</td></tr>"
	    } else {
		# Deactivated by mobin Wed Jan 19 00:24:23 EST 2000
		# set file_menu_1 "
		# <font size=-1>\[ <a href=rmfile-1.tcl?filesystem_node=$filesystem_node&file_node=$fid>remove</a> | rename "
		
		set file_menu_2 "<a href=\"dialog-class.tcl?title=Filesystem Management&text=This will delete the file `$filename' permanently.<br>Are you sure you would like to do that?&btn1=Yes&btn2=No&btn2target=index.tcl&btn2keyvalpairs=filesystem_node $filesystem_node&btn1target=rmfile-1.tcl&btn1keyvalpairs=filesystem_node $filesystem_node file_node $fid\">remove</a> | <a href=\"rename-1.tcl?filesystem_node=$filesystem_node&rename_node=$fid\">rename</a> | <a href=move-1.tcl?filesystem_node=$filesystem_node&move_node=$fid>move</a> \]</font>"
		
		
		if {[regexp {text.*} [ns_guesstype $filename] match]} {
		    # The file is editable by a text editor.
		    set file_menu_1 "<font size=-1>\[ <a href=edit-1.tcl?filesystem_node=$filesystem_node&file_node=$fid>edit</a> | "
		} else {
		    if {$this_managed_p} {
			if {[file extension $filename] == ""} {
			    set file_menu_1 "<font size=-1>\[ <a href=edit-1.tcl?filesystem_node=$filesystem_node&file_node=$fid>edit</a> | "
			} else {
			    set file_menu_1 "<font size=-1>\[ "
			}
		    } else {
			set file_menu_1 "<font size=-1>\[ "
		    }
		}
		
		if {$modifyable_p == "f"} {
		    set file_menu_2 "<a href=\"dialog-class.tcl?title=Filesystem Management&text=This will delete the file `$filename' permanently.<br>Are you sure you would like to do that?&btn1=Yes&btn2=No&btn2target=index.tcl&btn2keyvalpairs=filesystem_node $filesystem_node&btn1target=rmfile-1.tcl&btn1keyvalpairs=filesystem_node $filesystem_node file_node $fid\">remove</a> \]</font>"
		}
		
		set file_menu "$file_menu_1$file_menu_2"
		
		set filesize_display "
		<font size=-1>[util_commify_number $file_size] bytes</font>
		"
		if {$this_managed_p} {
		    append html "<tr><td><img src=doc.gif>
		    <a href=\"/users/$screen_name$curr_dir/$filename\">$filename</a>
		    </td>
		    <td valign=bottom align=left>&nbsp<font size=-1>$file_pretty_name</font></td>
		    <td valign=bottom align=right>&nbsp$file_menu</td>
		    </tr>
		    "
		} else {
		    append html "<tr><td><img src=doc.gif>
		    <a href=\"/users/$screen_name$curr_dir/$filename\">$filename</a>
		    </td>
		    <td valign=bottom align=right>&nbsp$filesize_display</td>
		    <td valign=bottom align=right>&nbsp$file_menu</td>
		    </tr>
		    "
		}
	    }
	}
    }
}

append html "</table></ul>"

# And off with the handle!
ns_db releasehandle $db

if {$view == "tree"} {
    set file_count $counter
}

append html "
$file_count file(s)
</td></tr></table>
<p>
<table border=0 cellspacing=0 cellpadding=0 width=90%>
<tr><td>$options_menu</td>
<td align=right>\[ <a href=update-display.tcl?filesystem_node=$filesystem_node>display settings</a> \]
</td></tr>
</table>
<br>
"

# To escape out of the blockquote mode
append html "
</blockquote>"

# ------------------------ htmlFooterGeneration codeBlock ----

# And here is our footer. Were you expecting someone else?
ns_write "
$html
[ad_footer]
"











