package routes

import (
	"net/http"

	"optimal-rion/server/controller"
	"optimal-rion/server/handler"
)

// Register wires up the HTTP routes.
// It registers a single endpoint that returns all data needed by the app.
func Register(mux *http.ServeMux, fetch *controller.FetchController) {
	mux.HandleFunc("/api/app/to-school", handler.AppToSchoolHandler(fetch))
	mux.HandleFunc("/api/app/to-home", handler.AppToHomeHandler(fetch))
	mux.HandleFunc("/api/cycle/to-school", handler.CycleToSchoolHandler(fetch))
	mux.HandleFunc("/api/cycle/to-home", handler.CycleToHomeHandler(fetch))
}

// New returns a pre-configured ServeMux with routes registered.
func New(fetch *controller.FetchController) *http.ServeMux {
	mux := http.NewServeMux()
	Register(mux, fetch)
	return mux
}
