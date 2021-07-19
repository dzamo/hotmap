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
  Report = object
    id: int
    lat: float
    lng: float
    obs: string
    notes: string
    sender_ip: string
    created: string # TODO: use DateTime?
    temp : float

proc save_report(report: Report) =
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

settings:
    bind_addr = dict.get_section_value("Web_service", "bind_addr")
    port = Port(parse_int(dict.get_section_value("Web_service", "port")))

routes:
    get "/":
        redirect "/index.html"

    post "/reports":
        let now = getTime().toUnix()
        let last_report = report_times.getOrDefault(request.ip)
        
        if now - last_report < 2*60*60:
            resp(
                Http429,
                """"You cannot send another report from this device yet, please
                try again later."""
            )

        report_times[request.ip] = now

        let params = request.params()

        let report = Report(
            lat: parse_float(params["lat-field"]),
            lng: parse_float(params["lng-field"]),
            obs: params["obs-field"],
            notes: params["notes-field"],
            sender_ip: request.ip
        )
        save_report(report)
        logger.log(lvl_info, "Inserted a new report.")
        redirect("/done.html")
        
    get "/reports":
        let params = request.params()
        var and_geo_search: string
        
        try:
            let lat = parse_float(params["lat"])
            let lng = parse_float(params["lng"])
            and_geo_search = fmt"and point(lat, lng) <@> point({lat}, {lng}) < 0.62137119 * 5"
        except ValueError:
            and_geo_search = ""

        let query = sql(fmt(
            """select *
            from report
            where obs = ?
            and created >= current_timestamp - interval ? hour
            {and_geo_search}
            order by created desc"""
        ))

        var reports = new_seq[Report](0)

        for row in db.fast_rows(query, params["obs"], params["period"]):
            let report = Report(
                id: parse_int(row[0]),
                lat: parse_float(row[1]),
                lng: parse_float(row[2]),
                obs: row[3],
                notes: row[4],
                sender_ip: row[5],
                created: row[6]
            )
            reports.add(report)
            
        logger.log(lvl_info, fmt"Returning {len(reports)} reports.")
        resp  %*(reports)

    get "/hot-spots":
        let params = request.params()

        const query = sql"""
            select *
            from hot_spot
            where obs = ?
            and created >= current_timestamp - interval ? hour"""
        var reports = new_seq[Report](0)

        for row in db.fast_rows(query, params["obs"], params["period"]):
            let report = Report(
                id: parse_int(row[0]),
                lat: parse_float(row[1]),
                lng: parse_float(row[2]),
                obs: row[3],
                notes: row[4],
                created: row[5],
                temp: parse_float(row[6])
            )
            reports.add(report)
            
        logger.log(lvl_info, fmt"Returning {len(reports)} reports.")
        resp  %*(reports)

