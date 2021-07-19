OBS = {
  testing: "Testing, ignore",
  covid_vac: "COVID-19 vaccination for walk-ins",
  crime: "Suspicious or criminal activity",
  fire: "Fire",
  supplies: "Charity or emergency relief supplies",
  weather: "Extreme weather",
};

NOTES_EGS = {
  testing: "This field will be enabled when you select an observation.",
  covid_vac: "E.g. 10 surplus doses, queue length 30 minutes",
  crime: "E.g. about 50 people, looting, moving North",
  fire: "E.g. fire break jumped here, buildings nearby",
  supplies: "E.g. food, water, blankets",
  weather: "E.g. flooding, road impassable, power lines down",
};

function getPosition(options) {
  return new Promise((resolve, reject) =>
    navigator.geolocation.getCurrentPosition(resolve, reject, options)
  );
}
