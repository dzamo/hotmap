--drop table report cascade;
create table report (
	id serial primary key,
	lat float not null,
	lng float not null,
	obs text not null,
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
	obs <> 'testing'
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
	obs,
	notes,
	created,
	log(1+count(*)) as "temp" -- temperature
from
	adjacent
group by
	id,
	lat,
	lng,
	obs,
	notes,
	created;

-- tests
select count(*) from report;

select * from report;

select
	*
from
	hot_spot;
