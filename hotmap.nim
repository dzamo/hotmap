import db_postgres
import json
import jester
import logging
import parsecfg
import strutils
import times
import tables
import strformat
import std/sha1

let logger = new_console_logger(lvl_info)
let dict = load_config("config.cfg")

let sender_ip_salt = dict.get_section_value("Web_service", "sender_ip_salt")

let db = open(
    dict.get_section_value("Database", "host"),
    dict.get_section_value("Database", "user"),
    dict.get_section_value("Database", "password"),
    dict.get_section_value("Database", "db")
)
logger.log(
    lvl_info,
    fmt"""Connected to pg database {dict.get_section_value("Database", "db")}."""
)

type
  HotSpotReport = object
    lat: float
    lng: float
    obs: string
    notes: string
    sender_ip_hash: string
    created: string
    distance: float
    age_hours: float

type
  Report = object
    id: int
    lat: float
    lng: float
    obs: string
    notes: string
    sender_ip: string
    created: string # TODO: use DateTime?

proc get_sender_ip(request: Request): string =
    try:
        return request.headers["X-Real-IP"]
    except KeyError:
        return request.ip


settings:
    bind_addr = dict.get_section_value("Web_service", "bind_addr")
    port = Port(parse_int(dict.get_section_value("Web_service", "port")))

routes:
    get "/":
        redirect "/index.html"

    post "/reports":
        const user_send_rate_sql = sql"""
            select count(*) reports_in_24h
            from report
            where sender_ip = ?
              and created >= current_timestamp - interval '24' hour
            """

        let sender_ip = get_sender_ip(request)
        let user_send_rate = parse_int(db.get_value(user_send_rate_sql, sender_ip))
        
        if user_send_rate >= 5:
            resp(
                Http429,
                """You cannot send another report from this device yet, please
                try again later."""
            )
            logger.log(lvl_info, fmt"Rate limited a new report from {sender_ip}.")

        let params = request.params()

        let report = Report(
            lat: parse_float(params["lat"]),
            lng: parse_float(params["lng"]),
            obs: params["obs"],
            notes: params.get_or_default("notes"),
            sender_ip: sender_ip
        )
        const insert_sql = sql"""
            insert into report(lat, lng, obs, notes, sender_ip)
            values(?,?,?,?,?)
            """

        db.exec(insert_sql,
            report.lat,
            report.lng,
            report.obs,
            report.notes,
            report.sender_ip
        )

        logger.log(lvl_info, fmt"Inserted a new report from {sender_ip}.")
        redirect("/done.html")
        
    get "/reports":
        let params = request.params()
        let sender_ip = get_sender_ip(request)
        var lat, lng = 0.0
        var radius_km = 1e10
        
        try:
            lat = parse_float(params["lat"])
            lng = parse_float(params["lng"])
            radius_km = parse_float(params["radius-km"])
        except ValueError:
            discard

        let query = sql(fmt(
            """
            select
                lat,
                lng,
                obs,
                notes,
                sender_ip,
                created,
                case
                    when ? < 1e10 then 1.609344 * (point(lat,lng) <@> point(?,?))
                    else 1e10
                end distance
            from
                report
            where
                obs = ?
                and point(lat,lng) <@> point(?,?) < 0.62137119 * ?
            order by
                created desc
            limit 100
            """
        ))

        var reports = new_seq[HotSpotReport](0)

        for row in db.fast_rows(
            query,
            radius_km,
            lat, lng,
            params["obs"],
            lat, lng,
            radius_km
        ):
            let report = HotSpotReport(
                lat: parse_float(row[0]),
                lng: parse_float(row[1]),
                obs: row[2],
                notes: row[3],
                sender_ip_hash: $secure_hash(fmt"{sender_ip_salt}{row[4]}"),
                created: row[5],
                distance: parse_float(row[6])
                
            )
            reports.add(report)
            
        logger.log(lvl_info, fmt"Returning {len(reports)} reports to {sender_ip}.")
        resp  %*(reports)

    get "/hot-spots":
        let params = request.params()
        let sender_ip = get_sender_ip(request)

        const query = sql"""
			select lat,
			      lng,
			      obs,
			      notes,
			      created,
			      extract(epoch
			              from (current_timestamp - created))/3600e0 age_hours
			from report
			where obs = ?
			 and created >= current_date - interval '90' day
            """

        var reports = new_seq[HotSpotReport](0)

        for row in db.fast_rows(query, params["obs"]):
            let report = HotSpotReport(
                lat: parse_float(row[0]),
                lng: parse_float(row[1]),
                obs: row[2],
                notes: row[3],
                created: row[4],
                age_hours: parse_float(row[5])
            )
            reports.add(report)
            
        logger.log(lvl_info, fmt"Returning {len(reports)} reports to {sender_ip}.")
        resp  %*(reports)

