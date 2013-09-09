# /www/bookmarks/import-from-netscape.tcl
ad_page_contract {
    imports bookmarks from the Netscape standard bookmark.htm file
    @param upload_file file to be uploaded
    @param bookmark_id ID for bookmark 
    @param return_url URL for user to return to
    @author Aurelius Prochazka (aure@arsdigita.com)
    @creation-date June 1999  
    @cvs-id import-from-netscape.tcl,v 3.4.6.10 2000/09/22 01:37:02 kevin Exp
} {
    upload_file
    bookmark_id:integer,notnull
    {return_url:trim ""}
} 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set page_title "Importing Your Bookmarks"

# We return headers so that we can show progress, importing can take a while

set page_content "
[ad_header $page_title]

<h2> $page_title </h2>

[ad_context_bar_ws [list $return_url [ad_parameter SystemName bm]] $page_title ]

<hr>
<ul>
"

# Input Checking
set tmp_file [ns_queryget upload_file.tmpfile]
# the maximum number of bytes specified in the .ini file
set max_bytes [ad_parameter MaxNumberOfBytes bm]

if { [file size $tmp_file] == 0 } {
    ad_return_complaint 1 "You need to specify a valid bookmark file to upload"
    return
} 

if [catch { set contents [read [open [ns_queryget upload_file.tmpfile] r] $max_bytes] } errmsg] {
    ad_return_complaint 1 "we had a problem processing your request:
    <p>$errmsg"
    return
}

# set flags to be used parsing the input file.
lappend folder_list [db_null]
set parent_id [db_null]

regexp {<DL>(.*)</DL>} $contents match result

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
	set duplicate_folder [db_string n_dp_folder "
                                    select count(bookmark_id) from bm_list
	                            where  owner_id = :user_id
	                            and    parent_id = :parent_id
	                            and    folder_p = 't'
	                            and    local_title = :local_title"] 

	if { $duplicate_folder != 0 } {
	    append page_content "<li>Duplicate folder \"$local_title\""
	} else {

	    # insert folder into bm_list
	    set insert "
	    insert into bm_list
	    (bookmark_id, 
             owner_id, 
             local_title, 
             parent_id, 
             folder_p, 
             creation_date)
	    values
	    (:bookmark_id, 
             :user_id, 
             :local_title, 
             :parent_id, 
              't', 
              sysdate)"
	   
	    if [catch {db_dml folder_insert $insert} errmsg] {
		# if it was not a double click, produce an error
		set dbclick_sql  "
		select count(bookmark_id) 
		from   bm_list 
		where  bookmark_id = :bookmark_id"
		
		if { [db_string -default "" dbclick_p $dbclick_sql] == 0 } {
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
		 # success in inserting folder into bm_list
		 append page_content "<li> Inserting folder $bookmark_id,$parent_id \"$local_title\""
	}

	lappend folder_list $bookmark_id
	set parent_id $bookmark_id
	set bookmark_id [db_string bookmark_id "select bm_bookmark_id_seq.nextval from dual"]
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
	    set url_id [db_string url_p "
		select url_id
		from   bm_urls
		where  complete_url = :complete_url" -default ""]
	    	
	    # if we don't have the url, then insert the url into the database
	    if {[empty_string_p $url_id]} { 
		set url_id [db_string url_id "select bm_url_id_seq.nextval from dual"]
		db_dml new_url "    
		insert into bm_urls 
		(url_id, host_url, complete_url)
		values
		(:url_id, :host_url, :complete_url)
		"
	    }


	    # now we have a url_id (either from query or insert), if it is not an exact duplicate 
	    # of one the user already has (ncluding folder location), lets put it in the users bookmark list. 

	    set duplicate_bookmark_query "select count(bookmark_id) 
                                          from   bm_list
	                                  where  url_id = :url_id
	                                  and    owner_id = :user_id
	                                  and    parent_id = :parent_id"
	    set duplicate_bookmark_listing [db_string duplicate $duplicate_bookmark_query -default ""]

	    if { $duplicate_bookmark_listing != 0 } {
		appen page_content "<li>You already added: \"$local_title\""
	    } else {
		# try to insert bookmark into user's list
		set insert "
		insert into bm_list
		(bookmark_id, 
                 owner_id, 
                 url_id, 
                 local_title, 
                 parent_id, 
                 creation_date)
		values
		(:bookmark_id, 
                 :user_id, 
                 :url_id, 
                 :local_title, 
                 :parent_id, 
                  sysdate)"	
		
		if [catch {db_dml bookmark_insert $insert} errmsg] {
		    # if it was not a double click, produce an error
		    set dbclick_sql "select count(bookmark_id) 
                                     from   bm_list 
                                     where bookmark_id = :bookmark_id"

		    if { [db_string dbclick $dbclick_sql] == 0 } {
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
	    }
	}
    }
	set bookmark_id [db_string bookmark_id "select bm_bookmark_id_seq.nextval from dual"]
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









