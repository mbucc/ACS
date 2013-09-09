
-- Create the basic groups for intranet
begin
   user_group_add ('intranet', 'Customers', 'customer', 'f'); 
   user_group_add ('intranet', 'Projects', 'project', 'f'); 
   user_group_add ('intranet', 'Offices', 'office', 'f'); 
   user_group_add ('intranet', 'Employees', 'employee', 'f'); 
   user_group_add ('intranet', 'Procedure', 'procedure', 'f'); 
   user_group_add ('intranet', 'Partners', 'partner', 'f'); 
   user_group_add ('intranet', 'Authorized Users', 'authorized_users', 'f'); 
   user_group_add ('intranet', 'Team', 'team', 'f'); 
end;
/
show errors;

-- Associate intranet user groups with a few modules
BEGIN
   user_group_type_module_add('intranet', 'news');
   user_group_type_module_add('intranet', 'address-book');
   user_group_type_module_add('intranet', 'download');
END;
/
show errors;


-- We insert all of the intranet categories we use at
-- ArsDigita more as a starting point/reference for 
-- other companies. Feel free to change these either
-- here in the data model or through /www/admin/intranet

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '223',
  '$1-10 million',
  '',
  'Intranet Annual Revenue');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '224',
  '$10-100 million',
  '',
  'Intranet Annual Revenue');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '222',
  '< $1 million',
  '',
  'Intranet Annual Revenue');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '225',
  '> $100 million',
  '',
  'Intranet Annual Revenue');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '221',
  'Pre-revenue',
  '',
  'Intranet Annual Revenue');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '44',
  'Bid and Lost',
  '',
  'Intranet Customer Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '43',
  'Bid out',
  '',
  'Intranet Customer Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '50',
  'Bid?',
  '',
  'Intranet Customer Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '42',
  'Creating Bid',
  '',
  'Intranet Customer Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '49',
  'Current',
  '',
  'Intranet Customer Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '46',
  'Declined',
  '',
  'Intranet Customer Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '41',
  'Inquiries',
  '',
  'Intranet Customer Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '47',
  'Non-converted',
  '',
  'Intranet Customer Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '45',
  'Past',
  '',
  'Intranet Customer Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '48',
  'Potential',
  '',
  'Intranet Customer Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '51',
  'Full Service',
  '',
  'Intranet Customer Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '56',
  'Hosting Only',
  '',
  'Intranet Customer Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '58',
  'iAggregate',
  '',
  'Intranet Customer Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '54',
  'Incubation',
  '',
  'Intranet Customer Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '59',
  'Other',
  '',
  'Intranet Customer Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '52',
  'Premium Support',
  '',
  'Intranet Customer Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '55',
  'Rocket Start',
  '',
  'Intranet Customer Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '53',
  'Standard Support',
  '',
  'Intranet Customer Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '57',
  'Teaching',
  '',
  'Intranet Customer Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '204',
  'Administration',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '212',
  'ArsDigita Press',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '213',
  'Business Development',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '198',
  'Client services',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '205',
  'Facilities',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '201',
  'Finance',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '208',
  'Foundation',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '216',
  'iAggregate',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '211',
  'Internal IT Support',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '210',
  'Legal',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '209',
  'Marketing',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '206',
  'Office management',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '202',
  'Operations',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '207',
  'Recruiting and training',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '200',
  'Sales',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '214',
  'Senior Management',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '199',
  'Sysadmin',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '203',
  'Toolkit',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '215',
  'University',
  '',
  'Intranet Department');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '227',
  'awaits final decision',
  '',
  'Intranet Employee Pipeline State');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '229',
  'Completed pset1',
  '',
  'Intranet Employee Pipeline State');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '230',
  'Completed pset2',
  '',
  'Intranet Employee Pipeline State');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '282',
  'Need rejection letter',
  '',
  'Intranet Employee Pipeline State');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '226',
  'received offer letter',
  '',
  'Intranet Employee Pipeline State');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('0',
  '',
  'f',
  '261',
  'Rejected after pset review',
  '',
  'Intranet Employee Pipeline State');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '281',
  'Rejected us',
  '',
  'Intranet Employee Pipeline State');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '228',
  'Reviewing problem sets',
  '',
  'Intranet Employee Pipeline State');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '283',
  'We rejected them',
  '',
  'Intranet Employee Pipeline State');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '145',
  '6.916',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '133',
  '6.916 Berkeley',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '132',
  '6.916 CalTech',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '131',
  '6.916 MIT',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '136',
  '6.916 UCLA',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '130',
  'Advertising',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '123',
  'Agency/Search Firm',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '127',
  'ArsDigita.com',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '128',
  'Campus Recruitng',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '134',
  'Client',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '138',
  'Grapevine',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '146',
  'iAggregate',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '144',
  'Internship',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '143',
  'Interview',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '129',
  'Oracle magazine',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '135',
  'Philip - Personal Referral',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '141',
  'Philip''s Book - Alex''s Guide',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '137',
  'Philip''s Book - DB Backed Web Sites',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '139',
  'Philip''s One Day Courses',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '140',
  'Philip''s Talks',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '126',
  'photo.net',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '124',
  'Referral - Employee',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '125',
  'Referral - Outside',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '142',
  'Self Recruited',
  '',
  'Intranet Hiring Source');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '151',
  'Administrative Assistant',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '186',
  'ArsDigita Press',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '187',
  'Assistant Controller',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '154',
  'CEO',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '159',
  'Chairman',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '185',
  'Client Services',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '177',
  'Consultant',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '172',
  'Contractor, Independant',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '173',
  'Controller',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '157',
  'COO',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '184',
  'Dba',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '176',
  'Director of Developer Relations',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '175',
  'Director of Network Operations',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '169',
  'Director of Recruiting',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '168',
  'Director of Training',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '182',
  'Executive Assistant',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '181',
  'Executive Director',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '170',
  'Foundation',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '183',
  'Foundation, Director',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '171',
  'iAggregate',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '160',
  'Marketing Assistant',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '152',
  'Office Manager',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '148',
  'Programmer, L1',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '178',
  'Programmer, L1 - Old Scale',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '147',
  'Programmer, L2',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '179',
  'Programmer, L2 - Old Scale',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '149',
  'Programmer, L3',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '180',
  'Programmer, L3 - Old Scale',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '150',
  'Programmer, L4',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '161',
  'Project Leader',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '174',
  'Project leader, Sr.',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '162',
  'Receptionist',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '163',
  'Recruiter',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '156',
  'Short Term Programmer',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '164',
  'Systems Administrator - Jr.',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '165',
  'Systems Administrator - Sr',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '153',
  'Team Leader',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '166',
  'VP, Client Services',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '167',
  'VP, Marketing/Business Development',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '155',
  'VP, Operations',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '158',
  'VP, Sales',
  '',
  'Intranet Job Title');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '62',
  'Active',
  '',
  'Intranet Partner Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '63',
  'Announced',
  '',
  'Intranet Partner Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '65',
  'Dead',
  '',
  'Intranet Partner Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '64',
  'Dormant',
  '',
  'Intranet Partner Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '61',
  'In Discussion',
  '',
  'Intranet Partner Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '60',
  'Targeted',
  '',
  'Intranet Partner Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '67',
  'Graphics',
  '',
  'Intranet Partner Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '71',
  'Hosting',
  '',
  'Intranet Partner Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '68',
  'Strategy',
  '',
  'Intranet Partner Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '69',
  'Supplier',
  '',
  'Intranet Partner Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '70',
  'Sys-admin',
  '',
  'Intranet Partner Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '72',
  'Systems Integrator',
  '',
  'Intranet Partner Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '66',
  'Usability',
  '',
  'Intranet Partner Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '116',
  'Administrator',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '93',
  'Consultant',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '100',
  'Contract Programmer',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '103',
  'Dot Com Venture',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '98',
  'European University',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '115',
  'Founder of a Company',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '118',
  'General Manager',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '94',
  'Graduate school',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '121',
  'iAggregate',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '107',
  'Internship',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '97',
  'MIT',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '96',
  'MIT Lincoln Labs',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '108',
  'No Information',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '119',
  'Non-profit',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '117',
  'Other',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '120',
  'PostDoc',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '111',
  'Product Manager',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '105',
  'Programmer',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '101',
  'Project Leader',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '102',
  'Project Manager',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '122',
  'QA Engineer',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '99',
  'Self Employed',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '109',
  'Start Up',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '112',
  'SW Engineer',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '113',
  'Systems Administrator',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '110',
  'Systems Programmer',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '114',
  'Temp Agency',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '95',
  'Undergraduate School',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '104',
  'University Employee (research or such)',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '106',
  'VP',
  '',
  'Intranet Prior Experience');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '75',
  'Closed',
  '',
  'Intranet Project Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '76',
  'Deleted',
  '',
  'Intranet Project Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '73',
  'Future',
  '',
  'Intranet Project Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '74',
  'Inactive',
  '',
  'Intranet Project Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '77',
  'Open',
  '',
  'Intranet Project Status');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '82',
  'Client - full service',
  '',
  'Intranet Project Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '89',
  'Client - Incubation',
  '',
  'Intranet Project Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '90',
  'Client - Support',
  '',
  'Intranet Project Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '85',
  'Client Services',
  '',
  'Intranet Project Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '92',
  'Client-Hosting Only',
  '',
  'Intranet Project Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '91',
  'Foundation',
  '',
  'Intranet Project Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '79',
  'Internal',
  '',
  'Intranet Project Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '86',
  'Marketing',
  '',
  'Intranet Project Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '87',
  'Miscellaneous',
  '',
  'Intranet Project Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '81',
  'Operations',
  '',
  'Intranet Project Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '78',
  'Sales',
  '',
  'Intranet Project Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '88',
  'Side Project',
  '',
  'Intranet Project Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '84',
  'Sysadmin',
  '',
  'Intranet Project Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '80',
  'Toolkit',
  '',
  'Intranet Project Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '83',
  'Training',
  '',
  'Intranet Project Type');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '189',
  '2 day bootcamp',
  '',
  'Intranet Qualification Process');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '188',
  '3 week bootcamp',
  '',
  'Intranet Qualification Process');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '190',
  '6.916',
  '',
  'Intranet Qualification Process');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '197',
  'Admin Computer Test',
  '',
  'Intranet Qualification Process');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '192',
  'Home study',
  '',
  'Intranet Qualification Process');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '196',
  'Interview Process',
  '',
  'Intranet Qualification Process');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '195',
  'No Process Established, Yet',
  '',
  'Intranet Qualification Process');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '194',
  'None',
  '',
  'Intranet Qualification Process');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '191',
  'Remote bootcamp',
  '',
  'Intranet Qualification Process');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('1',
  '',
  'f',
  '193',
  'Strong referral',
  '',
  'Intranet Qualification Process');


-- Set up the categories to track times associated with tasks

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('0',
  '',
  'f',
  category_id_sequence.nextVal,
  '15 Minutes',
  '',
  'Intranet Task Board Time Frame');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('2',
  '',
  'f',
  category_id_sequence.nextVal,
  '1 hour',
  '',
  'Intranet Task Board Time Frame');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('3',
  '',
  'f',
  category_id_sequence.nextVal,
  '1 day',
  '',
  'Intranet Task Board Time Frame');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('4',
  '',
  'f',
  category_id_sequence.nextVal,
  'Side Project',
  '',
  'Intranet Task Board Time Frame');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('10',
  '',
  'f',
  category_id_sequence.nextVal,
  'Full Time',
  '',
  'Intranet Task Board Time Frame');



-- Populate im_start_blocks. Start with Sunday, Jan 7th 1996
-- and end after inserting 550 weeks. Note that 550 is a 
-- completely arbitrary number. 
DECLARE
  v_max 			integer;
  v_i				integer;
  v_first_block_of_month	integer;
  v_next_start_block		date;
BEGIN
  v_max := 550;

  FOR v_i IN 0..v_max-1 LOOP
    -- for convenience, select out the next start block to insert into a variable
    select to_date('1996-01-07','YYYY-MM-DD') + v_i*7 into v_next_start_block from dual;

    insert into im_start_blocks
    (start_block) 
    values
    (to_date(v_next_start_block));

    -- set the start_of_larger_unit_p flag if this is the first start block of the month
    update im_start_blocks
       set start_of_larger_unit_p='t'
     where start_block=to_date(v_next_start_block)
       and not exists (select 1 
                         from im_start_blocks
                        where to_char(start_block,'YYYY-MM') = to_char(v_next_start_block,'YYYY-MM')
                          and start_of_larger_unit_p='t');

  END LOOP;
END;
/
show errors;
