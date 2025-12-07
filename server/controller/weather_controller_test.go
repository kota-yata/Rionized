package controller

import (
    "context"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "net/url"
    "os"
    "testing"
    "time"
)

// rewriteTransport rewrites outgoing requests to hit a test server
// while preserving the original request path and query.
type rewriteTransport struct {
    base *url.URL
    rt   http.RoundTripper
}

func (t *rewriteTransport) RoundTrip(req *http.Request) (*http.Response, error) {
    r2 := req.Clone(req.Context())
    r2.URL.Scheme = t.base.Scheme
    r2.URL.Host = t.base.Host
    return t.rt.RoundTrip(r2)
}

// minimalOneCall marshals a minimal One Call response with provided values.
func minimalOneCall(currentDt int64, temp float64, humidity int, minutely []struct{ Dt int64; P float64 }) []byte {
    type cur struct {
        Dt        int64   `json:"dt"`
        Temp      float64 `json:"temp"`
        FeelsLike float64 `json:"feels_like"`
        Pressure  int     `json:"pressure"`
        Humidity  int     `json:"humidity"`
        UVI       float64 `json:"uvi"`
        Clouds    int     `json:"clouds"`
        WindSpeed float64 `json:"wind_speed"`
        WindDeg   int     `json:"wind_deg"`
    }
    type min struct {
        Dt            int64   `json:"dt"`
        Precipitation float64 `json:"precipitation"`
    }
    oc := struct {
        Lat            float64 `json:"lat"`
        Lon            float64 `json:"lon"`
        Timezone       string  `json:"timezone"`
        TimezoneOffset int     `json:"timezone_offset"`
        Current        cur     `json:"current"`
        Minutely       []min   `json:"minutely"`
    }{
        Lat:            10,
        Lon:            20,
        Timezone:       "UTC",
        TimezoneOffset: 0,
        Current: cur{Dt: currentDt, Temp: temp, FeelsLike: temp, Pressure: 1000, Humidity: humidity, UVI: 3.2, Clouds: 0, WindSpeed: 0, WindDeg: 0},
    }
    for _, m := range minutely {
        oc.Minutely = append(oc.Minutely, min{Dt: m.Dt, Precipitation: m.P})
    }
    b, _ := json.Marshal(oc)
    return b
}

func setupTestFetch(t *testing.T, body []byte, expectPath string) (*FetchController, func()) {
    t.Helper()
    srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        if r.URL.Path != expectPath {
            http.NotFound(w, r)
            return
        }
        // Basic param presence checks
        if r.URL.Query().Get("lat") == "" || r.URL.Query().Get("lon") == "" || r.URL.Query().Get("appid") == "" {
            http.Error(w, "missing params", http.StatusBadRequest)
            return
        }
        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusOK)
        _, _ = w.Write(body)
    }))

    u, _ := url.Parse(srv.URL)
    fc := NewFetchController()
    fc.Client = &http.Client{
        Timeout:   5 * time.Second,
        Transport: &rewriteTransport{base: u, rt: http.DefaultTransport},
    }
    os.Setenv("OPENWEATHER_API_KEY", "testkey")
    cleanup := func() { srv.Close() }
    return fc, cleanup
}

func TestFetchWeather_Precip10Min_Exact(t *testing.T) {
    current := int64(1_000)
    // Target is 1_000 + 600 = 1_600
    body := minimalOneCall(current, 22.5, 55, []struct{ Dt int64; P float64 }{
        {Dt: 1500, P: 0.0},
        {Dt: 1600, P: 0.4}, // exact 10-minute mark
        {Dt: 1700, P: 1.2},
    })
    fetch, done := setupTestFetch(t, body, "/data/3.0/onecall")
    defer done()

    dto, err := FetchWeather(context.Background(), fetch, 35.0, 139.0, "metric", "ja")
    if err != nil {
        t.Fatalf("FetchWeather error: %v", err)
    }
    if dto.Precip10Min != 0.4 {
        t.Fatalf("unexpected precip10min: got %.2f want %.2f", dto.Precip10Min, 0.4)
    }
    if dto.TemperatureC != 22.5 || dto.HumidityPercent != 55 {
        t.Fatalf("unexpected temp/humidity: got %.2f/%d", dto.TemperatureC, dto.HumidityPercent)
    }
}

func TestFetchWeather_Precip10Min_FallbackLast(t *testing.T) {
    current := int64(10_000)
    // Target is 10_600. All entries are before target; should pick last (0.2)
    body := minimalOneCall(current, 18.0, 65, []struct{ Dt int64; P float64 }{
        {Dt: 10500, P: 0.0},
        {Dt: 10520, P: 0.2},
    })
    fetch, done := setupTestFetch(t, body, "/data/3.0/onecall")
    defer done()

    dto, err := FetchWeather(context.Background(), fetch, 51.5, -0.1, "metric", "en")
    if err != nil {
        t.Fatalf("FetchWeather error: %v", err)
    }
    if dto.Precip10Min != 0.2 {
        t.Fatalf("unexpected precip10min: got %.2f want %.2f", dto.Precip10Min, 0.2)
    }
}

