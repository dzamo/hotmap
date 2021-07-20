import db_postgres
import json
import jester
import logging
import parsecfg
import strutils
import times
import tables
import strformat

let logger = new_console_logger(lvl_info)
let dict = load_config("config.cfg")

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

# TODO: this table is wasteful and can grow without bound
var report_times = init_table[string, int64]()

type
  HotSpotReport = object
    lat: float
    lng: float
    obs: string
    notes: string
    created: string
    distance: float
    temp : float

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
        let now = getTime().toUnix()
        let sender_ip = get_sender_ip(request)
        let last_report = report_times.getOrDefault(sender_ip)
        
        if now - last_report < 2*60*60:
            resp(
                Http429,
                """"You cannot send another report from this device yet, please
                try again later."""
            )

        report_times[sender_ip] = now

        let params = request.params()

        let report = Report(
            lat: parse_float(params["lat-field"]),
            lng: parse_float(params["lng-field"]),
            obs: params["obs-field"],
            notes: params["notes-field"],
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
                created,
                case
                    when ? < 1e10 then 1.609344 * (point(lat,lng) <@> point(?,?))
                    else 1e10
                end distance
            from
                report
            where
                obs = ?
                and created >= current_timestamp - interval ? hour
                and point(lat,lng) <@> point(?,?) < 0.62137119 * ?
            order by
                created desc
            """
        ))

        var reports = new_seq[HotSpotReport](0)

        for row in db.fast_rows(
            query,
            radius_km,
            lat, lng,
            params["obs"],
            params["period"],
            lat, lng,
            radius_km
        ):
            let report = HotSpotReport(
                lat: parse_float(row[0]),
                lng: parse_float(row[1]),
                obs: row[2],
                notes: row[3],
                created: row[4],
                distance: parse_float(row[5])
                
            )
            reports.add(report)
            
        logger.log(lvl_info, fmt"Returning {len(reports)} reports to {sender_ip}.")
        resp  %*(reports)

    get "/hot-spots":
        let params = request.params()
        let sender_ip = get_sender_ip(request)
        let heat_xfer_coef = 1/parse_float(params["period"])

        # TODO the next cast to float caused by something quoting
        # the heat_xfer_coef parameter is very annoying
        const query = sql"""
            select 
                lat,
                lng,
                obs,
                notes,
                created,
                2^(-cast(? as float) * age_hours) "temp"
            from hotspot_report
            where obs = ?
            """

        var reports = new_seq[HotSpotReport](0)

        for row in db.fast_rows(query, heat_xfer_coef, params["obs"]):
            let report = HotSpotReport(
                lat: parse_float(row[0]),
                lng: parse_float(row[1]),
                obs: row[2],
                notes: row[3],
                created: row[4],
                temp: parse_float(row[5])
            )
            reports.add(report)
            
        logger.log(lvl_info, fmt"Returning {len(reports)} reports to {sender_ip}.")
        resp  %*(reports)

