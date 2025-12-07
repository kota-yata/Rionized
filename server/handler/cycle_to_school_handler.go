package handler

import (
	"context"
	"log"
	"net/http"
	"time"

	"optimal-rion/server/controller"
)

type cycleOnly struct {
	DepartureName          string `json:"departureName"`
	DestinationName        string `json:"destinationName"`
	AvailableAtDeparture   int    `json:"availableAtDeparture"`
	AvailableAtDestination int    `json:"availableAtDestination"`
}

// CycleToSchoolHandler returns only the rental cycle information for to-school.
func CycleToSchoolHandler(fetch *controller.FetchController) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}

		// Optional lat/lon not used here; GBFS is global
		ctx, cancel := context.WithTimeout(r.Context(), 8*time.Second)
		defer cancel()

		bike, err := controller.FetchBikeTotals(ctx, fetch)
		if err != nil {
			log.Printf("[warn] cycle to-school error: %v", err)
		}

		resp := cycleOnly{
			DepartureName:          "新座駅",
			DestinationName:        "新座キャンパス",
			AvailableAtDeparture:   bike.Station.Rentable,
			AvailableAtDestination: bike.Campus.Returnable,
		}
		writeJSON(w, http.StatusOK, resp)

		log.Printf("CycleToSchoolHandler: served %+v", resp)
	}
}
