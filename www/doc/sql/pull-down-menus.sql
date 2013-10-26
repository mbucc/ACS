-- pull-down-menus.sql
--
-- by aure@arsdigita.com, February 2000
--
-- pull-down-menus.sql,v 3.3 2000/03/21 06:34:53 ron Exp

create sequence pdm_menu_id_sequence;

create table pdm_menus (
	menu_id			integer primary key,
	-- programmer friendly title used to call the menu
	menu_key			varchar(20) unique not null,
	-- is this the menu to show if no pdm_key is passed to ad_pdm?
	default_p		char(1) default 'f' check (default_p in ('t','f')),
	-- orientation of the menu, either "horizontal" or "vertical"
	orientation		varchar(20) not null check (orientation in ('horizontal','vertical')),
	-- distance from the left side of the display area
	x_offset		integer not null,
	-- distance from top of the display area
	y_offset		integer not null,
	-- dimensions of a single menu element
	element_height		integer not null,
	element_width		integer not null,
	-- css-type style guides for the fonts in the menu
	main_menu_font_style	varchar(4000),
	sub_menu_font_style	varchar(4000),
	sub_sub_menu_font_style varchar(4000),
	-- main menu background images and background colors 
	main_menu_bg_img_url	varchar(200),
	main_menu_bg_color	varchar(12),
	-- hl stands for "highlight" - these are what are shown when
	-- someone mouses over the menu
	main_menu_hl_img_url    varchar(200),
	main_menu_hl_color	varchar(12),
	-- background and color definitions for first level sub menu
	sub_menu_bg_img_url	varchar(200),
	sub_menu_bg_color	varchar(12),
	sub_menu_hl_img_url	varchar(200),
	sub_menu_hl_color	varchar(12),
	-- background and color definitions for second level sub menu
	sub_sub_menu_bg_img_url	varchar(200),
	sub_sub_menu_bg_color	varchar(12),
	sub_sub_menu_hl_img_url	varchar(200),
	sub_sub_menu_hl_color	varchar(12)
);

create sequence pdm_item_id_sequence;

create table pdm_menu_items (
	item_id			integer primary key,
	menu_id			references pdm_menus,
	-- within one level, sort_key defines the order of the items
	sort_key		varchar(50) not null,
	-- text of the item to be displayed if no images are shown and
	-- as alt text to the images
	label			varchar(200) not null,
	-- url may be null if this item is only used to store other items
	url			varchar(500),
	-- don't show certain elements to people who haven't registered
	requires_registration_p char(1) default 'f' check (requires_registration_p in ('t','f'))
  , CONSTRAINT constraint_name UNIQUE (menu_id, sort_key, label)
);
