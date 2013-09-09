-- /www/doc/sql/upgrade-3.3-3.4.sql
--
-- Script to upgrade ACS 3.3 database to ACS 3.4 database
-- 
-- upgrade-3.3.1-3.4.sql,v 1.1.2.3 2000/10/10 20:22:04 jmileham Exp

---------------------------- BEGIN general-links
-- 2000-07-14 ryanlee@mit.edu

-- add a primary key to the link_kill_pattern table
alter table link_kill_patterns add (pattern_id integer);

create sequence link_kill_pattern_id start with 1;

create or replace procedure fill_link_kill_pattern_id
IS
	CURSOR c_id IS
	  select pattern_id, rowid from link_kill_patterns;

	v_lkp_row    c_id%ROWTYPE;
BEGIN
    FOR v_lkp_row IN c_id LOOP
	IF v_lkp_row.pattern_id IS NULL THEN
		UPDATE link_kill_patterns
		    set pattern_id = link_kill_pattern_id.nextval
	        WHERE ROWID=v_lkp_row.rowid;
	END IF;
    END LOOP;
END;
/
show errors

BEGIN
	fill_link_kill_pattern_id();
END;
/
show errors

alter table link_kill_patterns add constraint lkp_id_pk primary key (pattern_id);

---------------------------- END general-links

---------------------------- BEGIN ecommerce
-- 2000-07-17 ryanlee@mit.edu

-- change the ADP templates to remove $db variable references;
-- this isn't a data model change so much as a reflection of the
-- new db API

update ec_templates
	set template = '<head>' || CHR(10) || '<title><%= $product_name %></title>' || CHR(10) || '</head>' || CHR(10) || '<body bgcolor=white text=black>' || CHR(10) || CHR(10) || '<h2><%= $product_name %></h2>' || CHR(10)  || CHR(10) || '<table width=100%>' || CHR(10) || '<tr>' || CHR(10) || '<td>' || CHR(10) || ' <table>' || CHR(10) || ' <tr>' || CHR(10) || ' <td><%= [ec_linked_thumbnail_if_it_exists $dirname] %></td>' || CHR(10) || ' <td>' || CHR(10) || ' <b><%= $one_line_description %></b>' || CHR(10) || ' <br>' || CHR(10) || ' <%= [ec_price_line $product_id $user_id $offer_code] %>' || CHR(10) || ' </td>' || CHR(10) || ' </tr>' || CHR(10) || ' </table>' || CHR(10) || '</td>' || CHR(10) || '<td align=center>' || CHR(10) || '<%= [ec_add_to_cart_link $product_id] %>' || CHR(10) || '</td>' || CHR(10) || '</tr>' || CHR(10) || '</table>' || CHR(10) || CHR(10) || '<p>' || CHR(10) || '<%= $detailed_description %>' || CHR(10) || CHR(10) || '<%= [ec_display_product_purchase_combinations $product_id] %>' || CHR(10) || CHR(10) || '<%= [ec_product_links_if_they_exist $product_id] %>' || CHR(10) || CHR(10) || '<%= [ec_professional_reviews_if_they_exist $product_id] %>' || CHR(10) || CHR(10) || '<%= [ec_customer_comments $product_id $comments_sort_by] %>' || CHR(10) || CHR(10) || '<p>' || CHR(10) || CHR(10) || '<%= [ec_mailing_list_link_for_a_product $product_id] %>' || CHR(10) || CHR(10) || '<%= [ec_footer] %>' || CHR(10) || '</body>' || CHR(10) || '</html>'
	where template_id=1;

---------------------------- END ecommerce

---------------------------- BEGIN education-portals
-- 2000-07-17 ryanlee@mit.edu

-- change the ADP templates to remove $db variable references;
-- this isn't a data model change so much as a reflection of the
-- new db API

update portal_tables
set    adp = '<% set html [DisplayStockQuotes]%><%=$html%>'
where  creation_user = 1
and    table_name = 'Stock Quotes'
and    dbms_lob.instr(adp,' $db') > 0;

update portal_tables
set    adp = '<% set html [DisplayWeather]%><%=$html%>'
where  creation_user = 1
and    table_name = 'Current Weather'
and    dbms_lob.instr(adp,' $db') > 0;

update portal_tables
set    adp = '<% set html [GetClassHomepages]%><%=$html%>'
where  creation_user = 1
and    table_name = 'Classes'
and    dbms_lob.instr(adp,' $db') > 0;

update portal_tables
set    adp = '<% set html [GetNewsItems]%><%=$html%>'
where  creation_user = 1
and    table_name = 'Announcements'
and    dbms_lob.instr(adp,' $db') > 0;

update portal_tables
set    adp = '<% set html [edu_calendar_for_portal]%><%= $html%>'
where  creation_user = 1
and    table_name = 'Calendar'
and    dbms_lob.instr(adp,' $db') > 0;

---------------------------- END education-portals


---------------------------- BEGIN manuals

@manuals

---------------------------- END manuals

create or replace function im_cust_status_from_id ( v_status_id IN integer )
return varchar
IS 
  v_status    im_customer_status.customer_status%TYPE;
BEGIN
  select customer_status into v_status from im_customer_status where customer_status_id = v_status_id;
  return v_status;
END;
/
show errors;
