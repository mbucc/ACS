# /www/gc/edit-ad-5.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id edit-ad-5.tcl,v 3.3.2.5 2000/09/22 01:37:52 kevin Exp
} {
    user_id:integer
    classified_ad_id:integer
    full_ad:html
    one_line
    html_p
    expires
    primary_category
}
 
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


ad_proc ad_column_type { table_name primary_key_name } {
    db_with_handle db {
	set type [ns_column type $db $table_name $primary_key_name]
    }
    return $type
}

ad_proc ad_dbtype {} {
    db_with_handle db {
	set type [ns_db dbtype $db]
    }
    return $type
}

proc gc_magic_update {table_name primary_key_name primary_key_value form} {
    set form_size [ns_set size $form]
    set form_counter_i 0
    while {$form_counter_i<$form_size} {
	set form_var_name [ns_set key $form $form_counter_i]
	set value [ns_set value $form $form_counter_i]
	if { $form_var_name != $primary_key_name } {
	    set column_type [ad_column_type $table_name $form_var_name]

	    ns_log Notice [ad_column_type $table_name $form_var_name]
	    ns_log Notice [db_column_type $table_name $form_var_name]
	    
	    if {[regexp {date|time} $column_type]&&[regexp -nocase {current} $value]} {
		# we're using Illustra and a system function
		set quoted_value $value
	    } elseif { $column_type == "date" && [regexp -nocase {oracle} [ad_dbtype]]} {
		# we're using Oracle
		if { [string tolower $value] == "sysdate" } {
		    # wants the sysdate function, no quotes
		    set quoted_value $value
		} else {
		    set quoted_value "TO_DATE('$value','YYYY-MM-DD')"
		}
	    } else {
		set quoted_value [ns_dbquotevalue $value $column_type]
	    }
	    lappend the_sets "$form_var_name = $quoted_value"
	}
	incr form_counter_i
    }
    set primary_key_type [ad_column_type $table_name $primary_key_name]
    return "update $table_name\nset [join $the_sets ",\n"] \n where $primary_key_name = [ns_dbquotevalue $primary_key_value $primary_key_type]"
}



if [catch { db_1row gc_edit_ad_5_ad_data_get {
    select * from classified_ads 
    where classified_ad_id = :classified_ad_id
}   } errmsg ] {
    ad_return_error "Could not find Ad $classified_ad_id" "in <a href=index>[gc_system_name]</a>

<p>

Either you are fooling around with the Location field in your browser
or my code has a serious bug.  The error message from the database was

<blockquote><code>
$errmsg
</blockquote></code>"
       return 
}

db_1row gc_edit_ad_5_get_domain_info [gc_query_for_domain_info $domain_id]

set auth_user_id [ad_verify_and_get_user_id]

if { $auth_user_id != $user_id } {
    ad_return_error "Unauthorized" "You are not authorized to edit this ad."
    return
}

# person is authorized

set update_sql [gc_magic_update classified_ads classified_ad_id $classified_ad_id [ns_conn form]]

db_transaction {
    db_dml gc_edit_ad_5_audit_insert [gc_audit_insert $classified_ad_id]
    db_dml gc_edit_ad_5_update $update_sql 
} on_error {
    # something went a bit wrong
    
    ad_return_error "Error Updating Ad $classified_ad_id" "<h2>Error Updating Ad $classified_ad_id</h2>

in <a href=index>[gc_system_name]</a>

<p>

Tried the following SQL:

<pre>
$update_sql
</pre>

and got back the following:

<blockquote><code>
$errmsg
</blockquote></code>

[gc_footer $maintainer_email]"
    return 0
}

# everything went nicely 
doc_return  200 text/html "[gc_header "Success"]

<h2>Success!</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Ad Updated"]

<hr>

There isn't really a whole lot more to say...

<p>

If you'd like to check your ad, then take a look 
at <a href=\"view-one?classified_ad_id=$classified_ad_id\">the public page</a>.

[gc_footer $maintainer_email]"

