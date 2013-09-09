# /www/ticket/bug-listing.tcl
ad_page_contract {
    Grabs a list of known ACS bugs and outputs them to a file so that 
    any developer/customer can know the known ACS bugs.
    The HTML portion of this page has been commented out and it is
    now being sent to the user via a file

    @param project_id the project to list bugs on.  "all" provides a 
           listing for all projects.

    @author Hiro Iwashima (iwashima@arsdigita.com)
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date 7 May 2000
    @cvs-id bug-listing.tcl,v 3.8.2.7 2000/09/22 01:39:22 kevin Exp
} {
    {project_id "all"}
}

# -----------------------------------------------------------------------------

if {[empty_string_p $project_id] || [string compare $project_id "all"] == 0} {
    set project_sql_constraint ""
    set project_name "ALL"
} else {
    page_validation {
	validate_integer project_id $project_id
    }

    set project_sql_constraint "and ti.project_id=:project_id"

    set project_name [db_string title_for_one_project "
       select title_long
       from ticket_projects
       where project_id = :project_id" -default ""]
    page_validation {
	if [empty_string_p $project_name] {
	    error "Invalid Project ID"
	}
    }
}

set current_date [db_string get_date "
select to_char(sysdate,'YYYY-MM-DD HH24:MM') from dual"]

set bug_string "
Known Bugs for project: $project_name
in ACS as of $current_date
---------------------------------------

Listed below are some known bugs in the current ArsDigita Community Software along with who's working on them.  You can email them and ask if a patch has been made for the problem you are having.  If you find any more bugs, please report them to ArsDigita.

The format of the errors below are:

\[ID\]  
Assigned to:  person  --  email
Subject:      subject
Message:      message

-----------------------------------------

"

# append html "
# [ad_header "Known ACS Bugs"]
# <H2>Known ACS Bugs</H2>
# <hr>
# This page is automatically updated with the latest list of ACS bugs.
# <br><br>

# <table cellpadding=4 border=0>
# <tr bgcolor=#cccccc><td width=5><b>ID</b></td>
#     <td width=20><b>Assigned to</b></td>
#     <td width=30><b>email</b></td>
#     <td width=*><b>Subject</b></td></tr>
# "

#set bgcolor "#ffffff"

db_foreach get_all_bugs "
 SELECT ti.msg_id as msg_id,
        ti.one_line as one_line,
        gc.content as message,
        assigned_users.first_names || ' ' || assigned_users.last_name as assigned_user_name,
        assigned_users.email as assigned_user_email
 FROM  ticket_issues ti,
       users assigned_users,
       ticket_issue_assignments ta,
       general_comments gc
 WHERE ti.ticket_type='Defct'
   and ti.status='open'
   and ti.msg_id = ta.msg_id(+)
   and ta.user_id = assigned_users.user_id
   and gc.comment_id(+) = ti.comment_id
   $project_sql_constraint" {

    set message [ns_striphtml $message]
    set one_line [ns_striphtml $one_line]
    regsub -all "\n" $message "\n              " message
    regsub -all "\n" $one_line "\n              " one_line

    append bug_string "
\[$msg_id\]  
Assigned to:  $assigned_user_name  --  $assigned_user_email
Subject:      $one_line
Message:      $message

"

#     append html "
#     <tr bgcolor=$bgcolor><td>$msg_id</td>
#         <td>$assigned_user_name</td>
#         <td>$assigned_user_email</td>
#         <td>$one_line</td></tr>
#     <tr bgcolor=#ffffff><td>&nbsp;</td>
#         <td colspan=3 bgcolor=$bgcolor>$message</td></tr>
#     "

#     if {[string compare $bgcolor "#ffffff"] == 0} {
# 	set bgcolor "#ccccff"
#     } else {
# 	set bgcolor "#ffffff"
#     }
}

append bug_string "
Please send any additional bugs to ACS.
"

# append html "
# </table>
# [ad_footer]"

doc_return  200 text/plain $bug_string

