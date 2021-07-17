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

create or replace
view recent_report_cluster as 
with recent_report as (
select
	*
from
	report
where
	obs <> 'T'
	and created >= current_timestamp - interval '1' day),
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
	log(1+count(*)) as weight
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

select * from report;

select
	*
from
	recent_report_cluster;

/*
INSERT INTO public.report
(lat, lng, num_indiv, obs, dir, notes, sender_ip, created)
VALUES
(-26.10952, 28.08802, 10, 'L', '', 'Pan Africa mall', '127.0.0.1', current_timestamp),
(-26.10886,28.08638, 10, 'L', '', 'Alex FM', '127.0.0.1', current_timestamp),
(-26.14860,28.08081, 10, 'L', '', 'Puntans Hill', '127.0.0.1', current_timestamp),
(-26.19768,28.06812, 10, 'L', '', 'Bertrams', '127.0.0.1', current_timestamp),
(-25.94066,28.01973, 10, 'L', '', 'Diepsloot mall', '127.0.0.1', current_timestamp),
(-25.9756,28.2301, 10, 'L', '', 'Diepsloot mall', '127.0.0.1', current_timestamp)

INSERT INTO public.report
(lat, lng, num_indiv, obs, dir, notes, sender_ip, created)
VALUES
(-26.27561,27.81163, 10, 'L', '', 'Protea Glen mall', '127.0.0.1', current_timestamp),
(-26.27561,27.81163, 10, 'L', '', 'Protea Glen mall', '127.0.0.1', current_timestamp),
(-26.27809,27.81597, 10, 'L', '', 'Sizwe shopping centre', '127.0.0.1', current_timestamp),
(-26.27809,27.81597, 10, 'L', '', 'Sizwe shopping centre', '127.0.0.1', current_timestamp)

INSERT INTO public.report
(lat, lng, num_indiv, obs, dir, notes, sender_ip, created)
VALUES
(-29.7833,31.0056, 10, 'L', '', 'Massmart warehouse', '127.0.0.1', current_timestamp),
(-29.7833,31.0056, 10, 'L', '', 'Massmart warehouse', '127.0.0.1', current_timestamp)
*/
