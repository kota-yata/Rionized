package handler

import (
	"context"
	"log"
	"net/http"
	"time"

	"optimal-rion/server/controller"
)

// AppToHomeHandler handles GET /api/app/to-home
func AppToHomeHandler(fetch *controller.FetchController) http.HandlerFunc {
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
		resp.Bus.NextDeparture = "18:03"
		resp.Bus.Line = "シティリンク"
		// To-home: from campus -> station
		resp.Cycle.DepartureName = "新座キャンパス"
		resp.Cycle.DestinationName = "新座駅"
		resp.Cycle.AvailableAtDeparture = bike.Campus.Rentable
		resp.Cycle.AvailableAtDestination = bike.Station.Returnable

		writeJSON(w, http.StatusOK, resp)
		log.Printf("AppToHomeHandler: served +%v", resp)
	}
}
