# /packages/form-manager/database-procs.tcl
ad_library {

  Database storage and retrieval of metadata for form manager
  component for the ArsDigita Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id database-procs.tcl,v 1.4.2.2 2000/07/18 22:06:40 seb Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# Insert a form specification into the database

proc fm_insert_spec { spec locale_abbrev category_id } {

# set db [ns_db gethandle]

db_with_handle db {
  
  ns_db dml $db "begin transaction"
  set locale_abbrev [ns_dbquotevalue $locale_abbrev]

  # insert top-level properties

  ad_util_quote_variables $spec name action method dbaction author comment \
                                title help

  # insert title entry
  set title_msg [mc_add_message $db $title $locale_abbrev NULL NULL \
                    "'titles'" "'forms'"]

  # insert help text
  set help_msg [mc_add_message $db $help $locale_abbrev NULL NULL \
                    "'help'" "'forms'"]

  ns_db dml $db "insert into fm_forms(
    form_id, name, title_msg, action, method, dbaction, author, 
    help_msg, internal_comment, default_locale
  ) values (
    fm_forms_seq.nextval, $name, $title_msg, $action, $method, $dbaction,
    $author, $help_msg, $comment, $locale_abbrev
  )"

  ns_db dml $db "insert into fm_form_extensions(
    form_id, extend_name
  ) values (
    fm_forms_seq.currval, 'base'
  )"

  # enter the form in a category if one specified
  if { ! [empty_string_p $category_id] } {
    ns_db dml $db "insert into fm_form_category_map (
      category_id, form_id
    ) values (
      $category_id, fm_forms_seq.currval
    )"
  }

  # do pre- and post-process blocks

  foreach preprocess [ad_util_get_values $spec preprocess] {

    ad_util_quote_variables $preprocess code comment
    ns_db dml $db "insert into fm_form_process_code values (
      fm_forms_seq.currval, 'base', $code, 'pre', $comment)"
  }

  foreach postprocess [ad_util_get_values $spec postprocess] {

    ad_util_quote_variables $postprocess code comment
    ns_db dml $db "insert into fm_form_process_code values (
      fm_forms_seq.currval, 'base', $code, 'post', $comment)"
  }

  # remember form name for generating a (more) unique option key
  set form_name $name

  # process additional attributes

  # process each element

  foreach element [ad_form_get_elements $spec] {

    ad_util_quote_variables $element name widget datatype status comment \
                                     label help
    ad_util_set_variables $element width height defaults options

    # insert label
    set label_msg [mc_add_message $db $label $locale_abbrev NULL NULL \
                    "'labels'" "'elements'"]

    # insert help
    set help_msg [mc_add_message $db $help $locale_abbrev NULL NULL \
                    "'help'" "'elements'"]

    if { $defaults != "" } {
      ad_util_quote_variables $defaults method cache text
    } else {
      set method "NULL"
      set cache "NULL"
      set text "NULL"
    }
   
    ns_db dml $db "insert into fm_elements (
      element_id, name, widget, datatype, status, label_msg, 
      default_method, default_cache_p, default_code,
      help_msg, internal_comment
    ) values (
      fm_elements_seq.nextval, $name, $widget, $datatype, $status,
      $label_msg, $method, $cache, $text, $help_msg, $comment
    )"

    ns_db dml $db "insert into fm_form_element_map (
      form_id, element_id
    ) values (
      fm_forms_seq.currval, fm_elements_seq.currval
    )"

    # create an option set if necessary
    if { $options != "" } {
      regsub -all {'} "$form_name $name" {} option_key
      set option_key [ns_dbquotevalue $option_key]
      fm_insert_option_set $db $option_key $options $locale_abbrev
      fm_insert_attribute $db option_key $option_key
    }

    fm_insert_attribute $db height $height
    fm_insert_attribute $db width $width

    # insert datamaps
    foreach datamap [ad_util_get_values $element datamap] {
  
      ad_util_quote_variables $datamap key table column count type

      ns_db dml $db "insert into fm_element_datamaps (
        element_id, data_key, data_count, table_name, column_name, column_type
      ) values (
        fm_elements_seq.currval, $key, $count, $table, $column, $type
      )"
    }

    # insert validations
    foreach validate [ad_util_get_values $element validate] {
  
      ad_util_quote_variables $validate condition message

      set valid_msg [mc_add_message $db $message $locale_abbrev NULL NULL \
                    "'validate'" "'elements'"]

      ns_db dml $db "insert into fm_element_validations (
        element_id, code, message_id
      ) values (
        fm_elements_seq.currval, $condition, $valid_msg
      )"
    }
  }

  ns_db dml $db "end transaction"
}

#  ns_db releasehandle $db
}

proc fm_insert_option_set { db option_key options locale_abbrev } {

  ad_util_quote_variables $options null method cache text

  ns_db dml $db "insert into fm_element_option_sets (
    option_key, option_method, option_null_p, option_cache_p, option_code
  ) values (
    $option_key, $method, $null, $cache, $text
  )"

  if { $method == "'static'" } {
    foreach option [ad_form_prepare_parse_static_options $options] {
 
      set label [ns_dbquotevalue [lindex $option 0]]
      set value [ns_dbquotevalue [lindex $option 1]]

      set message_id [mc_add_message $db $label $locale_abbrev NULL NULL \
                    "'options'" "'elements'"]

      ns_db dml $db "insert into fm_element_options (
        option_key, value, message_id
      ) values (
        $option_key, $value, $message_id
      )"
    }
  }

  return $option_key
}

proc fm_insert_attribute { db attribute value } {

  if { [empty_string_p $value] } { return }

  ns_db dml $db "insert into fm_element_attributes (
    element_id, attribute, value
  ) values (
    fm_elements_seq.currval, '$attribute', $value    
  )";

}

proc mc_add_message { db message locale_abbrev { keyword "NULL" } \
  { comment "NULL" } { category "NULL" } { parent_category "NULL" } } {

    if { [string match $message NULL] } {
	return "NULL"
    } else {
	set message_id [ns_ora exec_plsql $db "
	  begin 
            :1 := mc.add_message($message, $locale_abbrev, 
                                 $keyword, $comment,
                                 $category, $parent_category); 
          end;"]
    }
}
