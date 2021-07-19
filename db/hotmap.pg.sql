-- drop table report;
create table report (
	id serial primary key,
	lat float not null,
	lng float not null,
	num_indiv int not null,
	obs text not null,
	dir text,
	notes text,
	sender_ip text,
	created timestamp not null default now()
);

create or replace view hot_spot as 
with recent_report as (
select
	*
from
	report
where
	obs <> 'T'
	and created >= current_timestamp - interval '30' day),
adjacent as (
select
	rr1.*
from
	recent_report rr1
left join recent_report rr2 on
	point(rr1.lat, rr1.lng) <@> point(rr2.lat, rr2.lng) < 0.62137119 * 0.2 -- km converted to miles
)
select
	id,
	lat,
	lng,
	num_indiv,
	obs,
	dir,
	notes,
	created,
	log(1+count(*)) as "temp" -- temperature
from
	adjacent
group by
	id,
	lat,
	lng,
	num_indiv,
	obs,
	dir,
	notes,
	created;

-- tests
select * from report;

select
	*
from
	hot_spot;

-- Load from Google User Map for riots and looting
/*
truncate table public.report;

-- https://www.google.com/maps/d/u/0/viewer?mid=1eDx6D_PEhXr9YIzIjWfw6ZXKFs_wiZ5D&ll=-27.24739924915443%2C27.691551771875027&z=7
INSERT INTO public.report (lng, lat, notes, num_indiv, obs, dir, sender_ip, created) VALUES
(28.1549166666667,-26.0075277777778,'Unverified Threat 12:02', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.0901388888889,-25.7523055555556,'Lotus Gardens - Gang Related Incident - Not Riot Related', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.111,-26.0572777777778,'House Fire - Not riot related 20:51', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.943282,-26.259455,'Bara Square - Cleanup Underway 14:00', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.1444444444444,-26.2182777777778,'Truck Overturned - Not Riot Related - 14:25', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.1550497,-26.3304731,'Shoprite Katlehong 11:50 (Clear)', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.217162,-25.679015,'Pick n Pay Sinoville 12:00 (safe)', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.02068,-26.09646,'House Fire - Not Riot Related', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.114502,-26.360456,'Looting (Unverified) 15 JUL 21', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.9543333333333,-26.0551666666667,'Veld Fire - Not Riot Related 15 JUL 21', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.853886,-26.1977689,'Braamfischer Primary School - False complaint', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.1676666666667,-26.1651111111111,'Truck Fire - Not Riot Related 15 JUL 21', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.1059142,-26.016795,'Waterfall Park Veld Fire 15 JULY 21', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.8367936,-26.3508349,'Ans Interior Design 14 JUL 21', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.1980277777778,-25.9922222222222,'Possible Hostile Area 14 JUL 21', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.0742939,-26.2245665,'56 Heidelberg Rd 20:55 (Unverified) 14 JUL 21', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.39091,-26.1370572,'Benoni East Fire 18:57 14 JULY 21', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.4221519,-26.1452452,'Daveyton - Monitored Threat - 14 JUL 21', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.4086318,-26.13481,'Pick n Pay Mayfield Square 14 JUL 21', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.1149028,-26.1130876,'Lombardy East & Rembrandt Warning (Unverified) 18:32 14 JUL 21', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.1276096,-25.9964357,'Boulders Shopping Centre - Unverified Threat', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.2033714,-25.9589335,'Mall of Thembisa - Unverified Threat 14 July 2021', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.0046124,-26.2175632,'Planet Avenue', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.3357682,-26.1819093,'Snake Road', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.869059,-26.1597459,'Albertina Sisulu Road & Station Street', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.086718,-26.11025,'Watt Avenue & 3rd Street (Cold)', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.9014305,-26.2582467,'Maponya Mall', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.341465,-25.7196504,'Tshwane Mall', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.3878196,-26.2829216,'Ackermans Springs Kwathema Square', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.1384217,-26.3245635,'Cliffy''s Hyper Land', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.826088,-26.5313509,'Torga Optical Evaton Plaza Optometrists', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.9493212,-26.2418511,'Diepkloof Square', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.844554,-26.496347,'Capitec Bank Sebokeng Palm Springs Mall', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.9949483,-25.9314842,'Bambanani Shopping Centre', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.9368122,-26.287782,'Devland', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.0630169,-26.1834392,'Yeoville', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.0651664,-25.7624607,'Nkomo Village Boxer Superstores', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.7993358,-26.1589768,'Chamdor Liquors', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.177672,-26.003947,'Ebony Mall', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.0566039,-26.2038183,'Commissioner Street', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.3333278,-25.7142781,'Exact - Mamelodi Crossing', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.0496215,-26.1936353,'Hillbrow', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.8879251,-26.2791542,'8 1st St', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.0126801,-26.2172206,'Crown Mines', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.790485,-26.269213,'Shoprite Glen Ridge Mall', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.1201391,-26.414144,'Sky City Mall', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.127168,-26.394441,'Wild Plum Street & Wild Olive Street', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.0880905,-26.0994152,'Usave Marlboro', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.2704347,-26.2573688,'Sunward Park Lifestyle Centre', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.1213773,-26.1052918,'Alex Mall.', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.1190398,-26.10843,'River Park Drive', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.396462,-25.7138417,'Police Station Mamelodi East', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.2033669,-26.2876634,'Nitrogen Road', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.205964,-26.287377,'Green Valley Meat Market', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.4038961,-26.1228033,'Putfontein AH', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.1526196,-26.3651259,'Katlehong', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.092729,-26.12602,'Pick n Pay Bramley', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.0078103,-26.2177262,'84 Planet Ave (G4S HQ)', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.85805,-26.2505566,'Absa | Branch | Jabulani', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.8816079,-26.1651129,'Onslow Avenue', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.8370041,-26.4101352,'Ennerdale', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.1955329,-26.0264588,'Nedbank Tembisa Plaza', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.2073486,-26.2301367,'Ramaphosa Taxi Rank', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.846645,-26.6017433,'Shoprite Sebokeng Plaza', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.2296722,-25.9756071,'Phumulani Mall', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.8549981,-26.2835457,'Mangalani', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.9677394,-26.2055898,'Zamimpilo Seventh-day Adventist Church', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.0963274,-26.0967089,'66 3rd St', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.1927703,-26.0376301,'Birch Acres Mall', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.2403897,-25.9911356,'Usave Tembisa', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.2048157,-26.3219168,'Luthando Street', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.205877,-25.980868,'Pick n Pay Ivory Park', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.1742195,-26.0323309,'Cash build Tembisa west', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.1529999,-26.2005799,'Marathon Supermarket', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.2209061,-26.0094689,'Tembisa Mall', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.3345479,-26.558667,'Ratanda Mall (Shopping Center)', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.4103981,-26.134236,'Mayfield Square Shopping Centre', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.087512,-26.109481,'Pan Africa Shopping Centre.', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.0030333,-26.0915625,'Randburg Square', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.8274399,-26.5281064,'Evaton Mall riots', 10, 'W', '', '127.0.0.1', current_timestamp),
(28.174262,-26.033444,'Modderfontein Road & Mastiff Road (12:58 looting)', 10, 'W', '', '127.0.0.1', current_timestamp),
(27.8494444444444,-26.1679166666667,'Unverified Threat 19:30', 10, 'W', '', '127.0.0.1', current_timestamp);
*/

-- Simulate uniform noise in the rectangle bounding the extant reports to
-- test whether enough good reports visually fade out bad reports.
/*  
INSERT INTO public.report (lng, lat, notes, num_indiv, obs, dir, sender_ip)
select
	(select min(lng) from report)+random()*((select max(lng) from report) - (select min(lng) from report)),
	(select min(lat) from report)+random()*((select max(lat) from report) - (select min(lat) from report)),
	'Simulated noise',
	0,
	'W',
	'',
	'127.0.0.1'
from public.report 
order by id
limit 82;
*/