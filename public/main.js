NOTES_EGS = {
  testing: "This field will be enabled when you select an observation.",
  dumping: "E.g. building rubble",
  road: "E.g. Lower Park Drive",
  electricity: "E.g. since about 18:20",
  water: "E.g. since about 18:30",
  gas: "E.g. since about 18:40",
  bird: "E.g. Western Barn Owl",
  crime: "E.g. suspicious group of three men",
};

function getPosition(options) {
  return new Promise((resolve, reject) =>
    navigator.geolocation.getCurrentPosition(resolve, reject, options)
  );
}
