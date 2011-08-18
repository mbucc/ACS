--
-- Support for persistent table customization, dimensional sliders,
-- etc.
--


create table user_custom (
        user_id         references users not null,
        -- user entered name
        item            varchar2(80) not null,
        -- ticket_table etc
        item_group      varchar2(80) not null,
        -- table_view etc
        item_type       varchar2(80) not null,
        -- list nsset etc.
        value_type      varchar2(80) not null,
        value           clob default empty_clob(), 
        primary key (user_id, item, item_group, item_type)
);


        

                     
