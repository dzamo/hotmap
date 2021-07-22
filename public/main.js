OBS = {
  testing: "Testing, ignore",
  covid_vac: "COVID-19 vaccination for walk-ins",
  supplies: "Charity or emergency relief supplies",
  crime: "Suspicious or criminal activity",
  dumping: "Illegal dumping, litter or eco hazards",
  fire: "Uncontrolled fire",
  flooding: "Flooding",
  protest: "Protest or civil unrest",
  road: "Impassable roads",
};

NOTES_EGS = {
  testing: "This field will be enabled when you select an observation.",
  covid_vac: "E.g. Midrand firestation, queue 200 people",
  supplies: "E.g. Salvation Army, food and water",
  crime: "E.g. 3 people, attempted mugging, red BMW",
  dumping: "E.g. building rubble",
  fire: "E.g. moving North",
  flooding: "E.g. high clearance vehicles only",
  protest: "E.g. roads blocked",
  road: "E.g. severe potholes",
};

function getPosition(options) {
  return new Promise((resolve, reject) =>
    navigator.geolocation.getCurrentPosition(resolve, reject, options)
  );
}
