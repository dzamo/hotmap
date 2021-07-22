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

create index ix_obs_created on report(obs, created);

create index ix_sender_created on report(sender_ip, created);

-- tests
select count(*) from report;

explain analyse
select
	*
from
	report
where
	obs = 'covid_vac'
order by
	created desc;

select 
	*, 
	2^(-${heat_xfer_coef} * age_hours) "temp"
from summary_report;


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