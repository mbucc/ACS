LOAD DATA
INFILE *
INTO TABLE CURRENCY_CODES
REPLACE
FIELDS TERMINATED BY '|'
(
iso
,currency_name
,supported_p
)
BEGINDATA
ADP|Andorran Peseta|f
AED|United Arab Emirates Dirham|f
AFA|Afghanistan Afghani|f
ALL|Albanian Lek|f
AMD|Armenian Dram|f
ANG|Netherlands Antillian Guilder|f
AON|Angolan New Kwanza|f
ARP|Argentinian Peso|f
ATS|Austrian Schilling|f
AUD|Australian Dollar|t
AWF|Aruban Florin|f
AZM|Azerbaijan Manat|f
BAK|Bosnia and Herzegovina Convertible Mark|f
BBD|Barbados Dollar|f
BDT|Bangladeshi Taka|f
BEF|Belgian Franc|f
BGL|Bulgarian Lev|f
BHD|Bahraini Dinar|f
BIF|Burundi Franc|f
BMD|Bermudian Dollar|f
BND|Brunei Dollar|f
BOB|Bolivian Boliviano|f
BRR|Brazilian Real|f
BSD|Bahamian Dollar|f
BTN|Bhutan Ngultrum|f
BUK|Burma Kyat|f
BWP|Botswanian Pula|f
BYP|Belarus Ruble|f
BZD|Belize Dollar|f
CAD|Canadian Dollar|t
CHF|Swiss Franc|f
CLF|Chilean Unidades de Fomento|f
CLP|Chilean Peso|f
CNY|Yuan (Chinese) Renminbi|f
COP|Colombian Peso|f
CRC|Costa Rican Colon|f
CSK|Czech Koruna|f
CUP|Cuban Peso|f
CVE|Cape Verde Escudo|f
CYP|Cyprus Pound|f
DDM|East German Mark (DDR)|f
DEM|Deutsche Mark|f
DJF|Djibouti Franc|f
DKK|Danish Krone|f
DOP|Dominican Peso|f
DZD|Algerian Dinar|f
ECS|Ecuador Sucre|f
EGP|Egyptian Pound|f
ESP|Spanish Peseta|f
ETB|Ethiopian Birr|f
EUR|Euro|t
FIM|Finnish Markka|f
FJD|Fiji Dollar|f
FKP|Falkland Islands Pound|f
FRF|French Franc|f
GBP|British Pound|f
GHC|Ghanaian Cedi|f
GIP|Gibraltar Pound|f
GMD|Gambian Dalasi|f
GNF|Guinea Franc|f
GRD|Greek Drachma|f
GTQ|Guatemalan Quetzal|f
GWP|Guinea-Bissau Peso|f
GYD|Guyanan Dollar|f
HKD|Hong Kong Dollar|f
HNL|Honduran Lempira|f
HRK|Croatian Kuna|f
HTG|Haitian Gourde|f
HUF|Hungarian Forint|f
IDR|Indonesian Rupiah|f
IEP|Irish Punt|f
ILS|Israeli Shekel|f
INR|Indian Rupee|f
IQD|Iraqi Dinar|f
IRR|Iranian Rial|f
ISK|Iceland Krona|f
ITL|Italian Lira|f
JMD|Jamaican Dollar|f
JOD|Jordanian Dinar|f
JPY|Japanese Yen|t
KES|Kenyan Schilling|f
KHR|Kampuchean (Cambodian) Riel|f
KMF|Comoros Franc|f
KPW|North Korean Won|f
KRW|South Korean Won|f
KWD|Kuwaiti Dinar|f
KYD|Cayman Islands Dollar|f
LAK|Lao Kip|f
LBP|Lebanese Pound|f
LKR|Sri Lanka Rupee|f
LRD|Liberian Dollar|f
LSL|Lesotho Loti|f
LUF|Luxembourg Franc|f
LYD|Libyan Dinar|f
MAD|Moroccan Dirham|f
MGF|Malagasy Franc|f
MNT|Mongolian Tugrik|f
MOP|Macau Pataca|f
MRO|Mauritanian Ouguiya|f
MTL|Maltese Lira|f
MUR|Mauritius Rupee|f
MVR|Maldive Rufiyaa|f
MWK|Malawi Kwacha|f
MXP|Mexican Peso|f
MYR|Malaysian Ringgit|f
MZM|Mozambique Metical|f
NGN|Nigerian Naira|f
NIC|Nicaraguan Cordoba|f
NLG|Dutch Guilder|f
NOK|Norwegian Kroner|f
NPR|Nepalese Rupee|f
NZD|New Zealand Dollar|f
OMR|Omani Rial|f
PAB|Panamanian Balboa|f
PEI|Peruvian Inti|f
PGK|Papua New Guinea Kina|f
PHP|Philippine Peso|f
PKR|Pakistan Rupee|f
PLZ|Polish Zloty|f
PTE|Portuguese Escudo|f
PYG|Paraguay Guarani|f
QAR|Qatari Rial|f
ROL|Romanian Leu|f
RUR|Russian Ruble|f
RWF|Rwanda Franc|f
SAR|Saudi Arabian Riyal|f
SBD|Solomon Islands Dollar|f
SCR|Seychelles Rupee|f
SDP|Sudanese Pound|f
SEK|Swedish Krona|f
SGD|Singapore Dollar|f
SHP|St. Helena Pound|f
SLL|Sierra Leone Leone|f
SOS|Somali Schilling|f
SRG|Suriname Guilder|f
STD|Sao Tome and Principe Dobra|f
SVC|El Salvador Colon|f
SYP|Syrian Potmd|f
SZL|Swaziland Lilangeni|f
THB|Thai Bhat|f
TND|Tunisian Dinar|f
TOP|Tongan Pa'anga|f
TPE|East Timor Escudo|f
TRL|Turkish Lira|f
TTD|Trinidad and Tobago Dollar|f
TWD|Taiwan Dollar|f
TZS|Tanzanian Schilling|f
UAH|Ukrainan Hryvnia|f
UGS|Uganda Shilling|f
USD|United States Dollar|t
UYP|Uruguayan Peso|f
VEB|Venezualan Bolivar|f
VND|Vietnamese Dong|f
VUV|Vanuatu Vatu|f
WST|Samoan Tala|f
YDD|Democratic Yemeni Dinar|f
YER|Yemeni Rial|f
YUD|New Yugoslavia Dinar|f
ZAR|South African Rand|f
ZMK|Zambian Kwacha|f
ZRZ|Zaire Zaire|f
ZWD|Zimbabwe Dollar|f
