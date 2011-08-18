# /bookmarks/import-from-netscape.tcl
#
# imports bookmarks from the Netscape standard bookmark.htm file
#
# by aure@arsdigit.com, June 1999
#
# $Id: import-from-netscape.tcl,v 3.0.4.2 2000/04/28 15:09:46 carsten Exp $

ad_page_variables {
    upload_file
    bookmark_id
    return_url
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set page_title "Importing Your Bookmarks"

# We return headers so that we can show progress, importing can take a while

ReturnHeaders

ns_write "
[ad_header $page_title]

<h2> $page_title </h2>

[ad_context_bar_ws [list $return_url [ad_parameter SystemName bm]] $page_title ]

<hr>
<ul>
"

# read contents of the uploaded file up to the maximum number of bytes
# specified in the .ini file
set max_bytes [ad_parameter MaxNumberOfBytes bm]
set contents [read [open [ns_queryget upload_file.tmpfile r]] $max_bytes]

# set flags to be used parsing the input file.
set folder_list [list "NULL"]
set parent_id "NULL"

# split the input file 'contents' on returns and rename it 'lines'
set lines [split $contents "\n"]

# connect to the default pool and start a transaction.
set db [ns_db gethandle]

foreach line $lines {

    set depth [expr [llength $folder_list]-1]
   
    # checks if the line represents a folder
    if {[regexp {<H3[^>]*>([^<]*)</H3>} $line match local_title]} {

	if {[string length $local_title] > 499} {
	    set local_title "[string range $local_title 0 496]..."
	}
	set insert "
	insert into bm_list
	(bookmark_id, owner_id, local_title, parent_id, folder_p, creation_date)
	values
	($bookmark_id,$user_id, '[DoubleApos $local_title]', $parent_id, 't', sysdate)
	"

	lappend folder_list $bookmark_id
	set parent_id $bookmark_id

	if [catch {ns_db dml $db $insert} errmsg] {
	    # if it was not a double click, produce an error
	    if { [database_to_tcl_string $db "select count(bookmark_id) from bm_list where bookmark_id = $bookmark_id"] == 0 } {
		ad_return_complaint 1 "We were unable to create your user record in the database.  Here's what the error looked like:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
return 
             } else { 
	    # assume this was a double click
	    ad_returnredirect $return_url
	     }
	 } else {
	    set bookmark_id [database_to_tcl_string $db "select bm_bookmark_id_seq.nextval from dual"]
	    ns_write "<li> Inserting \"$local_title\""
	} 

    }

    # check if the line ends the current folder
    if {[regexp {</DL>} $line match]} {
	set folder_depth [expr [llength $folder_list]-2]
	if {$folder_depth<0} {
	    set folder_depth 0
	}
	set folder_list [lrange $folder_list 0 $folder_depth]
	set parent_id [lindex $folder_list $folder_depth]
    }

    # check if the line is a url
    if {[regexp -nocase {<DT><A HREF="([^"]*)"[^>]*>([^<]*)</A>} $line match complete_url local_title]} {

	set host_url [bm_host_url $complete_url]

	if { [empty_string_p $host_url] } {
	    continue
	}

	# check to see if we already have the url in our database
	set url_query "select url_id
	               from   bm_urls
                       where  complete_url='[DoubleApos $complete_url]'"
	set url_id [database_to_tcl_string_or_null  $db $url_query]

	# if we don't have the url, then insert the url into the database
	if {[empty_string_p $url_id]} { 
	    set url_id [database_to_tcl_string $db "select bm_url_id_seq.nextval from dual"]
	    ns_db dml $db "    
	    insert into bm_urls 
	    (url_id, host_url, complete_url)
	    values
	    ($url_id, '[DoubleApos $host_url]', '[DoubleApos $complete_url]')
	    "
	}

	set insert "
	insert into bm_list
	(bookmark_id, owner_id, url_id, local_title, parent_id, creation_date)
	values
	($bookmark_id, $user_id, $url_id, '[DoubleApos $local_title]', $parent_id, sysdate)
	"	

	if [catch {ns_db dml $db $insert} errmsg] {
	    # if it was not a double click, produce an error
	    if { [database_to_tcl_string $db "select count(bookmark_id) from bm_list where bookmark_id = $bookmark_id"] == 0 } {
		ad_return_complaint 1 "We were unable to create your user record in the database.  Here's what the error looked like:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
return 
             } else { 
	    # assume this was a double click
	    ad_returnredirect $return_url
	     }
	 } else {
	    set bookmark_id [database_to_tcl_string $db "select bm_bookmark_id_seq.nextval from dual"]
	    ns_write "<li> Inserting \"$local_title\""

	} 
    }
}

# call the procedure which sets the 'hidden_p' column in the 'bm_list' table
# this determines if a given bookmark/folder is somewhere inside a private folder.
bm_set_hidden_p $db $user_id

# same as above, but this sets the closed_p and in_closed_p columns
bm_set_in_closed_p $db $user_id

ns_write "</ul> Done!  <A href=$return_url>Click</a> to continue.
[bm_footer]"










