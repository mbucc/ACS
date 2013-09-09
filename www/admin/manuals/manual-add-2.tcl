# /www/admin/manuals/manual-add-2.tcl
ad_page_contract {
    Add a manual based on the information provided

    @param next_manual_id the next manual ID from our sequence
    @param title the title of the manual
    @param short_name name used for file names, etc
    @param owner_id the user ID of the owner of the manual
    @param notify_p is the owner notified of changes?
    @param author the name(s) of the author(s)
    @param copyright a copyright notice
    @param version the version name/number
    @param group_id the ID of the group associated with this manual
    @param active_p is this manual availible to the public?

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Jan 2000
    @cvs-id manual-add-2.tcl,v 1.6.2.7 2001/01/11 17:40:04 khy Exp
} {
    next_manual_id:integer,notnull,verify
    title:trim,notnull
    short_name:trim,notnull
    owner_id:integer,notnull
    notify_p
    {author ""}
    {copyright ""}
    {version ""}
    {group_id ""}
    active_p
} -validate {
    short_name_invalid_chars -requires {short_name} {
	if {[regexp " " $short_name] || [regexp "'" $short_name]} {
	    ad_complain "The short name must not contain any spaces or apostrophes.\n"
	} 
    }

    manual_owner_check -requires {owner_id} {
	if {![empty_string_p $group_id]} {
	    if { ![ad_administrator_p $owner_id] && ![ad_user_group_authorized_admin $owner_id $group_id]} {
		ad_complain "The specified owner is not an administrator for the group.\n"
	    }
	}
    }

    title_unique_check -requires {title} {
	if {[db_0or1row title_conflict "
	select manual_id
	from   manuals 
	where  title = :title"]} {
	    ad_complain "Your title conflicts with the existing manual
	    \"<a href=one?manual_id=$manual_id>$title</a>\"\n"
	}
    }

    short_name_unique_check -requires {short_name_invalid_chars} {
	if {[db_0or1row short_name_conflict "
	select manual_id
	from   manuals 
	where  short_name = :short_name"]} {
	    ad_complain "Your short name conflicts with the existing short name
	    \"<a href=one?manual_id=$manual_id>$short_name</a>\"\n"
	}
    }
}

# -----------------------------------------------------------------------------
# Done error checking.  Insert the new manual into the database and
# redirect to the admin page.

set double_click_p [db_string dbl_click_check "
select count(*)
from   manuals
where  manual_id = :next_manual_id"]

if {!$double_click_p} {

    db_transaction {
	db_dml manual_insert "
	insert into manuals 
	( manual_id, 
 	  title, 
	  short_name, 
	  owner_id, 
	  author,
	  copyright,
	  version,
	  scope, 
	  group_id, 
	  active_p, 
	  notify_p)
	values
	( :next_manual_id, 
	  :title, 
	  :short_name, 
	  :owner_id,
	  :author,
	  :copyright,
	  :version,
	   decode(:group_id,'','public','group'),
	  :group_id, 
	  :active_p, 
 	  :notify_p)"

	# make the related administration group for this manual

	ad_administration_group_add "Editors of $title" manuals \
		$next_manual_id \
		"/manuals/admin/manual-view.tcl?manual_id=$next_manual_id" "f"

    }
}

ad_returnredirect "manual-edit.tcl?manual_id=$next_manual_id"



