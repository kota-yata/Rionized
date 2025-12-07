package handler

import (
    "encoding/json"
    "net/http"
    "strconv"
)

// AppData aggregates all sections the app needs.
type AppData struct {
    Title   string `json:"title"`
    Weather interface{} `json:"weather"`
    Cycle struct {
        DepartureName          string `json:"departureName"`
        DestinationName        string `json:"destinationName"`
        AvailableAtDeparture   int    `json:"availableAtDeparture"`
        AvailableAtDestination int    `json:"availableAtDestination"`
    } `json:"cycle"`
}

func writeJSON(w http.ResponseWriter, status int, v any) {
    w.Header().Set("Content-Type", "application/json; charset=utf-8")
    w.WriteHeader(status)
    _ = json.NewEncoder(w).Encode(v)
}

const (
    defaultLat = 35.813583
    defaultLon = 139.565710
)

func parseFloatParam(r *http.Request, key string, def float64) (float64, error) {
    s := r.URL.Query().Get(key)
    if s == "" {
        return def, nil
    }
    return strconv.ParseFloat(s, 64)
}
