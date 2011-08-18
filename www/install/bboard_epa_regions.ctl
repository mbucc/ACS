LOAD DATA
INFILE *
INTO TABLE BBOARD_EPA_REGIONS
REPLACE
FIELDS TERMINATED BY '|'
(
state_name
,fips_numeric_code
,epa_region
,usps_abbrev
,description
)
BEGINDATA
Alabama|01|4|AL|Southeast Region
Alaska|02|10|AK|Northwestern Region
American Samoa|60|9|AS|Western Region
Arizona|04|9|AZ|Western Region
Arkansas|05|6|AR|Southern Region
California|06|9|CA|Western Region
Colorado|08|8|CO|North Central Region
Connecticut|09|1|CT|New England Region
Delaware|10|3|DE|Mid Atlantic Region
District of Columbia|11|3|DC|Mid Atlantic Region
Florida|12|4|FL|Southeast Region
Georgia|13|4|GA|Southeast Region
Guam|66|9|GU|Western Region
Hawaii|15|9|HI|Western Region
Idaho|16|10|ID|Northwestern Region
Illinois|17|5|IL|Great Lakes Region
Indiana|18|5|IN|Great Lakes Region
Iowa|19|7|IA|Central Region
Kansas|20|7|KS|Central Region
Kentucky|21|4|KY|Southeast Region
Louisiana|22|6|LA|Southern Region
Maine|23|1|ME|New England Region
Maryland|24|3|MD|Mid Atlantic Region
Massachusetts|25|1|MA|New England Region
Michigan|26|5|MI|Great Lakes Region
Minnesota|27|5|MN|Great Lakes Region
Mississippi|28|4|MS|Southeast Region
Missouri|29|7|MO|Central Region
Montana|30|8|MT|North Central Region
Nebraska|31|7|NE|Central Region
Nevada|32|9|NV|Western Region
New Hampshire|33|1|NH|New England Region
New Jersey|34|2|NJ|NY and NJ Region
New Mexico|35|6|NM|Southern Region
New York|36|2|NY|NY and NJ Region
North Carolina|37|4|NC|Southeast Region
North Dakota|38|8|ND|North Central Region
Ohio|39|5|OH|Great Lakes Region
Oklahoma|40|6|OK|Southern Region
Oregon|41|10|OR|Northwestern Region
Pennsylvania|42|3|PA|Mid Atlantic Region
Puerto Rico|72|2|PR|NY and NJ Region
Rhode Island|44|1|RI|New England Region
South Carolina|45|4|SC|Southeast Region
South Dakota|46|8|SD|North Central Region
Tennessee|47|4|TN|Southeast Region
Texas|48|6|TX|Southern Region
Utah|49|8|UT|North Central Region
Vermont|50|1|VT|New England Region
Virgin Islands of the U.S.|78|2|VI|NY and NJ Region
Virginia|51|3|VA|Mid Atlantic Region
Washington|53|10|WA|Northwestern Region
West Virginia|54|3|WV|Mid Atlantic Region
Wisconsin|55|5|WI|Great Lakes Region
Wyoming|56|8|WY|North Central Region
