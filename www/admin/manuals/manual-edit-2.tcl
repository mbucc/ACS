# /www/admin/manuals/manual-edit-2.tcl
ad_page_contract {
    Processes an \"update properties\" request from manual-edit.tcl

    @param manual_id the ID of the manual to modify
    @param title the title of the manual
    @param short_name name used for file names, etc
    @param owner_id the user ID of the owner of the manual
    @param notify_p is the owner notified of changes?
    @param author the name(s) of the author(s)
    @param copyright a copyright notice
    @param version the version name/number
    @param group_id the ID of the group associated with this manual
    @param active_p is this manual availible to the public?

    @author Ron Henderson (ron@arsdigita.com)
    @creation-date Feb 2000
    @cvs-id manual-edit-2.tcl,v 1.6.2.5 2000/08/06 18:36:07 kevin Exp
} {
    manual_id:integer,notnull
    title:trim,notnull
    short_name:trim,notnull
    owner_id:integer,notnull
    {author ""}
    {copyright ""}
    {version ""}
    notify_p
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
	if {![db_0or1row title_conflict "
	select manual_id
	from   manuals 
	where  title = :title"]} {
	    ad_complain "Your title conflicts with the existing manual
	    \"<a href=one?manual_id=$title_conflict_manual_id>$title</a>\"\n"
	}
    }

    short_name_unique_check -requires {short_name_invalid_chars} {
	if {![db_0or1row short_name_conflict "
	select manual_id
	from   manuals 
	where  short_name = :short_name"]} {
	    ad_complain "Your short name conflicts with the existing short name
	    \"<a href=one?manual_id=$short_name_conflict_manual_id>$short_name</a>\"\n"
	}
    }
}

# -----------------------------------------------------------------------------

# Done error checking.  Update the existing information for this manual.

db_dml manual_update "
update manuals
set    title      = :title,
       short_name = :short_name,
       owner_id   = :owner_id,
       author     = :author,
       copyright  = :copyright,
       version    = :version,
       scope      =  [expr {[empty_string_p $group_id] ? "'public'" : "'group'"}],
       group_id   = :group_id, 
       active_p   = :active_p, 
       notify_p   = :notify_p
where  manual_id  = :manual_id"

ad_returnredirect "manual-edit.tcl?manual_id=$manual_id"



