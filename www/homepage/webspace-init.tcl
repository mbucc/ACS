# /homepage/webspace-init.tcl

ad_page_contract {
    Web Page Initialization

    @creation-date Thu Jan 13 00:09:31 EST 2000
    @author mobin@mit.edu
    @cvs-id webspace-init.tcl,v 3.3.2.4 2000/07/21 22:05:55 mdetting Exp
} {
}

# ------------------------------ initialization codeBlock ----

set user_id [ad_maybe_redirect_for_registration]

# ------------------------ initialDatabaseQuery codeBlock ----

# This will check whether the user's top level directory exists
# or not.
set dir_p [db_string dir_p_exists {
    select count(*)
    from users_files
    where filename=:user_id
    and parent_id is null
    and owner_id=:user_id
}]

if {$dir_p==0} {
    if [catch {ns_mkdir "[ad_parameter ContentRoot users]$user_id"} errmsg] {
        # directory already exists    
        append exception_text "
        <li>directory [ad_parameter ContentRoot users]$user_id could not be created.<pre>$errmsg</pre>"
        ad_return_complaint 1 $exception_text
        return
    } else {
	ns_chmod "[ad_parameter ContentRoot users]$user_id" 0777
	
	db_dml user_file_insert {
	    insert into users_files
	    (file_id, filename, directory_p, file_pretty_name, file_size, owner_id)
	    values
	    (users_file_id_seq.nextval, :user_id, 't', 'UserContent personalRoot', 0, :user_id)
	}
	
        db_dml user_homepage_insert {
	    insert into users_homepages
	    (user_id, bgcolor, maint_bgcolor, maint_unvisited_link, maint_visited_link, 
	    maint_link_text_decoration, maint_link_font_weight)
	    values
	    (:user_id, 'white', 'white', '006699', '006699', 'none', 'bold')
	}
    }
}

# And off with the handle!
db_release_unused_handles

ad_returnredirect index.tcl

