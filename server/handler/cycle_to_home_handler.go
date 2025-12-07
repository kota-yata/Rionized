package handler

import (
	"context"
	"log"
	"net/http"
	"time"

	"optimal-rion/server/controller"
)

// CycleToHomeHandler returns only the rental cycle information for to-home.
func CycleToHomeHandler(fetch *controller.FetchController) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}

		ctx, cancel := context.WithTimeout(r.Context(), 8*time.Second)
		defer cancel()

		bike, err := controller.FetchBikeTotals(ctx, fetch)
		if err != nil {
			log.Printf("[warn] cycle to-home error: %v", err)
		}

		resp := cycleOnly{
			DepartureName:          "新座キャンパス",
			DestinationName:        "新座駅",
			AvailableAtDeparture:   bike.Campus.Rentable,
			AvailableAtDestination: bike.Station.Returnable,
		}
		writeJSON(w, http.StatusOK, resp)

		log.Printf("CycleToHomeHandler: served %+v", resp)
	}
}
