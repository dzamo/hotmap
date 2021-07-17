import db_postgres
import json
import jester    # Our webserver
import logging   # Logging utils
import os        # Used to get arguments
import parsecfg  # Parse our config file
import strutils  # Basic functions
import times     # Time and date
import tables
import strformat

let logger = new_console_logger(lvl_info)
let db = open("localhost", "hotmap_user", "loot", "hotmap")
logger.log(lvl_info, "Connected to pg.")

# TODO: this table is wasteful and can grow without bound
var report_times = init_table[string, int64]()

type
  Report = object
    id: int
    lat: float
    lng: float
    num_indiv: int
    obs: string
    dir: string
    notes: string
    sender_ip: string
    created: string # TODO: use DateTime?
    weight : float

proc save_report(report: Report) =
    db.exec(sql"INSERT into report(lat, lng, num_indiv, obs, dir, notes, sender_ip) values(?,?,?,?,?,?,?)",
        report.lat,
        report.lng,
        report.num_indiv,
        report.obs,
        report.dir,
        report.notes,
        report.sender_ip
    )

settings:
    port = Port(7000)
    bind_addr = "0.0.0.0"

routes:
    get "/":
        redirect "/index.html"

    post "/reports":
        let now = getTime().toUnix()
        let last_report = report_times.getOrDefault(request.ip)
        
        if now - last_report < 2*60*60:
            resp(Http429, "You cannot send another report from this device yet, please try again later.")

        report_times[request.ip] = now

        let params = request.params()

        let report = Report(
            lat: parse_float(params["lat-field"]),
            lng: parse_float(params["lng-field"]),
            num_indiv: parse_int(params["num-indiv-field"]),
            obs: params["obs-field"],
            dir: params["dir-field"],
            notes: params["notes-field"],
            sender_ip: request.ip
        )
        save_report(report)
        logger.log(lvl_info, "Inserted a new report.")
        redirect("/done.html")
        
    get "/reports":
        let params = request.params()
        var lat, lng, geo_search = ""
        if params.has_key("lat") and params.has_key("lng"):
            lat = params["lat"]
            lng = params["lng"]
            geo_search = fmt"and point(lat, lng) <@> point({lat}, {lng}) < 0.62137119 * 5"

        var reports = new_seq[Report](0)

        echo(fmt"QUERY = select * from report where created >= current_timestamp - interval '1' day {geo_search} order by created desc")

        let query = sql(fmt("select * from report where created >= current_timestamp - interval '1' day {geo_search} order by created desc"))
        #logging.log(lvl_info, fmt"Executing query {query}")

        for row in db.fast_rows(query):
            let report = Report(
                id: parse_int(row[0]),
                lat: parse_float(row[1]),
                lng: parse_float(row[2]),
                num_indiv: parse_int(row[3]),
                obs: row[4],
                dir: row[5],
                notes: row[6],
                sender_ip: row[7],
                created: row[8]
            )
            reports.add(report)
            
        logger.log(lvl_info, fmt"Returning {len(reports)} reports.")
        resp  %*(reports)

    get "/report-clusters":
        var reports = new_seq[Report](0)

        let query = sql"select * from recent_report_cluster"
        for row in db.fast_rows(query):
            let report = Report(
                id: parse_int(row[0]),
                lat: parse_float(row[1]),
                lng: parse_float(row[2]),
                num_indiv: parse_int(row[3]),
                obs: row[4],
                dir: row[5],
                notes: row[6],
                created: row[7],
                weight: parse_float(row[8])
            )
            reports.add(report)
            
        logger.log(lvl_info, fmt"Returning {len(reports)} reports.")
        resp  %*(reports)

