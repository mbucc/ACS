# /admin/ug/group-type-new.tcl

ad_page_contract {
    Add a new user group

    @param group_type the type of group 
    @param pretty_name
    @param pretty_plural
    @param approval_policy
    @param group_module_administration

    @author Tarik Alatovic (tarik@arsdigita.com)
    @creation-date 22 December 1999
    @cvs-id group-type-new-2.tcl,v 3.2.2.9 2000/08/27 20:21:42 cnk Exp

} {
    group_type:notnull
    pretty_name:notnull
    pretty_plural:notnull
    approval_policy:notnull
    {group_module_administration "none"}
} -validate {

    name_is_ok -requires group_type {
	if { [regexp {[^a-zA-Z0-9_]} $group_type] } {
	    ad_complain "You can't have spaces, dashes, slashes, quotes, or colons in a group type.  It has to be just alphanumerics and underscores."
	}
    }

    name_is_not_too_long -requires group_type {
	if { [string length $group_type] > 20 } {
	    ad_complain "You can't have a group type longer than 20 characters."
	}
    }

    group_type_dont_exist -requires group_type {
	if { [db_string select_group_type_exists_p "
            select count(*)
            from   user_group_types
            where  group_type = :group_type
            "] > 0 } {
		ad_complain "The group type you entered ($group_type) is already in use; please try a different name"
	}
    }
}


set insert_sql "
    INSERT INTO user_group_types
           (group_type, pretty_name, pretty_plural, approval_policy, group_module_administration, user_group_types_id)
           VALUES
           (:group_type, :pretty_name, :pretty_plural, :approval_policy, :group_module_administration, user_group_types_seq.nextval)
"

set helper_table "create table [ad_generate_helper_table_name $group_type] (
      group_id	primary key references user_groups
)"

# putting this semi-private error return here so that the transaction
# code is a little more readable

proc my_error_return {} {
    upvar errmsg errmsg
    ad_return_error "Insert failed" "Insertion of your group type in the database failed.  Here's what the RDBMS had to say:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
You should back up, edit the form to fix whatever problem is mentioned 
above, and then resubmit.
"
   ad_script_abort
}

with_catch errmsg {
    db_dml group_type_insert $insert_sql
} {
    my_error_return
}

if [ catch { db_dml make_helper_table $helper_table } errmsg ] {
    # have to try to reverse the insert into user_group_types
    catch [ db_dml reverse_group_type_insert "delete from user_group_types where group_type = :group_type"] errmsg
    my_error_return
}

db_release_unused_handles

ad_returnredirect "group-type?group_type=[ns_urlencode $group_type]"









