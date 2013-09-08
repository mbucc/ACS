# /www/bookmarks/import-bookmarks.tcl

ad_page_contract {
    imports bookmarks from the Netscape standard bookmark.htm file
    @param upload_file file to be uploaded
    @param bookmark_id ID for bookmark 
    @param return_url URL for user to return to
    @author Aurelius Prochazka (aure@arsdigita.com)
    @creation-date June 1999  
    @cvs-id import-bookmarks.tcl,v 1.1.2.10 2001/01/09 22:53:47 khy Exp
} {
    upload_file
    upload_file.tmpfile:tmpfile
    bookmark_id:verify,integer,notnull
    {return_url:trim ""}
} 

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# Let's check for a doubleclick first
if { [db_string dbclick_check "
select count(bookmark_id) as n_existing
from   bm_list 
where  bookmark_id = :bookmark_id"] != 0 } {
    # must have doubleclicked
    ad_returnredirect $return_url
    return
}

# -----------------------------------------------------------------------------

# Input Checking
# the maximum number of bytes specified in the .ini file
set max_bytes [ad_parameter MaxNumberOfBytes bm]

page_validation {
    if { [file size ${upload_file.tmpfile}] == 0 } {
	error "The bookmark file you specified is either empty or invalid."
    } 
    
    if [catch { set contents [read [open ${upload_file.tmpfile} r] $max_bytes] } errmsg] {
	error "We had a problem processing your request:
	<p>$errmsg"
    }

    if {![regexp {<DL>(.*)</DL>} $contents match format_p]} {
	error "You file does not appear to be a valid bookmark file"
    }
}

# -----------------------------------------------------------------------------

set page_title "Importing Your Bookmarks"

# We return headers so that we can show progress, importing can take a while

set page_content "
[ad_header $page_title]

<h2> $page_title </h2>

[ad_context_bar_ws [list $return_url [ad_parameter SystemName bm]] $page_title ]

<hr>
<ul>
"

# set flags to be used parsing the input file.
lappend folder_list [db_null]
set parent_id [db_null]

# split the input file 'contents' on returns and rename it 'lines'
set lines [split $contents "\n"]

# connect to the default pool and start a transaction.
foreach line $lines {
    set depth [expr [llength $folder_list]-1]

    # checks if the line represents a folder
    if {[regexp {<H3[^>]*>([^<]*)</H3>} $line match local_title]} {

	if {[string length $local_title] > 499} {
	    set local_title "[string range $local_title 0 496]..."
	}

	# test for duplicates	
	if [empty_string_p $parent_id] {
	    set dp_folder "
	    select count(*) from bm_list
	    where  owner_id = :user_id
	    and    parent_id is null
	    and    folder_p = 't'
	    and    local_title = :local_title"
	} else {
	    set dp_folder "
	    select count(*) from bm_list
	    where  owner_id = :user_id
	    and    parent_id = :parent_id
	    and    folder_p = 't'
	    and    local_title = :local_title"
	}
	
	if { [db_string n_dp_folder $dp_folder] != 0 } {
    
	    append page_content "<li>Duplicate folder \"$local_title\""
	    set parent_id [db_string bm_parent "
	    select bookmark_id
	    from   bm_list
	    where  folder_p = 't'
	    and    owner_id = :user_id
	    and    local_title = :local_title"]
	    
	    } else {
		# insert folder into bm_list
		if [catch {db_dml folder_insert "
		insert into bm_list
		(bookmark_id, owner_id, local_title, 
		parent_id, folder_p, creation_date)
		values
		(:bookmark_id, :user_id, :local_title, 
		:parent_id, 't', sysdate)"} errmsg] {
		    ad_return_complaint 1 "We were unable to create your user record in the database.  Here's what the error looked like:
		    <blockquote>
		    <pre>
		    $errmsg
		    </pre>
		    </blockquote>"
		    return 
		} else {
		    # success in inserting folder into bm_list
		    append page_content "<li> Inserting folder $bookmark_id,$parent_id \"$local_title\""

		    lappend folder_list $bookmark_id
		    set parent_id $bookmark_id
		    set bookmark_id [db_string bookmark_id "select bm_bookmark_id_seq.nextval from dual"]
		}
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
    if {[regexp {<DT><A HREF="([^"]*)"[^>]*>([^<]*)</A>} $line match complete_url local_title]} {
	set host_url [bm_host_url $complete_url]

	if { [empty_string_p $host_url] } {
	    continue
	}
	
	if { [string length $complete_url] > 499 } {
	    append page_content "<li>URL is too long for our database, skipping: \"$complete_url\""
	 
	} else {	 
	    # check to see if we already have the url in our database
	    set url_id [db_string bm_dp_url "
		    select url_id
		    from   bm_urls
		    where  complete_url = :complete_url" -default ""]

	    set url_p 1 

	    # if we don't have the url, then insert the url into the database
	    if [empty_string_p $url_id] {

		set url_id [db_string bm_new_url "
		select bm_url_id_seq.nextval from dual"]

		if [catch {db_dml new_url "
		insert into bm_urls 
		(url_id, host_url, complete_url)
		values
		(:url_id, :host_url, :complete_url)"} errmsg] {
		    set url_p 0
		} 
	    }

	# now we have a url_id (either from query or insert), if it is not an exact duplicate 
	# of one the user already has (including folder location), lets put it in the users bookmark list.
	    if {$url_p == 1} {
	    if [empty_string_p $parent_id] {
		set dp_bookmark "
		select count(bookmark_id) 
		from   bm_list
		where  url_id = :url_id
		and    owner_id = :user_id
		and    parent_id is null"
	    } else {
		set dp_bookmark "
		select count(bookmark_id) 
		from   bm_list
		where  url_id = :url_id
		and    owner_id = :user_id
		and    parent_id = :parent_id"
	    }
	
	    if { [db_string dp $dp_bookmark] != 0 } {
		append page_content "<li>You already added: \"$local_title\""
	    } else {
	    
		# try to insert bookmark into user's list	
		if [catch {db_dml bookmark_insert  "
		insert into bm_list
		(bookmark_id, owner_id, url_id, 
		local_title, parent_id, creation_date)
		values
		(:bookmark_id, :user_id, :url_id, 
		:local_title, :parent_id, sysdate)" } errmsg] {
		    # if it was not a double click, produce an error
		    if { [db_string dbclick  {
			select count(bookmark_id) 
			from   bm_list 
			where bookmark_id = :bookmark_id} ] == 0 } {
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
			# insert into bm_list succeeded
			append page_content "<li> Inserting url:$bookmark_id,$parent_id\"$local_title\""
		    
			set bookmark_id [db_string bookmark_id "select bm_bookmark_id_seq.nextval from dual"]
		    }
		}
	    }
	}
    }
}    

# call the procedure which sets the 'hidden_p' column in the 'bm_list' table
# this determines if a given bookmark/folder is somewhere inside a private folder.
bm_set_hidden_p $user_id

# same as above, but this sets the closed_p and in_closed_p columns
bm_set_in_closed_p $user_id

# release the database handle before serving the page
db_release_unused_handles 

append page_content "</ul> Done!  <A href=$return_url>Click</a> to continue.
[bm_footer]"

doc_return  200 text/html "$page_content"








