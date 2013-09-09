# /www/admin/file-manager/file-upload-2.tcl

ad_page_contract {

    Process a file upload

    @author  ron@arsdigita.com
    @created Fri May 26 06:39:29 2000
    @cvs-id  file-upload-2.tcl,v 1.4.2.13 2000/11/21 00:28:24 ron Exp
} {
    {path:trim,notnull}
    {message:trim,notnull}
    {title:trim,notnull}
}

set the_file [ns_queryget the_file.tmpfile]

# Make sure the incoming filename is valid

if ![fm_valid_filename_p $title] {
    ad_return_complaint "<li>Invalid file name (no spaces, & or /'s)"
    return
}

if {![empty_string_p $title] && [empty_string_p [file ext $title]]} {
    incr   errcnt
    append errmsg "
    <li>The title you supply must have one of the following extensions:<br>
    [ad_parameter Extensions file-manager]"
}

# Done with error checking

set path [file join $path $title]

# Check the file type

set file_type [exec /bin/file $the_file] 

# If the file is text then read it, strip carriage returns,
# and write to the destination path

if {[regexp -nocase -- {\.adp} $path]} {
    if [catch {

	set fd [open $the_file r]
	set text [read $fd]
	close $fd
	
    } errmsg] {

	doc_return  200 text/html "
	
	<p>An error occurred with the file upload:</p>
	
	<pre>$errmsg</pre>
	"
	return
    }
    
    if {[fm_adp_function_p $text]} {
	ad_return_error "Permission Denied" "
	<P>We're sorry, but files edited with the file manager cannot
	have functions in them for security reasons. Only HTML and 
	<%= \$variable %> style code may be used."
	return
    }
} elseif [regexp {text} $file_type] {

    if [catch {

	set fd [open $the_file r]
	set text [read $fd]
	close $fd
	
    } errmsg] {

	doc_return 200 text/html "
	
	<p>An error occurred with the file upload:</p>
	
	<pre>$errmsg</pre>
	"
	return
    }
    
    # for Windows
    regsub -all "\r\n" $text "\n" text
    
    # for Mac
    regsub -all "\r" $text "\n" text
    
    set fd [open $path w]
    puts  $fd $text
    close $fd
    
} else {
    # if the file is binary just copy it
    ns_cp $the_file $path
}

# Register what we did with the version control system if necessary

if [ad_parameter VersionControlP file-manager 0] {

    # get the editor's name and email address for the log
    set user_id [ad_verify_and_get_user_id]

    db_1row user_info { 
	select first_names || ' ' || last_name as name,
	       email
	from   users
	where  user_id = :user_id
    } 

    # add the file (just in case) and commit the change
    vc_add    $path
    vc_commit $path "$name ($email) - $message"

    db_release_unused_handles
}

ad_returnredirect "file-list?path=[file dirname $path]"
return

