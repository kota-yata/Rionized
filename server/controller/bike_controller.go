package controller

import (
    "context"
)

const (
    helloInfoURL   = "https://api-public.odpt.org/api/v4/gbfs/hellocycling/station_information.json"
    helloStatusURL = "https://api-public.odpt.org/api/v4/gbfs/hellocycling/station_status.json"
)

// GBFS Information payload (partial)
type helloInfo struct {
    Data struct {
        Stations []struct {
            StationID string `json:"station_id"`
            Capacity  int    `json:"capacity"`
        } `json:"stations"`
    } `json:"data"`
}

// GBFS Status payload (partial)
type helloStatus struct {
    Data struct {
        Stations []struct {
            StationID          string `json:"station_id"`
            NumBikesAvailable  int    `json:"num_bikes_available"`
            NumDocksAvailable  *int   `json:"num_docks_available,omitempty"`
        } `json:"stations"`
    } `json:"data"`
}

type groupTotals struct {
    Rentable  int `json:"rentable"`
    Returnable int `json:"returnable"`
}

// BikeTotalsDTO aggregates totals for off-campus station group and campus group (primary IDs only).
type BikeTotalsDTO struct {
    Station groupTotals `json:"station"`
    Campus  groupTotals `json:"campus"`
}

// Primary station ID groups (public IDs; safe to embed)
var (
    // Campus bike primary IDs
    campusPrimaryIDs = []string{"14743", "5770", "5769", "3151", "4223", "3150", "16774", "5778", "5776", "6832"}
    // Nearest station (Shonandai/Niiza etc.) primary IDs
    stationPrimaryIDs = []string{"6504", "6503", "7060", "6502", "23069"}
)

// FetchBikeTotals fetches Hello Cycling GBFS and computes totals for the primary station groups.
// It reads CAMPUS_BIKE_PRIMARY and STATION_BIKE_PRIMARY from the environment.
func FetchBikeTotals(ctx context.Context, f *FetchController) (BikeTotalsDTO, error) {
    var out BikeTotalsDTO

    var info helloInfo
    if err := f.GetJSON(ctx, helloInfoURL, nil, &info); err != nil {
        return out, err
    }
    var status helloStatus
    if err := f.GetJSON(ctx, helloStatusURL, nil, &status); err != nil {
        return out, err
    }

    capByID := map[string]int{}
    for _, s := range info.Data.Stations {
        capByID[s.StationID] = s.Capacity
    }
    type st struct{ bikes int; docks *int }
    stByID := map[string]st{}
    for _, s := range status.Data.Stations {
        stByID[s.StationID] = st{bikes: s.NumBikesAvailable, docks: s.NumDocksAvailable}
    }

    rentable := func(id string) int {
        s, ok := stByID[id]
        if !ok {
            return 0
        }
        if s.bikes < 0 { return 0 }
        return s.bikes
    }
    returnable := func(id string) int {
        s, ok := stByID[id]
        if !ok {
            return 0
        }
        if s.docks != nil {
            if *s.docks < 0 { return 0 }
            return *s.docks
        }
        cap := capByID[id]
        v := cap - s.bikes
        if v < 0 { return 0 }
        return v
    }

    // Sum for each group
    for _, id := range stationPrimaryIDs {
        out.Station.Rentable += rentable(id)
        out.Station.Returnable += returnable(id)
    }
    for _, id := range campusPrimaryIDs {
        out.Campus.Rentable += rentable(id)
        out.Campus.Returnable += returnable(id)
    }

    return out, nil
}
