package handler

import (
	"context"
	"log"
	"net/http"
	"time"

	"optimal-rion/server/controller"
)

// AppToSchoolHandler handles GET /api/app/to-school
func AppToSchoolHandler(fetch *controller.FetchController) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}

		lat, err := parseFloatParam(r, "lat", defaultLat)
		if err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
			return
		}
		lon, err := parseFloatParam(r, "lon", defaultLon)
		if err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
			return
		}
		units := r.URL.Query().Get("units")
		if units == "" {
			units = "metric"
		}
		lang := r.URL.Query().Get("lang")

		ctx, cancel := context.WithTimeout(r.Context(), 8*time.Second)
		defer cancel()

		weather, err := controller.FetchWeather(ctx, fetch, lat, lon, units, lang)
		if err != nil {
			writeJSON(w, http.StatusBadGateway, map[string]string{"error": err.Error()})
			return
		}

		// Fetch Hello Cycling totals (primary IDs only)
		bike, berr := controller.FetchBikeTotals(ctx, fetch)
		if berr != nil {
			log.Printf("[warn] bike totals error: %v", berr)
		}

		var resp AppData
		resp.Title = "Rionized"
		resp.Weather = weather
        // To-school: from station -> campus
        resp.Cycle.DepartureName = "新座駅"
        resp.Cycle.DestinationName = "新座キャンパス"
        resp.Cycle.AvailableAtDeparture = bike.Station.Rentable
        resp.Cycle.AvailableAtDestination = bike.Campus.Returnable

		writeJSON(w, http.StatusOK, resp)
		log.Printf("AppToSchoolHandler: served +%v", resp)
	}
}
