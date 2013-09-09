-- Data model to support autogenerating forms for the ArsDigita
-- Publishing System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- form-manager-create.sql,v 1.3 2000/06/24 06:18:40 karl Exp

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

------------------------------------------
-- KNOWLEDGE LEVEL OBJECTS
------------------------------------------

create table fm_widgets (
  widget	varchar2(100)
		constraint fm_widgets_pk
                primary key
);

comment on table fm_widgets is '
  Canonical list of widgets that may be included in a managed form.
';

create table fm_widget_attributes (
  widget	varchar2(100)
		constraint fm_widget_attribute_ref
		references fm_widgets,
  attribute	varchar2(100)
		constraint fm_widget_attribute_nil
		not null,
  type		varchar2(20)
		constraint fm_widget_attrib_type_ref
		check (type in ('attribute', 'element')),
  method	varchar2(200),
  element_id    number(9),
  constraint fm_widget_attributes_pk
  primary key(widget, attribute)
);

comment on table fm_widget_attributes is '
  Additional attributes associated with a form widget.  For example,
  a text input field has a width attribute.  Attributes
  may be included in the HTML tag or may be for internal consumption.
';

comment on column fm_widget_attributes.method is '
  A java method, called by reflection, which when passed an attribute
  value returns an XMLElement reflecting the data structure for a
  complex attribute such as an option set.
';

create table fm_datatypes (
  datatype		varchar2(100)
			constraint fm_datatypes_pk
			primary key
);

comment on table fm_datatypes is '
  Controlled list of implemented datatypes on the system.
';

------------------------------------------
-- OPERATIONAL LEVEL OBJECTS
------------------------------------------

create sequence fm_forms_seq start with 1600 increment by 1;

create table fm_forms (
  form_id	number(9)
                constraint fm_forms_pk
		primary key,
  name	        varchar2(100)
		constraint fm_forms_name_unq
		unique
		constraint fm_forms_name_nil
		not null,
  title_msg     constraint fm_forms_title_ref
                references ad_messages(message_id),
  action        varchar2(1000)
		constraint fm_forms_action_nil
		not null,
  method        varchar2(20) default 'post'
		constraint fm_forms_method_chk
		check (lower(method) in ('get', 'post')),
  default_locale	 varchar2(4)
			 constraint ad_forms_local_ref
			 references ad_locales
			 constraint ad_forms_local_nil
			 not null,
  dbaction	         varchar2(20)
			 constraint fm_forms_db_action_chk
			 check (dbaction in ('insert', 'update', 'delete')),
  author		 varchar2(1000)
			 constraint fm_forms_author_nil
			 not null,
  help_msg		 number(9)
                         constraint fm_forms_help_ref
			 references ad_messages(message_id),
  internal_comment	 varchar2(4000)
);

comment on table fm_forms is '
  A master reference table for managed forms.
';

create table fm_form_attributes (
  form_id		number(9)
			constraint fm_attribute_form_ref
			references fm_forms on delete cascade,
  html_p		char(1)
			constraint fm_form_attribute_html_chk
			check (html_p in ('t', 'f')),
  attribute		varchar2(100),
  value			clob
);

create table fm_form_extensions (
  form_id		number(9)
			constraint fm_extension_form_ref
			references fm_forms on delete cascade,
  extend_name		varchar2(100),
  constraint fm_form_extensions_pk
  primary key(form_id, extend_name)
);

comment on table fm_form_attributes is '
  Additional attributes associated with a form.
';

create table fm_form_process_code (
  form_id			 number(9)
				 constraint fm_form_process_form_ref
				 references fm_forms on delete cascade,
  extend_name			 varchar2(100),
  code				 varchar2(4000),
  type				 varchar2(16)
				 constraint fm_form_process_type_chk
				 check (type in ('pre', 'post')),
  internal_comment	 	 varchar2(4000),
  constraint fm_form_process_extend_fk
  foreign key(form_id, extend_name) references fm_form_extensions
);

create sequence fm_form_categories_seq start with 1000 increment by 1;

create table fm_form_categories (
  category_id            integer 
                         constraint fm_form_categories_pk
                         primary key,
  parent_id		 integer
			 constraint fm_form_categories_par_ref
                         references fm_form_categories,
  category_name          varchar2(400) not null
);

comment on table fm_form_categories is '
  A simple means of categorizing forms.
';

create table fm_form_category_map (
  category_id		integer
			constraint fm_form_cat_map_cat_ref
			references fm_form_categories,
  form_id		integer
			constraint fm_form_cat_map_form_ref
			references fm_forms on delete cascade,
  constraint fm_form_category_pk
  primary key(category_id, form_id)
);

create table fm_element_option_methods (
  method		varchar2(40)
			constraint fm_element_option_methods_pk
			primary key
);

create table fm_element_option_sets (
  option_key            varchar2(100)
                        constraint fm_element_option_sets_pk
                        primary key,
  option_method		varchar2(16)
			constraint fm_elements_option_ref
                        references fm_element_option_methods,
  option_null_p		char(1)
			constraint fm_elements_option_null_chk
			check (option_null_p in ('t', 'f')),
  option_cache_p	char(1)
			constraint fm_elements_option_cache_chk
			check (option_cache_p in ('t', 'f')),
  option_code		varchar2(4000)
);

create table fm_element_options (
  option_key		varchar2(100)
			constraint fm_option_set_ref
			references fm_element_option_sets on delete cascade,
  value			varchar2(4000),
  message_id		number(9)
			constraint fm_options_message_ref
			references ad_messages
);

create sequence fm_elements_seq start with 1000 increment by 1;

create table fm_elements (
  element_id		number(9)
			constraint fm_elements_pk
			primary key,
  name			varchar2(40)
			constraint fm_elements_name_nil
			not null,
  widget		varchar2(100) default 'text'
			constraint fm_elements_widget_ref
			references fm_widgets,
  datatype		varchar2(100) default 'text'
			constraint fm_elements_datatype_ref
			references fm_datatypes,
  status		varchar2(16) 
			constraint fm_elements_status_chk
			check (status in ('optional', 'required')),
  label_msg		number(9)
                        constraint fm_elements_label_ref
                        references ad_messages(message_id),
  default_method	varchar2(16)
			constraint fm_elements_default_chk
			check (default_method in 
 			('query', 'static', 'param', 'eval')),
  default_cache_p	char(1)
			constraint fm_elements_default_cache_chk
			check (default_cache_p in ('t', 'f')),
  default_code		varchar2(4000),
  help_msg		number(9)
                        constraint fm_elements_help_ref
                        references ad_messages(message_id),
  internal_comment	varchar2(4000)
);

comment on table fm_elements is '
  Metadata for each column in extended attribute tables, for generating
  data entry and edit forms using the form manager.
';

alter table fm_widget_attributes add constraint
  fm_widget_attributes foreign key (element_id) references fm_elements(element_id);

create table fm_element_attributes (
  element_id		number(9)
			constraint fm_attribute_element_ref
			references fm_elements on delete cascade,
  attribute		varchar2(100),
  value			varchar2(4000)
);

comment on table fm_element_attributes is '
  Additional attributes associated with particular type of widget.
';

create table fm_form_element_map (
  form_id			 number(9)
				 constraint fm_element_map_form_ref
				 references fm_forms on delete cascade,
  extend_name			 varchar2(100),
  element_id			 number(9)
				 constraint fm_form_map_element_ref
				 references fm_elements on delete cascade,
  label_width_percent		 number(9)
				 constraint fm_form_label_pct_chk
				 check (label_width_percent >= 0 and 
                                        label_width_percent <= 100),
  element_width_percent		 number(9)
				 constraint fm_form_element_pct_chk
				 check (element_width_percent >= 0 and 
                                        element_width_percent <= 100),
  line_break_after_p		 char(1)
				 constraint fm_form_line_break_chk
				 check (line_break_after_p in ('t', 'f')),
  section_break_before_p	 char(1)
				 constraint fm_form_section_break_chk
				 check (section_break_before_p in ('t', 'f')),
  section_msg			 number(9)
				 constraint fm_form_section_msg_chk
				 references ad_messages(message_id),
  sort_key			 number(9),
  constraint fm_form_map_extend_fk
  foreign key(form_id, extend_name) 
  references fm_form_extensions on delete cascade
);

create table fm_element_datamaps (
  element_id		number(9)
			constraint fm_datamap_element_ref
			references fm_elements on delete cascade,
  data_key		varchar2(16)
			constraint fm_datamap_key_chk
			check (data_key in ('parent', 'child')),
  data_count	        varchar2(16) default 'one' 
			constraint fm_datamap_count_chk
			check (data_count in ('one', 'variable')),
  table_name            varchar2(30)
                        constraint fm_datamap_nil
                        not null,
  column_name           varchar2(30),
  column_type           varchar2(30)
                        constraint fm_datamap_type_chk
                        check (column_type in ('blob', 'clob'))
);

create table fm_element_validations (
  element_id		number(9)
			constraint fm_validate_element_ref
			references fm_elements on delete cascade,
  code			varchar2(4000)
			constraint fm_validate_code_nil
			not null,
  message_id		number(9)
			constraint fm_validate_message_ref
			references ad_messages
);

-- Create message categories for forms

begin
  mc.add_category('forms');
  mc.add_category('titles', 'forms');
  mc.add_category('help', 'forms');
  mc.add_category('elements', 'forms');
  mc.add_category('labels', 'elements', 'forms');
  mc.add_category('help', 'elements', 'forms');
  mc.add_category('validate', 'elements', 'forms');
  mc.add_category('options', 'elements', 'forms');
end;
/
show errors;

-- Bootstrap the list of widgets

insert into fm_widgets values ('text');
insert into fm_widgets values ('none');
insert into fm_widgets values ('password');
insert into fm_widgets values ('checkbox');
insert into fm_widgets values ('radio');
insert into fm_widgets values ('submit');
insert into fm_widgets values ('reset');
insert into fm_widgets values ('file');
insert into fm_widgets values ('hidden');
insert into fm_widgets values ('image');
insert into fm_widgets values ('textarea');
insert into fm_widgets values ('select');
insert into fm_widgets values ('multiselect');
insert into fm_widgets values ('date');
insert into fm_widgets values ('datetime');

-- Bootstrap the list of datatypes

insert into fm_datatypes values ('text');
insert into fm_datatypes values ('number');
insert into fm_datatypes values ('integer');
insert into fm_datatypes values ('keyword');
insert into fm_datatypes values ('date');
insert into fm_datatypes values ('datetime');

-- Bootstrap the list of option methods

insert into fm_element_option_methods values ('query');
insert into fm_element_option_methods values ('static');
insert into fm_element_option_methods values ('eval');
