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

with recent_report as (
select
	*
from
	report
where
	obs = '${obs}'
	and created >= current_timestamp - interval '${period}' day),
adjacent as (
select
	rr1.*
from
	recent_report rr1
left join recent_report rr2 on
	point(rr1.lat, rr1.lng) <@> point(rr2.lat, rr2.lng) < 0.62137119 * 0.2
	-- km converted to miles
)
select
	id,
	lat,
	lng,
	obs,
	notes,
	created,
	log(2, 1 + count(*)) as "temp"
	-- temperature

	from adjacent
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

SELECT
	lat,
	lng,
	obs,
	notes,
	created,
	CASE
		WHEN ${radius_km} < 1e10 THEN 1.609344 * (point(lat,lng) <@> point(${lat},${lng}))
	END distance
FROM
	report
WHERE
	obs = ?
	AND created >= current_timestamp - INTERVAL '30' day
	AND point(lat,lng) <@> point(${lat},${lng}) < 0.62137119 * ${radius_km}
ORDER BY
	created DESC