/**
 * Steady — Phone-side JavaScript
 * Fetches CGM data from Nightscout (or Dexcom Share) and sends to watch via AppMessage.
 * Also fetches weather via OpenMeteo (no API key required).
 */

// ─── Config page URL ─────────────────────────────────────────────────────────
// Hosted on the gh-pages branch of this repo.
var CONFIG_URL = 'https://btmx-7.github.io/steady-pebble-watchface/config.html';

// ─── AppMessage Key constants (must match main.c) ────────────────────────────
var KEY_GLUCOSE_VALUE   = 0;
var KEY_GLUCOSE_TREND   = 1;
var KEY_GLUCOSE_DELTA   = 2;
var KEY_LAST_READ_SEC   = 3;
var KEY_GRAPH_DATA      = 4;
var KEY_USE_MMOL        = 5;
var KEY_HIGH_THRESHOLD  = 6;
var KEY_LOW_THRESHOLD   = 7;
var KEY_URGENT_HIGH     = 8;
var KEY_URGENT_LOW      = 9;
var KEY_WEATHER_TEMP    = 10;
var KEY_WEATHER_ICON    = 11;
var KEY_WEATHER_TMIN    = 17;
var KEY_WEATHER_TMAX    = 18;
var KEY_LAYOUT          = 12;
var KEY_SLOT_0          = 13;
var KEY_SLOT_1          = 14;
var KEY_SLOT_2          = 15;
var KEY_SLOT_3          = 16;
var KEY_DEBUG_INFO      = 21;
var KEY_ALERTS_ENABLED  = 22;
var KEY_VIBE_LOW         = 23;
var KEY_VIBE_HIGH        = 24;
var KEY_VIBE_URGENT_LOW  = 25;
var KEY_VIBE_URGENT_HIGH = 26;
var KEY_COLOR_THEME      = 28;
var KEY_DARK_MODE        = 29;

// ─── Trend direction mapping ─────────────────────────────────────────────────
var TREND_MAP = {
  'DoubleUp':          0,
  'SingleUp':          1,
  'FortyFiveUp':       2,
  'Flat':              3,
  'FortyFiveDown':     4,
  'SingleDown':        5,
  'DoubleDown':        6,
  'NOT COMPUTABLE':    7,
  'RATE OUT OF RANGE': 7,
  'NotComputable':     7,
  'RateOutOfRange':    7,
  'None':              7
};

// ─── Settings ────────────────────────────────────────────────────────────────
var settings = {};

function loadSettings() {
  var keys = [
    'nsUrl', 'nsToken', 'dexcomUser', 'dexcomPass', 'useMmol',
    'highThresh', 'lowThresh', 'urgentHigh', 'urgentLow',
    'alertsEnabled', 'vibeLow', 'vibeHigh', 'vibeUrgentLow', 'vibeUrgentHigh',
    'dataSource', 'graphWindow',
    'layout', 'slot0', 'slot1', 'slot2', 'slot3',
    'colorTheme', 'darkMode'
  ];
  keys.forEach(function(k) {
    var v = localStorage.getItem('steady_' + k);
    if (v !== null) settings[k] = v;
  });

  if (!settings.highThresh)  settings.highThresh  = '180';
  if (!settings.lowThresh)   settings.lowThresh   = '70';
  if (!settings.urgentHigh)  settings.urgentHigh  = '250';
  if (!settings.urgentLow)   settings.urgentLow   = '55';
  if (!settings.useMmol)     settings.useMmol     = '0';
  if (!settings.alertsEnabled)  settings.alertsEnabled  = '1';
  if (!settings.vibeLow)        settings.vibeLow        = '1';  // VIBE_TYPE_SHORT_PULSE
  if (!settings.vibeHigh)       settings.vibeHigh       = '1';  // VIBE_TYPE_SHORT_PULSE
  if (!settings.vibeUrgentLow)  settings.vibeUrgentLow  = '3';  // VIBE_TYPE_DOUBLE_PULSE
  if (!settings.vibeUrgentHigh) settings.vibeUrgentHigh = '3';  // VIBE_TYPE_DOUBLE_PULSE
  if (!settings.dataSource)  settings.dataSource  = 'nightscout';
  if (!settings.graphWindow) settings.graphWindow = '37';
  if (!settings.layout)      settings.layout      = '0';  // LAYOUT_SIMPLE
  if (!settings.slot0)       settings.slot0       = '2';  // SLOT_WEATHER
  if (!settings.slot1)       settings.slot1       = '1';  // SLOT_BATTERY
  if (!settings.slot2)       settings.slot2       = '5';  // SLOT_CGM
  if (!settings.slot3)       settings.slot3       = '3';  // SLOT_HEART_RATE
  if (!settings.colorTheme)  settings.colorTheme  = '4';  // COLOR_THEME_CYAN
  if (!settings.darkMode)    settings.darkMode    = '1';
}

function saveSettings(data) {
  Object.keys(data).forEach(function(k) {
    localStorage.setItem('steady_' + k, data[k]);
  });
  loadSettings();
}

// ─── Send CGM data to watch ──────────────────────────────────────────────────

function sendToWatch(glucose, trend, delta, lastReadSec, graphArray) {
  var graphBytes = new Array(graphArray.length);
  for (var i = 0; i < graphArray.length; i++) {
    graphBytes[i] = Math.round(Math.min(graphArray[i], 510) / 2);
  }

  var msg = {};
  msg[KEY_GLUCOSE_VALUE]   = glucose;
  msg[KEY_GLUCOSE_TREND]   = trend;
  msg[KEY_GLUCOSE_DELTA]   = delta;
  msg[KEY_LAST_READ_SEC]   = lastReadSec;
  msg[KEY_GRAPH_DATA]      = graphBytes;
  msg[KEY_USE_MMOL]        = parseInt(settings.useMmol)    || 0;
  msg[KEY_HIGH_THRESHOLD]  = parseInt(settings.highThresh) || 180;
  msg[KEY_LOW_THRESHOLD]   = parseInt(settings.lowThresh)  || 70;
  msg[KEY_URGENT_HIGH]     = parseInt(settings.urgentHigh) || 250;
  msg[KEY_URGENT_LOW]      = parseInt(settings.urgentLow)  || 55;
  msg[KEY_ALERTS_ENABLED]  = parseInt(settings.alertsEnabled)  || 0;
  msg[KEY_VIBE_LOW]        = parseInt(settings.vibeLow)        || 0;
  msg[KEY_VIBE_HIGH]       = parseInt(settings.vibeHigh)       || 0;
  msg[KEY_VIBE_URGENT_LOW] = parseInt(settings.vibeUrgentLow)  || 0;
  msg[KEY_VIBE_URGENT_HIGH]= parseInt(settings.vibeUrgentHigh) || 0;
  msg[KEY_LAYOUT]          = parseInt(settings.layout)     || 0;
  msg[KEY_SLOT_0]          = parseInt(settings.slot0)      || 0;
  msg[KEY_SLOT_1]          = parseInt(settings.slot1)      || 0;
  msg[KEY_SLOT_2]          = parseInt(settings.slot2)      || 0;
  msg[KEY_SLOT_3]          = parseInt(settings.slot3)      || 0;
  msg[KEY_COLOR_THEME]     = parseInt(settings.colorTheme) || 0;
  msg[KEY_DARK_MODE]       = parseInt(settings.darkMode)   || 0;

  Pebble.sendAppMessage(msg,
    function()  { console.log('Steady: CGM data sent OK'); },
    function(e) { console.error('Steady: CGM send failed: ' + JSON.stringify(e)); }
  );
}

// ─── Weather via OpenMeteo ────────────────────────────────────────────────────

function weatherCodeToIconIndex(code) {
  // WMO weather code → 0-7 icon index
  if (code === 0)                                    return 0;  // clear
  if (code >= 1  && code <= 2)                       return 1;  // partly cloudy
  if (code === 3)                                    return 2;  // overcast
  if (code >= 45 && code <= 48)                      return 6;  // fog
  if ((code >= 51 && code <= 67) ||
      (code >= 80 && code <= 82))                    return 3;  // rain/drizzle
  if ((code >= 71 && code <= 77) ||
      (code >= 85 && code <= 86))                    return 5;  // snow
  if (code >= 95 && code <= 99)                      return 4;  // thunderstorm
  return 7;  // default cloud
}

function fetchWeather() {
  navigator.geolocation.getCurrentPosition(
    function(pos) {
      var lat = pos.coords.latitude;
      var lon = pos.coords.longitude;
      var url = 'https://api.open-meteo.com/v1/forecast' +
        '?latitude='  + lat +
        '&longitude=' + lon +
        '&current=temperature_2m,weather_code' +
        '&daily=temperature_2m_min,temperature_2m_max' +
        '&timezone=auto' +
        '&forecast_days=1' +
        '&temperature_unit=celsius';

      var xhr = new XMLHttpRequest();
      xhr.onload = function() {
        if (xhr.status === 200) {
          try {
            var data = JSON.parse(xhr.responseText);
            var temp = Math.round(data.current.temperature_2m);
            var icon = weatherCodeToIconIndex(data.current.weather_code);
            var msg  = {};
            msg[KEY_WEATHER_TEMP] = temp;
            msg[KEY_WEATHER_ICON] = icon;
            // Daily min/max for the active arc range. Fall back to -128 sentinel
            // if the response shape is unexpected.
            var tmin = -128, tmax = -128;
            if (data.daily && data.daily.temperature_2m_min && data.daily.temperature_2m_max) {
              var rawMin = data.daily.temperature_2m_min[0];
              var rawMax = data.daily.temperature_2m_max[0];
              if (typeof rawMin === 'number') tmin = Math.max(-127, Math.min(127, Math.round(rawMin)));
              if (typeof rawMax === 'number') tmax = Math.max(-127, Math.min(127, Math.round(rawMax)));
            }
            msg[KEY_WEATHER_TMIN] = tmin;
            msg[KEY_WEATHER_TMAX] = tmax;
            Pebble.sendAppMessage(msg,
              function()  { console.log('Steady: weather sent OK (' + temp + 'C [' + tmin + ',' + tmax + '] icon=' + icon + ')'); },
              function(e) { console.error('Steady: weather send failed: ' + JSON.stringify(e)); }
            );
          } catch(e) {
            console.error('Steady: weather parse error: ' + e.message);
          }
        } else {
          console.error('Steady: weather HTTP error ' + xhr.status);
        }
      };
      xhr.onerror = function() { console.error('Steady: weather network error'); };
      xhr.open('GET', url);
      xhr.send();
    },
    function(err) {
      // Geolocation denied or unavailable: send sentinel value (-128)
      console.log('Steady: geolocation unavailable, code=' + err.code);
      var msg = {};
      msg[KEY_WEATHER_TEMP] = -128;
      msg[KEY_WEATHER_ICON] = 7;
      msg[KEY_WEATHER_TMIN] = -128;
      msg[KEY_WEATHER_TMAX] = -128;
      Pebble.sendAppMessage(msg, function(){}, function(){});
    }
  );
}

// ─── Nightscout Fetch ────────────────────────────────────────────────────────

function fetchNightscout() {
  if (!settings.nsUrl) {
    console.log('Steady: No Nightscout URL configured');
    return;
  }

  var count = parseInt(settings.graphWindow) || 37;
  var url = settings.nsUrl.replace(/\/$/, '') +
    '/api/v1/entries.json?count=' + count;
  if (settings.nsToken) url += '&token=' + encodeURIComponent(settings.nsToken);

  var xhr = new XMLHttpRequest();
  xhr.onload = function() {
    if (xhr.status === 200) {
      try {
        var entries = JSON.parse(xhr.responseText);
        if (!entries || entries.length === 0) return;

        var latest  = entries[0];
        var glucose  = parseInt(latest.sgv) || 0;
        var trendStr = latest.direction || 'None';
        var trend    = TREND_MAP[trendStr] !== undefined ? TREND_MAP[trendStr] : 7;
        var delta    = parseInt(latest.delta) || 0;
        var lastRead = Math.round((latest.date || new Date(latest.dateString).getTime() || 0) / 1000);

        if (!latest.delta && entries.length >= 2) {
          delta = glucose - (parseInt(entries[1].sgv) || glucose);
        }

        var graphData = [];
        for (var i = entries.length - 1; i >= 0; i--) {
          graphData.push(parseInt(entries[i].sgv) || 0);
        }

        sendToWatch(glucose, trend, delta, lastRead, graphData);
      } catch(e) {
        console.error('Steady: NS parse error: ' + e.message);
      }
    } else {
      console.error('Steady: NS HTTP error ' + xhr.status);
    }
  };
  xhr.onerror = function() { console.error('Steady: NS network error'); };
  xhr.open('GET', url);
  xhr.send();
}

// ─── Dexcom Share Fetch ──────────────────────────────────────────────────────

var DEXCOM_AUTH_URL     = '/ShareWebServices/Services/General/AuthenticatePublisherAccount';
var DEXCOM_LOGIN_URL    = '/ShareWebServices/Services/General/LoginPublisherAccountById';
var DEXCOM_READINGS_URL = '/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues';
var DEXCOM_APP_ID       = 'd89443d2-327c-4a6f-89e5-496bbb0317db';
var DEXCOM_ZERO_GUID    = '00000000-0000-0000-0000-000000000000';
var s_dexcom_session_id = null;
var s_dexcom_base_url   = 'https://share2.dexcom.com';

// POSTs `body` to `path` on the current Dexcom base URL with a 10s watchdog.
// The Android pkjs runtime executes inside a WebView, so cross-origin XHRs
// go through real browser CORS; the watchdog turns a hung preflight into a
// clear log line instead of silence. Calls done(status, responseText), with
// status 0 for a network/CORS error or timeout.
function dexcomPost(path, body, done) {
  var url = s_dexcom_base_url + path;
  var xhr = new XMLHttpRequest();
  var finished = false;
  var watchdog = setTimeout(function() {
    if (finished) return;
    finished = true;
    console.error('Steady: Dexcom request to ' + path + ' timed out (likely CORS-blocked in WebView)');
    xhr.abort();
    done(0, '');
  }, 10000);
  xhr.onload = function() {
    if (finished) return;
    finished = true;
    clearTimeout(watchdog);
    done(xhr.status, xhr.responseText);
  };
  xhr.onerror = function() {
    if (finished) return;
    finished = true;
    clearTimeout(watchdog);
    console.error('Steady: Dexcom request to ' + path + ' network/CORS error');
    done(0, '');
  };
  xhr.open('POST', url);
  xhr.setRequestHeader('Content-Type', 'application/json');
  xhr.setRequestHeader('Accept', 'application/json');
  xhr.send(body);
}

// Dexcom Share login is two steps: AuthenticatePublisherAccount resolves the
// username to an accountId, then LoginPublisherAccountById (which requires
// that accountId, not the username) returns the session id. Skipping the
// first step and passing the username directly as accountId is rejected
// with an all-zero GUID, which looks identical to bad credentials.
function dexcomLogin(callback, isRetry) {
  var authBody = JSON.stringify({
    accountName:   settings.dexcomUser,
    password:      settings.dexcomPass,
    applicationId: DEXCOM_APP_ID
  });
  dexcomPost(DEXCOM_AUTH_URL, authBody, function(status, text) {
    var accountId = text ? text.replace(/"/g, '') : '';
    if (status !== 200 || !accountId || accountId === DEXCOM_ZERO_GUID) {
      if (!isRetry && s_dexcom_base_url.indexOf('shareous') === -1) {
        console.error('Steady: Dexcom auth rejected on ' + s_dexcom_base_url + ' (status ' + status + '), retrying on OUS server');
        s_dexcom_base_url = 'https://shareous1.dexcom.com';
        dexcomLogin(callback, true);
        return;
      }
      console.error('Steady: Dexcom authentication failed, status=' + status + ', response="' + text + '"');
      s_dexcom_session_id = null;
      callback(false);
      return;
    }

    var loginBody = JSON.stringify({
      accountId:     accountId,
      password:      settings.dexcomPass,
      applicationId: DEXCOM_APP_ID
    });
    dexcomPost(DEXCOM_LOGIN_URL, loginBody, function(status2, text2) {
      var sessionId = text2 ? text2.replace(/"/g, '') : '';
      if (status2 !== 200 || !sessionId || sessionId === DEXCOM_ZERO_GUID) {
        console.error('Steady: Dexcom login failed, status=' + status2 + ', response="' + text2 + '"');
        s_dexcom_session_id = null;
        callback(false);
        return;
      }
      s_dexcom_session_id = sessionId;
      callback(true);
    });
  });
}

function dexcomFetchReadings() {
  var count = parseInt(settings.graphWindow) || 37;
  var url = s_dexcom_base_url + DEXCOM_READINGS_URL +
    '?sessionId=' + s_dexcom_session_id +
    '&minutes=180&maxCount=' + count;
  var xhr = new XMLHttpRequest();
  var done = false;
  var watchdog = setTimeout(function() {
    if (done) return;
    done = true;
    console.error('Steady: Dexcom readings request timed out (likely CORS-blocked in WebView)');
    xhr.abort();
  }, 10000);
  xhr.onload = function() {
    if (done) return;
    done = true;
    clearTimeout(watchdog);
    if (xhr.status === 200) {
      if (!xhr.responseText) {
        // Empty body: session expired/invalid. Force a fresh login next time.
        console.error('Steady: Dexcom empty response, response="' + xhr.responseText + '"');
        s_dexcom_session_id = null;
        return;
      }
      try {
        var readings = JSON.parse(xhr.responseText);
        if (!readings || readings.length === 0) return;
        var latest  = readings[0];
        var glucose = parseInt(latest.Value) || 0;
        // Modern Dexcom Share returns Trend as a string name (e.g. "Flat");
        // older versions returned a numeric code. Handle both.
        var trend;
        if (TREND_MAP[latest.Trend] !== undefined) {
          trend = TREND_MAP[latest.Trend];
        } else {
          trend = parseInt(latest.Trend) - 1;
          if (trend < 0 || trend > 6) trend = 7;
        }
        var delta   = readings.length >= 2 ?
          glucose - (parseInt(readings[1].Value) || glucose) : 0;
        var lastRead = 0;
        var tsMatch  = latest.ST.match(/\d+/);
        if (tsMatch) lastRead = Math.round(parseInt(tsMatch[0]) / 1000);
        var graphData = [];
        for (var i = readings.length - 1; i >= 0; i--) {
          graphData.push(parseInt(readings[i].Value) || 0);
        }
        sendToWatch(glucose, trend, delta, lastRead, graphData);
      } catch(e) {
        console.error('Steady: Dexcom parse error: ' + e.message + ', response="' + xhr.responseText + '"');
      }
    } else if (xhr.status === 500) {
      s_dexcom_session_id = null;
      fetchDexcom();
    }
  };
  xhr.onerror = function() {
    if (done) return;
    done = true;
    clearTimeout(watchdog);
    console.error('Steady: Dexcom readings network/CORS error, status=' + xhr.status);
  };
  xhr.open('GET', url);
  xhr.setRequestHeader('Accept', 'application/json');
  xhr.send();
}

function fetchDexcom() {
  if (!settings.dexcomUser || !settings.dexcomPass) {
    console.error('Steady: Dexcom fetch skipped, missing credentials (user=' +
      (settings.dexcomUser ? 'set' : 'MISSING') + ', pass=' +
      (settings.dexcomPass ? 'set' : 'MISSING') + ')');
    return;
  }
  if (s_dexcom_session_id) dexcomFetchReadings();
  else dexcomLogin(function(ok) { if (ok) dexcomFetchReadings(); });
}

// ─── Main Fetch ──────────────────────────────────────────────────────────────

function fetchData() {
  loadSettings();
  console.log('Steady: fetchData, dataSource=' + settings.dataSource);
  if (settings.dataSource === 'dexcom') fetchDexcom();
  else fetchNightscout();
}

// ─── Pebble Event Handlers ───────────────────────────────────────────────────

Pebble.addEventListener('ready', function() {
  console.log('Steady JS ready');
  loadSettings();
  fetchData();
  fetchWeather();
  setInterval(fetchData,    5  * 60 * 1000);  // CGM every 5 min
  setInterval(fetchWeather, 30 * 60 * 1000);  // weather every 30 min
});

Pebble.addEventListener('appmessage', function(e) {
  var payload = e.payload || {};
  // Key may come back as the numeric AppMessage key or the friendly
  // messageKeys name depending on runtime — accept either.
  var debugInfo = payload[KEY_DEBUG_INFO] || payload['KEY_DEBUG_INFO'];
  if (debugInfo) {
    console.log('Steady: health debug — ' + debugInfo);
    return;
  }
  console.log('Steady: message from watch, payload=' + JSON.stringify(payload));
  fetchData();
});

Pebble.addEventListener('showConfiguration', function() {
  loadSettings();
  var url = CONFIG_URL +
    '?nsUrl='       + encodeURIComponent(settings.nsUrl       || '') +
    '&dexcomUser='  + encodeURIComponent(settings.dexcomUser  || '') +
    '&dataSource='  + encodeURIComponent(settings.dataSource  || 'nightscout') +
    '&useMmol='     + encodeURIComponent(settings.useMmol     || '0') +
    '&highThresh='  + encodeURIComponent(settings.highThresh  || '180') +
    '&lowThresh='   + encodeURIComponent(settings.lowThresh   || '70') +
    '&urgentHigh='  + encodeURIComponent(settings.urgentHigh  || '250') +
    '&urgentLow='   + encodeURIComponent(settings.urgentLow   || '55') +
    '&alertsEnabled=' + encodeURIComponent(settings.alertsEnabled || '1') +
    '&vibeLow=' + encodeURIComponent(settings.vibeLow || '1') +
    '&vibeHigh=' + encodeURIComponent(settings.vibeHigh || '1') +
    '&vibeUrgentLow=' + encodeURIComponent(settings.vibeUrgentLow || '3') +
    '&vibeUrgentHigh=' + encodeURIComponent(settings.vibeUrgentHigh || '3') +
    '&graphWindow=' + encodeURIComponent(settings.graphWindow || '37') +
    '&layout='      + encodeURIComponent(settings.layout      || '0') +
    '&slot0='       + encodeURIComponent(settings.slot0       || '2') +
    '&slot1='       + encodeURIComponent(settings.slot1       || '1') +
    '&slot2='       + encodeURIComponent(settings.slot2       || '5') +
    '&slot3='       + encodeURIComponent(settings.slot3       || '3') +
    '&colorTheme='  + encodeURIComponent(settings.colorTheme  || '4') +
    '&darkMode='    + encodeURIComponent(settings.darkMode    || '1');
  Pebble.openURL(url);
});

Pebble.addEventListener('webviewclosed', function(e) {
  console.log('Steady: webviewclosed, response=' + (e.response ? 'present (' + e.response.length + ' chars)' : 'MISSING'));
  if (e.response) {
    try {
      var data = JSON.parse(decodeURIComponent(e.response));
      saveSettings(data);
      console.log('Steady: settings saved, dataSource=' + settings.dataSource +
        ', dexcomUser=' + (settings.dexcomUser ? 'set' : 'empty') +
        ', dexcomPass=' + (settings.dexcomPass ? 'set' : 'empty'));
      // Send layout + slot settings to watch immediately
      var msg = {};
      msg[KEY_LAYOUT] = parseInt(data.layout) || 0;
      msg[KEY_SLOT_0] = parseInt(data.slot0)  || 0;
      msg[KEY_SLOT_1] = parseInt(data.slot1)  || 0;
      msg[KEY_SLOT_2] = parseInt(data.slot2)  || 0;
      msg[KEY_SLOT_3] = parseInt(data.slot3)  || 0;
      msg[KEY_COLOR_THEME] = parseInt(data.colorTheme) || 0;
      msg[KEY_DARK_MODE]   = parseInt(data.darkMode)   || 0;
      Pebble.sendAppMessage(msg, function(){}, function(){});
      fetchData();
    } catch(err) {
      console.error('Steady: config parse error: ' + err);
    }
  }
});
