-- /doc/sql/pdm-data.sql
--
-- by aure@arsdigita.com, March 2000
--
-- Data to initialize the menus for the admin pages, and arsdigita-users bar
-- for demonstration of the module
--
-- $Id: pull-down-menu-data.sql,v 1.1.2.2 2000/03/16 05:35:34 aure Exp $

set define off;

-- create the two horizontal pull-down menus

insert into pdm_menus (menu_id, menu_key, default_p, orientation, x_offset, y_offset, element_height, element_width, main_menu_font_style, sub_menu_font_style, sub_sub_menu_font_style, main_menu_bg_img_url, main_menu_bg_color, main_menu_hl_img_url, main_menu_hl_color, sub_menu_bg_img_url, sub_menu_bg_color, sub_menu_hl_img_url, sub_menu_hl_color, sub_sub_menu_bg_img_url, sub_sub_menu_bg_color, sub_sub_menu_hl_img_url, sub_sub_menu_hl_color)
    values (pdm_menu_id_sequence.nextval, 'admin', 'f', 'horizontal', 10, 5, 18, 150, 'font-family: arial,helvetica,sans-serif;  font-size: 13px; font-weight: bold;text-decoration: none; line-height: 1.2em; color: #000000;', 'font-family: arial,helvetica,sans-serif;  font-size: 11px; text-decoration: none; line-height: 1em; color: #000000;', 'font-family: arial,helvetica,sans-serif;  font-size: 11px; text-decoration: none; line-height: 1em; color: #000000;', NULL, '#dddddd', NULL, '#9999cc', '/graphics/ad_at_angle.gif' , '#dddddd', NULL, '#9999cc', NULL, '#cccccc', NULL, '#9999cc');

insert into pdm_menus (menu_id, menu_key, default_p, orientation, x_offset, y_offset, element_height, element_width, main_menu_font_style, sub_menu_font_style, sub_sub_menu_font_style, main_menu_bg_img_url, main_menu_bg_color, main_menu_hl_img_url, main_menu_hl_color, sub_menu_bg_img_url, sub_menu_bg_color, sub_menu_hl_img_url, sub_menu_hl_color, sub_sub_menu_bg_img_url, sub_sub_menu_bg_color, sub_sub_menu_hl_img_url, sub_sub_menu_hl_color)
    values (pdm_menu_id_sequence.nextval, 'www.arsdigita.com', 't', 'horizontal', 5, 5, 18, 160, 'font-family: arial,helvetica,sans-serif;  font-size: 13px; font-weight: bold;  text-decoration: none; line-height: 1.2em; color: #000000;', 'font-family: arial,helvetica,sans-serif;  font-size: 11px; text-decoration: none; line-height: 1em; color: #000000;', 'font-family: arial,helvetica,sans-serif;  font-size: 11px; text-decoration: none; line-height: 1em; color: #000000;', NULL, '#dddddd', NULL, '#9999cc', '/graphics/ad_at_angle.gif', '#dddddd', NULL, '#9999cc', NULL, '#cccccc', NULL, '#9999cc');


-- insert items into the pull-down menus defined above

insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '18', 'User Utility Modules', '/admin/#user_modules', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '20', 'Module Tools', '/admin/#module_tools', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '17', 'User Management', '/admin/#user_management', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1900', 'Ad Server', '/admin/adserver/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1800', 'Address Book', '/admin/address-book/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '2000', 'Comments on Static Pages', '/admin/comments/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1700', 'Categories', '/admin/categories/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '19', 'Site Wide Tools', '/admin/#site_tools', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1701', 'Customer Relationship Mgmt.', '/admin/crm/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1702', 'Users', '/admin/users/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1703', 'User Searches', '/admin/searches/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1704', 'User Groups', '/admin/ug/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '2001', 'General Comments', '/admin/general-comments/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '2002', 'General Links', '/admin/general-links/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '2003', 'Related Links', '/admin/links/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1801', 'Bulletin Boards', '/admin/bboard/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1802', 'Bookmarks', '/admin/bookmarks/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1803', 'Calendar', '/admin/calendar/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1804', 'Chat', '/admin/chat/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1805', 'Classifieds', '/admin/gc/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1806', 'Contests', '/admin/contest/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1807', 'Events', '/admin/events/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1808', 'Frequently Asked Questions', '/admin/faq/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1809', 'File Storage', '/admin/file-storage/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1810', 'Glossary', '/admin/glossary/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1811', 'Intranet', '/admin/intranet/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1812', 'Neighbor-to-Neighbor', '/admin/neighbor/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1813', 'News', '/admin/news/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1814', 'Polls', '/admin/poll/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1815', 'Press', '/admin/press/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1816', 'Stolen Equipment Registry', '/admin/registry/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1817', 'Ticket Tracker', '/admin/ticket/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1901', 'Banner Ideas', '/admin/bannerideas/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1902', 'Clickthroughs', '/admin/click/report.tcl', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1903', 'Co-Branding', '/admin/partner/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1904', 'Curriculum', '/admin/curriculum/element-list.tcl', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1905', 'Display', '/admin/display/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1906', 'Documentation', '/admin/documentation/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1907', 'Monitoring', '/admin/monitoring/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1908', 'Portals', '/admin/portals/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1909', 'Pull-down Menus', '/admin/pull-down-menus/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1910', 'Referrals', '/admin/referer/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1911', 'Robot Detection', '/admin/robot-detection/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1912', 'Spam', '/admin/spam/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 1, '1913', 'Static Content', '/admin/static/', 'f');


insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '21', 'Everyone', '#', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '2101', 'Learn about ArsDigita', 'http://www.arsdigita.com/pages/about', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '23', 'Prospective Clients', '#', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '25', 'ACS Developers', '#', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '26', 'Other', '#', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '2502', 'Attend a boot camp', 'http://photo.net/teaching/boot-camp', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '2500', 'Download our software', 'http://www.arsdigita.com/register/index?return_url=%2fdownload%2findex%2etcl', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '2501', 'Join developer discussions', 'http://photo.net/wtr/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '2600', 'The ArsDigita Foundation', 'http://arsdigita.org/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '2601', 'ArfDigita.org', 'http://arfdigita.com/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '2300', 'Qualify us ', 'http://www.arsdigita.com/pages/qualify-us', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '2301', 'Get our sales pitch', 'http://www.arsdigita.com/pages/sales-pitch/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '230100', 'Why hire us?', 'http://www.arsdigita.com/pages/sales-pitch/#like-us', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '230101', 'The Competition', 'http://arsdigita.com/pages/sales-pitch/#competition', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '230102', 'References', 'http://arsdigita.com/pages/sales-pitch/#references', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '230103', 'Next Steps', 'http://arsdigita.com/pages/sales-pitch/#next-steps', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '230104', 'NDA', 'http://arsdigita.com/pages/NDA', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '2302', 'Check our references', 'http://www.arsdigita.com/pages/sales-pitch/#references', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '2303', 'Tell us about your project or idea', 'http://www.arsdigita.com/proposals/new', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '2100', 'Learn about the Web', 'http://www.arsdigita.com/pages/learn/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '210100', 'Contact Us', 'http://arsdigita.com/pages/contact-us', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '2102', 'Review Our Projects', 'ttp://www.arsdigita.com/pages/projects', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '2103', 'Review Our Services', 'http://www.arsdigita.com/pages/services', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '2104', 'Attend our classes and lectures', 'http://register.photo.net/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '2105', 'Use our free services', 'http://www.arsdigita.com/pages/free-services', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '24', 'Potential Employees', '#', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '2400', 'Job Openings', 'http://www.arsdigita.com/pages/jobs/', 'f');
insert into pdm_menu_items (item_id, menu_id, sort_key, label, url, requires_registration_p)
    values (pdm_item_id_sequence.nextval, 2, '2401', 'Review our problem sets', 'http://photo.net/teaching/one-term-web', 'f');
