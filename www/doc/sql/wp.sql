--
-- Data model for WimpyPoint II.
-- Even Wimpier than the Original(tm).
--
-- Jon Salz <jsalz@mit.edu>
-- 13 Nov 1999
--
-- (c)1999 Jon Salz
--

-- Add WimpyPoint user group type.
insert into user_group_types(group_type, pretty_name, pretty_plural, approval_policy, default_new_member_policy, group_module_administration, user_group_types_id)
values('wp', 'WimpyPoint presentation', 'WimpyPoint presentations', 'closed', 'closed', 'none', user_group_types_seq.nextval);

create sequence wp_ids;

-- Styles for presentations. We'll think more about this later if there's time -
-- maybe allow ADPs for more flexibility.
create table wp_styles (
	style_id		integer primary key,
	name			varchar2(400) not null,
	-- CSS source
	css			clob,
	-- HTML style properties. Colors are in the form '192,192,255'.
	text_color		varchar2(20) check(text_color like '%,%,%'),
	background_color	varchar2(20) check(background_color like '%,%,%'),
	background_image	varchar2(200),
	link_color		varchar2(20) check(link_color like '%,%,%'),
	alink_color		varchar2(20) check(alink_color like '%,%,%'),
	vlink_color		varchar2(20) check(vlink_color like '%,%,%'),
	-- public? Set directly by administrators - not accessible through web interface
        public_p                char(1) default 'f' check(public_p in ('t','f')),
	-- if provided by a user, his/her ID
	owner			references users on delete cascade
);

create index wp_styles_by_owner on wp_styles(owner);

-- Insert the magic, "default" style.
insert into wp_styles(style_id, name, public_p, css)
values(-1, 'Default (Plain)', 't',
       'BODY { background-color: white; color: black } P { line-height: 120% } UL { line-height: 140% }');

-- Images used for styles.
create sequence wp_style_images_seq;

create table wp_style_images (
	wp_style_images_id integer primary key,
	style_id	references wp_styles on delete cascade not null,
	image		blob not null,
	file_size	integer not null,
	file_name	varchar(200) not null,
	mime_type	varchar(100) not null,
	unique (style_id, file_name)
);

alter table wp_styles add (
	foreign key (style_id, background_image) references wp_style_images(style_id, file_name) on delete set null
);

-- N.B.: Interdependent tables - you have to use CASCADE CONSTRAINTS to drop wp_styles and wp_style_images!

create table wp_presentations (
	presentation_id		integer primary key,
	-- The title of the presentation, as displayed to the user.
	title			varchar2(400) not null,
	-- A signature on the bottom.
	page_signature		varchar2(4000),
	-- The copyright notice displayed on all pages.
	copyright_notice	varchar2(400),
	-- Creation date and user. The creation user always has admin access to
	-- a presentation.
	creation_date		date not null,
	creation_user		references users not null,
	-- Style information.
	style			references wp_styles on delete set null,
	-- Show last-modified date for slides?
	show_modified_p         char(1) default 'f' check(show_modified_p in ('t','f')),
	-- Can the public view the presentation?
	public_p		char(1) default 't' check(public_p in ('t','f')),
	-- Metainformation.
	audience		varchar(4000),
	background		varchar(4000),
	-- The group used for access control on this presentation.
	-- This group should have type 'wp' and group_name = our presentation_id.
	group_id		references user_groups
);

create index wp_presentations_by_date on wp_presentations(creation_date);

-- A list of checkpoints (frozen versions of a presentation).	
create sequence wp_checkpoints_seq;

create table wp_checkpoints (
	wp_checkpoints_id 	integer primary key,
	presentation_id		references wp_presentations on delete cascade not null,
	checkpoint		integer not null,
	description		varchar(200),
	checkpoint_date		date,
	unique(presentation_id, checkpoint)
);

-- Slides belonging to presentations. When a slide is created, set checkpoint
-- to the value of wp_presentations.checkpoint.
create table wp_slides (
	slide_id		integer primary key,
	presentation_id 	references wp_presentations on delete cascade not null,
	-- The slide_id which this was branched from. Used to preserve comments across
	-- versions.
	original_slide_id	references wp_slides on delete set null,
	-- The minimum and maximum checkpoint for which a slide apply.
        -- max_checkpoint = null is the "current" version. To search for
	-- the slide used for checkpoint n, use condition
	--   min_checkpoint <= n and (max_checkpoint is null or max_checkpoint >= n)
	min_checkpoint		integer not null,
	max_checkpoint		integer,
	sort_key		numeric not null,
	title			varchar2(400),
	preamble		clob,
	-- Store bullet items in a Tcl list.
	bullet_items		clob,
	postamble		clob,
	include_in_outline_p	char(1) default 't' check(include_in_outline_p in ('t','f')),
	context_break_after_p	char(1) default 'f' check(context_break_after_p in ('t','f')),
	modification_date	date not null,
	-- Can override the style setting for the presentation.
	style			references wp_styles,
        foreign key (presentation_id, min_checkpoint) references wp_checkpoints(presentation_id, checkpoint),
	foreign key (presentation_id, max_checkpoint) references wp_checkpoints(presentation_id, checkpoint)
);

create index wp_sorted_slides on wp_slides(presentation_id, max_checkpoint, sort_key);

-- Keeps track of the sorting order for frozen sets of slides.
create sequence wp_historical_sort_seq;
create table wp_historical_sort (
	wp_historical_sort_id integer primary key,
	slide_id	references wp_slides on delete cascade not null,
        presentation_id integer not null,
        checkpoint      integer not null,        
	sort_key	numeric not null,
	unique (slide_id, checkpoint),
	foreign key (presentation_id, checkpoint) references wp_checkpoints(presentation_id, checkpoint) on delete cascade
);

create index wp_sorted_historical_slides on wp_historical_sort(presentation_id, checkpoint, sort_key);

-- File attachments (including images).
create table wp_attachments (
	attach_id	integer primary key,
	slide_id	references wp_slides on delete cascade not null,
	attachment	blob not null,
	file_size	integer not null,
	file_name	varchar(200) not null,
	mime_type	varchar(100) not null,
	-- Display how? null for a link
        display         varchar(20) check(display in ('preamble', 'bullets', 'postamble', 'top', 'after-preamble', 'after-bullets', 'bottom'))
);

create index wp_attachments_by_slide on wp_attachments(slide_id);

-- A "ticket" which can be redeemed for an ACL entry. Useful for inviting
-- someone to work on a presentation: we generate a ticket, send it to the
-- invitee (along with the secret code), and when the user access WimpyPoint we
-- grant him access based on issued tickets.
create table wp_user_access_ticket (
	invitation_id   integer primary key,
	presentation_id	references wp_presentations on delete cascade not null,
	role		varchar(10) not null check (role in('read','write','admin')),
	name            varchar(200) not null,
	email		varchar(200) not null,
	-- secret is null if already redeemed
	secret		varchar(50),
        invite_date     date not null,
	invite_user     references users on delete cascade not null
);

-- Functions.

create or replace function wp_real_user_p(n_slides IN number)
return varchar
AS
BEGIN
  IF n_slides < 5 THEN
     return 'f';
  ELSE
     return 't';
  END IF;
END wp_real_user_p;
/
show errors

create or replace function wp_previous_slide(
  v_sort_key IN wp_slides.sort_key%TYPE,
  v_presentation_id IN wp_slides.presentation_id%TYPE,
  v_checkpoint IN wp_checkpoints.checkpoint%TYPE
)
return integer is
  ret integer;
begin
  if v_checkpoint is null then
    select slide_id into ret
    from   wp_slides
    where  presentation_id = v_presentation_id
    and    max_checkpoint is null
    and    sort_key = (select max(sort_key) from wp_slides
                       where  presentation_id = v_presentation_id
                       and    max_checkpoint is null
                       and    sort_key < v_sort_key);
  else
    select slide_id into ret
    from   wp_historical_sort
    where  presentation_id = v_presentation_id
    and    checkpoint = v_checkpoint
    and    sort_key = (select max(sort_key) from wp_historical_sort
                       where  presentation_id = v_presentation_id
                       and    checkpoint = v_checkpoint
                       and    sort_key < v_sort_key);
  end if;
  return ret;
end;
/
show errors

create or replace function wp_next_slide(
  v_sort_key IN wp_slides.sort_key%TYPE,
  v_presentation_id IN wp_slides.presentation_id%TYPE,
  v_checkpoint IN wp_checkpoints.checkpoint%TYPE
)
return integer is
  ret integer;
begin
  if v_checkpoint is null then
    select slide_id into ret
    from   wp_slides
    where  presentation_id = v_presentation_id
    and    max_checkpoint is null
    and    sort_key = (select min(sort_key) from wp_slides
                       where  presentation_id = v_presentation_id
                       and    max_checkpoint is null
                       and    sort_key > v_sort_key);
  else
    select slide_id into ret
    from   wp_historical_sort
    where  presentation_id = v_presentation_id
    and    checkpoint = v_checkpoint
    and    sort_key = (select min(sort_key) from wp_historical_sort
                       where  presentation_id = v_presentation_id
                       and    checkpoint = v_checkpoint
                       and    sort_key > v_sort_key);
  end if;
  return ret;
end;
/
show errors

-- Turns the read/write/admin role predicate into a number (used for ordering).
-- Higher means more access.
create or replace function wp_role_order
  (v_role IN user_group_map.role%TYPE)
return integer is
begin
  if v_role = 'read' then
    return 1;
  elsif v_role = 'write' then
    return 2;
  elsif v_role = 'admin' then
    return 3;
  end if;

  return null;
end;
/
show errors

-- Given a min_checkpoint/max_checkpoint pair, determines whether the slide
-- refers to a particular checkpoint. A max_checkpoint of null is considered
-- infinitely high (i.e., the very latest).
create or replace function wp_between_checkpoints_p
  (v_checkpoint IN wp_checkpoints.checkpoint%TYPE,
   v_min_checkpoint IN wp_checkpoints.checkpoint%TYPE,
   v_max_checkpoint IN wp_checkpoints.checkpoint%TYPE)   
return varchar is
begin
  if v_checkpoint >= v_min_checkpoint AND (v_max_checkpoint IS NULL OR v_checkpoint < v_max_checkpoint) then
    return 't';
  end if;

  return 'f';
end;
/
show errors

-- Returns the access rights for a presentation. Never returns an access
-- level lower than v_role (e.g., if v_role = 'write' but we only have
-- read access, returns null).
create or replace function wp_access
  (v_presentation_id IN wp_presentations.presentation_id%TYPE,
   v_user_id IN users.user_id%TYPE,
   v_role IN user_group_map.role%TYPE,
   v_public_p IN wp_presentations.public_p%TYPE,
   v_creation_user IN users.user_id%TYPE,
   v_group_id IN user_groups.group_id%TYPE
  )
return varchar is
  a_role user_group_map.role%TYPE;
begin
  if v_creation_user = v_user_id then
    return 'admin';
  end if;
  begin
    select role into a_role
      from user_group_map
      where group_id = v_group_id
      and user_id = v_user_id;
  exception
    -- nothing at all!
    when no_data_found then
      a_role := null;
  end;
  if v_role = 'write' and a_role = 'read' then
    a_role := null;
  elsif v_role = 'admin' and a_role <> 'admin' then
    a_role := null;
  end if;
  if v_role = 'read' and v_public_p = 't' and a_role is null then
    a_role := 'read';
  end if;
  return a_role;
end;
/
show errors

-- Reverts to a checkpoint in a presentation.
create or replace procedure wp_revert_to_checkpoint
  (v_presentation_id IN wp_presentations.presentation_id%TYPE,
   v_checkpoint IN wp_checkpoints.checkpoint%TYPE)
is
  duplicate_sort_keys integer;
begin
  -- Fix old versions of slides. If min_checkpoint <= v_checkpoint < max_checkpoint,
  -- the slide is now the most recent.
  update wp_slides
    set max_checkpoint = null
    where presentation_id = v_presentation_id
    and wp_between_checkpoints_p(v_checkpoint, min_checkpoint, max_checkpoint) = 't';
  -- Restore sort_keys from wp_historical sort.
  update wp_slides s
    set sort_key = (select sort_key
                    from wp_historical_sort h
                    where h.slide_id = s.slide_id
                    and h.checkpoint = v_checkpoint)
    where presentation_id = v_presentation_id
    and max_checkpoint is null
    and min_checkpoint <= v_checkpoint;
  -- Delete wp_historical_sort info for the current checkpoint.
  delete from wp_historical_sort
    where presentation_id = v_presentation_id
    and checkpoint = v_checkpoint;
  -- Delete hosed slides.
  delete from wp_slides
    where presentation_id = v_presentation_id
    and min_checkpoint > v_checkpoint;
  -- Delete recent checkpoints. "on delete cascade" causes appropriate rows
  -- in wp_historical_sort to be hosed. Gotta love cascading deletes!
  delete from wp_checkpoints
    where presentation_id = v_presentation_id
    and checkpoint > v_checkpoint;
  -- A little sanity checking: make sure sort_keys are unique in the most recent
  -- version now. Use a self-join.
  select  count(*) into duplicate_sort_keys
    from  wp_slides s1, wp_slides s2
    where s1.presentation_id = v_presentation_id
    and   s2.presentation_id = v_presentation_id
    and   s1.max_checkpoint is null
    and   s2.max_checkpoint is null
    and   s1.sort_key = s2.sort_key
    and   s1.slide_id <> s2.slide_id;
  if duplicate_sort_keys <> 0 then
    raise_application_error(-20000, 'Duplicate sort_keys');
  end if;
end;
/
show errors

-- Sets a checkpoint in a presentation.
create or replace procedure wp_set_checkpoint
  (v_presentation_id IN wp_presentations.presentation_id%TYPE,
   v_description IN wp_checkpoints.description%TYPE)
is
  latest_checkpoint wp_checkpoints.checkpoint%TYPE;
begin
  select max(checkpoint) into latest_checkpoint
    from  wp_checkpoints
    where presentation_id = v_presentation_id;
  update wp_checkpoints
    set   description = v_description, checkpoint_date = sysdate
    where presentation_id = v_presentation_id
    and   checkpoint = latest_checkpoint;
  insert into wp_checkpoints(presentation_id, checkpoint, wp_checkpoints_id)
    values(v_presentation_id, latest_checkpoint + 1, wp_checkpoints_seq.nextval);
  -- Save sort order.
  insert into wp_historical_sort(slide_id, presentation_id, checkpoint, sort_key, wp_historical_sort_id)
    select slide_id, v_presentation_id, latest_checkpoint, sort_key, wp_historical_sort_seq.nextval
    from   wp_slides
    where  presentation_id = v_presentation_id
    and    max_checkpoint is null;
end;
/
show errors

create or replace function wp_migrate_slide
  (v_presentation_id IN wp_presentations.presentation_id%TYPE,
   v_slide_id IN wp_slides.slide_id%TYPE)
return wp_slides.slide_id%TYPE is
  latest_checkpoint wp_checkpoints.checkpoint%TYPE;
  should_migrate integer;
  new_slide_id integer;
begin
  select max(checkpoint) into latest_checkpoint
    from  wp_checkpoints
    where presentation_id = v_presentation_id;
  select count(*) into should_migrate
    from wp_slides
    where slide_id = v_slide_id
    and min_checkpoint < (select max(checkpoint) from wp_checkpoints where presentation_id = v_presentation_id)
    and max_checkpoint is null;
  if should_migrate > 0 then
    select wp_ids.nextval into new_slide_id from dual;
    update wp_slides
      set max_checkpoint = latest_checkpoint
      where slide_id = v_slide_id;
    insert into wp_slides(slide_id, presentation_id, modification_date, sort_key, min_checkpoint, include_in_outline_p, context_break_after_p,
                          title, preamble, bullet_items, postamble, original_slide_id)
    select new_slide_id, presentation_id, modification_date, sort_key, latest_checkpoint, include_in_outline_p, context_break_after_p,
           title, preamble, bullet_items, postamble, nvl(original_slide_id, slide_id)
      from wp_slides
      where slide_id = v_slide_id;
    insert into wp_attachments(attach_id, slide_id, attachment, file_size, file_name, mime_type, display)
      select wp_ids.nextval, new_slide_id, attachment, file_size, file_name, mime_type, display
        from   wp_attachments
        where  slide_id = v_slide_id;
    return new_slide_id;
  else
    return v_slide_id;
  end if;
end;
/
show errors
