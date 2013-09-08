create or replace package fm
is

  procedure add_attribute (
    widget_in IN varchar2,
    attribute_in IN varchar2,
    type_in IN varchar2 := 'attribute',
    method_in IN varchar2 := NULL,
    help_in IN varchar2 := NULL,
    datatype_in IN varchar2 := 'text',
    entry_widget_in IN varchar2 := 'text',
    status_in IN varchar2 := 'required'
  );

  procedure copy_attribute (
    from_widget_in IN varchar2,
    attribute_in IN varchar2,
    to_widget_in IN varchar2
  );

  procedure delete_form (
    form_name_in IN varchar2
  );

  procedure write_spec (
    name_in IN varchar2,
    extension_in IN varchar2,
    locale_abbrev IN varchar2,
    dest_loc IN clob
  ) as language
    java
  name
    'com.arsdigita.fm.FormWriter.writeSpec(
       java.lang.String, java.lang.String, java.lang.String,
       oracle.sql.CLOB       
    )'; 

  function get_spec (
    name_in IN varchar2,
    extension_in IN varchar2,
    locale_abbrev IN varchar2
  ) return clob;

end fm;
/
show errors;

create or replace package body fm
is

  function get_spec (
    name_in IN varchar2,
    extension_in IN varchar2,
    locale_abbrev IN varchar2
  ) return clob is

    dest_loc clob;

  begin
     
    dbms_lob.createtemporary(dest_loc, true);
    write_spec(name_in, extension_in, locale_abbrev, dest_loc);
   
    return dest_loc;

  end get_spec;

  procedure delete_form (
    form_name_in IN varchar2
  ) is

    form_id_v integer;

  begin

    select 
      form_id into form_id_v 
    from 
      fm_forms 
    where 
      name = form_name_in;
   
    delete from 
      fm_elements
    where
      element_id in (select element_id from fm_form_element_map
                    where form_id = form_id_v);

    delete from
      fm_forms
    where
      form_id = form_id_v;

  end delete_form;

-- Add an attribute for a particular widget, such as 'width' for a
-- text input field.

  procedure add_attribute (
    widget_in IN varchar2,
    attribute_in IN varchar2,
    type_in IN varchar2 := 'attribute',
    method_in IN varchar2 := NULL,
    help_in IN varchar2 := NULL,
    datatype_in IN varchar2 := 'text',
    entry_widget_in IN varchar2 := 'text',
    status_in IN varchar2 := 'required'
  ) is

    label_msg_v integer;
    help_msg_v integer;

  begin

    label_msg_v := mc.add_message(initcap(attribute_in), 'us', NULL, NULL, 
                                  'labels', 'elements');
    help_msg_v := mc.add_message(help_in, 'us', NULL, NULL, 'help', 
                                 'elements');

    insert into fm_elements (
      element_id, name, widget, datatype, status, label_msg, help_msg
    ) values (
      fm_elements_seq.nextval, attribute_in, entry_widget_in, datatype_in, 
      status_in, label_msg_v, help_msg_v
    );

    insert into fm_widget_attributes (
      widget, attribute, element_id, type, method
    ) values (
      widget_in, attribute_in, fm_elements_seq.currval, type_in, method_in
    );

  end add_attribute;

  procedure copy_attribute (
    from_widget_in IN varchar2,
    attribute_in IN varchar2,
    to_widget_in IN varchar2
  ) is

    element_id_v integer;
    method_v fm_widget_attributes.method%TYPE;
    type_v fm_widget_attributes.type%TYPE;

  begin

    select 
      element_id, method, type
    into 
      element_id_v,  method_v, type_v 
    from 
      fm_widget_attributes 
    where 
      widget = from_widget_in 
    and 
      attribute = attribute_in;

    insert into fm_widget_attributes (
      widget, attribute, element_id, method, type
    ) values (
      to_widget_in, attribute_in, element_id_v, method_v, type_v
    );
        
  end copy_attribute;

end fm;
/
show errors;
  
-- Additional attributes for form elements.

begin

  fm.add_attribute('text', 'width', 'attribute', NULL,
    'Specifies the SIZE attribute for text input fields or the COLS ' ||
    'attribute for text areas.', 'number', 'text', 'optional');

  fm.copy_attribute('text', 'width', 'password');
  fm.copy_attribute('text', 'width', 'textarea');

  fm.add_attribute('textarea', 'height', 'attribute', NULL, 
    'Specifies the SIZE attribute for select elements or the ROWS ' ||
    ' attribute for text areas.', 'number', 'text', 'optional');

  fm.copy_attribute('textarea', 'height', 'select');
  fm.copy_attribute('textarea', 'height', 'multiselect');

  fm.add_attribute('checkbox', 'option_key', 'element', 'getOptionSet',
    'Specifies the labels and values for the list of options ' ||
    'for text areas.', 'keyword', 'select', 'required');

  fm.copy_attribute('checkbox', 'option_key', 'select');
  fm.copy_attribute('checkbox', 'option_key', 'multiselect');
  fm.copy_attribute('checkbox', 'option_key', 'radio');

end;
/
show errors;

