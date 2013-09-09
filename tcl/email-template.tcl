# /tcl/email-template.tcl#

ad_library {
    Email templates
    util_template_replace and friends    
    @author jbank@arsdigita.com
    @creation-date  Thu Jun 15 17:24:36 2000
    @cvs-id email-template.tcl,v 3.1.2.2 2000/07/25 11:27:49 ron Exp
}

# vars_to_bindings 
# jbank@arsdigita.com
proc_doc vars_to_bindings { var_list } {Create a binding list with the current values of each of the variables in var_list.} {
    set res [list]
    foreach var $var_list {
        upvar $var val
        lappend res [list $var $val]
    }
    return $res
}

# selection_to_bindings
# jbank@arsdigita.com
proc_doc selection_to_bindings { selection } {Create a binding list with the values in the selection.} {
    set res [list]
    set n_cols [ns_set size $selection]
    for {set i 0} {$i < $n_cols} {incr i} {
        set key [ns_set key $selection $i]
        set value [ns_set value $selection $i]
        lappend res [list $key $value]
    }   
    return $res
}

# query_to_bindings
# jbank@arsdigita.com
proc_doc query_to_bindings {sql } {Create a binding list with the values from the query.} {
    set selection [db_1row email_template_query_to_binds_sql $sql]
    return [selection_to_bindings $selection]
}

# binding_list_combine
# jbank@arsdigita.com
proc_doc binding_list_combine { bl1 bl2 } {Combine two binding lists.} {
    return [concat $bl1 $bl2]
}

# util_template_replace
# jbank@arsdigita.com
proc_doc util_template_replace { text binding_list } {Replace all occurances of each binding in text with its value in the binding_list} {
    foreach binding $binding_list {
        set var [lindex $binding 0]
        set val [lindex $binding 1]
	regsub -all "<$var>" $text $val text
    }
    return $text
}

# util_template_replace_vars
# jbank@arsdigita.com
proc_doc util_template_replace_vars { text var_list } {Replace all occurances of each binding in text with its value from var_list} {
    return [util_template_replace $text [vars_to_bindings $var_list]]
}

##
## Email object abstraction
##

# email_object_create
# jbank@arsdigita.com
proc_doc email_object_create { to_email from_email subject body {headers ""} } {Create an email object.} {
    return [list $to_email $from_email $subject $body $headers]
}

# email_object_get_to
# jbank@arsdigita.com
proc_doc email_object_get_to { email_object } {Get the "to" field from an email object.} {
    return [lindex $email_object 0]
}

# email_object_get_from
# jbank@arsdigita.com
proc_doc email_object_get_from { email_object } {Get the "from" field from an email object.} {
    return [lindex $email_object 1]
}

# email_object_get_subject
# jbank@arsdigita.com
proc_doc email_object_get_subject { email_object } {Get the "subject" field from an email object.} {
    return [lindex $email_object 2]
}

# email_object_get_body
# jbank@arsdigita.com
proc_doc email_object_get_body { email_object } {Get the "body" field from an email object.} {
    return [lindex $email_object 3]
}

# email_object_get_headers
# jbank@arsdigita.com
proc_doc email_object_get_headers { email_object } {Get the "headers" field from an email object.} {
    return [lindex $email_object 4]
}

##Todo, write out the other headers as well
proc_doc email_object_pretty_print { eo {html_p "f"}} {} {
    if {$html_p == "f"} {
        set body [ns_quotehtml [email_object_get_body $eo]]
    } else {
        set body [email_object_get_body $eo]
    }
    return "
<table border=0 cellpadding=5 >

<tr><th align=left>To </th><td>[ns_quotehtml [email_object_get_to $eo]]</td></tr>
<tr><th align=left>From </th><td>[ns_quotehtml [email_object_get_from $eo]]</td></tr>
<tr><th align=left>Subject </th><td>[ns_quotehtml [email_object_get_subject $eo]]</td></tr>
<tr><th align=left valign=top>Message </th><td>
<pre>$body</pre>
</td></tr>
</table>
"
}

proc_doc email_object_edit_form { eo form_target extra_inputs {submit "Submit"} {html_p "f"}} {} {
    if {$html_p == "f"} {
        set body [ns_quotehtml [email_object_get_body $eo]]
    } else {
        set body [email_object_get_body $eo]
    }
    return "
<form action=$form_target>
<table border=0 cellpadding=5 >
$extra_inputs
<tr><th align=left>To </th><td><input size=40 type=text name=email_to value=\"[ns_quotehtml [email_object_get_to $eo]]\"></td></tr>
<tr><th align=left>From </th><td><input size=40 type=text name=email_from value=\"[ns_quotehtml [email_object_get_from $eo]]\"></td></tr>
<tr><th align=left>Subject </th><td><input size=40 type=text name=email_subject value=\"[ns_quotehtml [email_object_get_subject $eo]]\"></td></tr>
<tr><th align=left valign=top>Message </th><td>
<textarea name=email_body rows=20 cols=80>$body</textarea>
</td></tr>
</table>
<center><input type=submit value=\"$submit\"></center>
</form>
"
}

##
## Sending an email object
##

# ad_email_object_send
# jbank@arsdigita.com
proc_doc ad_email_object_send { email_object } {Send an email object.} {
    ns_sendmail [email_object_get_to $email_object] \
            [email_object_get_from $email_object] \
            [email_object_get_subject $email_object] \
            [email_object_get_body $email_object] \
            [email_object_get_headers $email_object]
}

# ad_email_object_list_send
# jbank@arsdigita.com
proc_doc ad_email_object_list_send { eo_list } {Send each email object.} {
    foreach email_object $eo_list {
        ad_email_object_send $email_object
    }
}

##
## General email object substitution
##

# ad_email_object_substitute
# jbank@arsdigita.com
proc_doc ad_email_object_substitute { email_object binding_list } {Do binding substitution on the relevant fields of an email object.} {
    return [email_object_create \
            [util_template_replace [email_object_get_to $email_object] $binding_list] \
            [util_template_replace [email_object_get_from $email_object] $binding_list] \
            [util_template_replace [email_object_get_subject $email_object] $binding_list] \
            [util_template_replace [email_object_get_body $email_object] $binding_list] \
            [email_object_get_headers $email_object]]
}

# ad_email_object_substitute_sql
# jbank@arsdigita.com
proc_doc ad_email_object_substitute_sql { email_object sql_onequery {binding_list ""}} {Do binding substitution on the relevant fields of an email object, using both the binding list and the result of the sql query.} {
    set bl2 [query_to_bindings $sql_onequery]
    return [ad_email_object_substitute $email_object [binding_list_combine $binding_list $bl2]]
}

# ad_email_object_substitute_sql_to_list
# jbank@arsdigita.com
proc_doc ad_email_object_substitute_sql_to_list {email_object sqlquery {binding_list ""}} {Do binding substitution on the relevant fields of an email object, using both the binding list and the result of each row from the sql query.} {
    set res_list [list]

    db_forearch email_template_email_object)substitute_sql_to_list_list_of_stuff $sqlqery {
        set bl2 [selection_to_bindings $list_of_stuff]
        lappend res_list [ad_email_object_substitute $email_object [binding_list_combine $binding_list $bl2]]
    }
    return $res_list
}


##
## Some standard bindings creation functions
##
proc_doc user_id_to_from_bindings { from_user_id } {} {
    return [query_to_bindings "select first_names as from_first_names, last_name as from_last_names, first_names || ' ' || last_name as from_name, email as from_email from users where user_id = :from_user_id"]
}

proc_doc user_id_to_to_bindings { to_user_id } {} {
    return [query_to_bindings "select first_names as to_first_names, last_name as to_last_names, first_names || ' ' || last_name as to_name, email as to_email from users where user_id = :to_user_id"]
}

##
## Some standard headers
##
proc_doc email_extra_headers { html_p } {} {
    set extra_headers [ns_set create]
    ns_set put $extra_headers "Content-Transfer-Encoding" "7bit"
    ns_set put $extra_headers "MIME-Version" "1.0"
    if {$html_p == "t"} {
        ns_set put $extra_headers "Content-Type" "text/html; charset=us-ascii"
    } else {
        ns_set put $extra_headers "Content-Type" "text/plain; charset=us-ascii"
    }
    return $extra_headers
}