# /tcl/intranet-wap-defs.tcl

ad_library {

    Procedures used by WAP interface to the intranet module.

    @creation-date 24 May 2000
    @author Andrew Grumet (aegrumet@arsdigita.com)
    @cvs-id intranet-wap-defs.tcl,v 3.1.6.3 2000/09/14 07:36:31 ron Exp

}

ad_proc -public wml_one_employee_card {

    one_employee 
    {card_id {}}

} { 

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return A WML card with phone numbers for one employee
    @param one_employee A list of phone numbers: { {home_phone} {work_phone} {cell_phone} }
    @param card_id A name for the WML card.

} {

    set name [lindex $one_employee 0]
    set home_phone [lindex $one_employee 1]
    set work_phone [lindex $one_employee 2]
    set cell_phone [lindex $one_employee 3]
    set body "$name<br/>\n"
    if ![empty_string_p $cell_phone] {
	append body "cell: $cell_phone [wml_maybe_call -parse $cell_phone]<br/>\n"
    }
    if ![empty_string_p $work_phone] {
	append body "work: $work_phone [wml_maybe_call -parse $work_phone]<br/>\n"
    }
    if ![empty_string_p $home_phone] {
	append body "home: $home_phone [wml_maybe_call -parse $home_phone]<br/>\n"
    }
    return [wml_simple_card -card_id $card_id $body]
}

ad_proc -public util_numeric_to_sql_sets {

    a_few_chars

} { 

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return A SQL fragment containing a list of letters corresponding to the digits on a phone, i.e. passing in 2 returns ('a','b','c')
    @param a_few_chars A few digits or characters.

} {
    if ![string length $a_few_chars] {
	return {}
    } else {
	set result [list]
	set lower_chars [string tolower $a_few_chars]
	for {set i 0} {$i<[string length $lower_chars]} {incr i} {
	    set one_char [string range $lower_chars $i $i]
	    set char_equiv_list [list]
	    if [regexp {[a-z]} $one_char] {
		lappend char_equiv_list $one_char
	    } else {
                if [regexp {[2-9]} $one_char] {
		    switch $one_char {
			2 { lappend char_equiv_list a b c }
			3 { lappend char_equiv_list d e f }
			4 { lappend char_equiv_list g h i }
			5 { lappend char_equiv_list j k l }
			6 { lappend char_equiv_list m n o }
			7 { lappend char_equiv_list p q r s }
			8 { lappend char_equiv_list t u v }
			9 { lappend char_equiv_list w x y z }
		    }
		}
	    }
	    if [llength $char_equiv_list] {
		set char_equiv_sql {(}
		foreach char_equiv $char_equiv_list {
		    append char_equiv_sql '$char_equiv',
		}
		lappend result "[string trim $char_equiv_sql ,])"
	    }
	}
    }
    return $result
}

ad_proc util_parse_phone {

    phone_number 

} {

    Tries to figure out the phone number from a user-entered string.

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @return A tcl list with the phone number and maybe an extension.
    @param phone_number A string containing the phone number.

} {

    set result [ns_set new]

    # Ugh.  We should have stricter data format in the db.
    regsub -all {\)|\(|\-|\.} $phone_number { } phone

    if [regexp {([0-9][0-9][0-9]) +([0-9][0-9][0-9]) +([0-9][0-9][0-9][0-9])} $phone match area_code prefix suffix] {
	# looks like a US phone number
	regexp -indices {[0-9][0-9][0-9] +[0-9][0-9][0-9] +[0-9][0-9][0-9][0-9]} $phone ind
	if { [lindex $ind 0] <= 1 } {
	    # looks a lot like a US phone number.
	    set last_part [string range $phone [expr [lindex $ind 1] + 1] \
		    [string length $phone]]
	    ns_set put $result number [list "$area_code$prefix$suffix"]
	    ns_set put $result type UsTenDigit
	    if [regexp {([xX]|ext|ex) *([0-9][0-9][0-9])} $last_part match ext_str ext] {
		    ns_set put $result extension $ext
	    }
	    return $result
	}
    }
    # Just return all digits if we get here.
    regsub -all {[^0-9]} $phone_number {} all_the_digits
    ns_set put $result number $all_the_digits
    return $result
}
