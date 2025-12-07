package main

import (
    "log"
    "net/http"
    "os"
    "time"

    "optimal-rion/server/controller"
    "optimal-rion/server/routes"
)

func withCORS(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Access-Control-Allow-Origin", "*")
        w.Header().Set("Access-Control-Allow-Methods", "GET,OPTIONS")
        w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
        if r.Method == http.MethodOptions {
            w.WriteHeader(http.StatusNoContent)
            return
        }
        next.ServeHTTP(w, r)
    })
}

func main() {
    // Construct shared fetch controller
    fetch := controller.NewFetchController()
    mux := routes.New(fetch)

    // Optionally warn if API key is not set
    if os.Getenv("OPENWEATHER_API_KEY") == "" {
        log.Println("[warn] OPENWEATHER_API_KEY not set; upstream calls will fail")
    }

    srv := &http.Server{
        Addr:         ":8080",
        Handler:      withCORS(mux),
        ReadTimeout:  5 * time.Second,
        WriteTimeout: 10 * time.Second,
        IdleTimeout:  60 * time.Second,
    }

    log.Println("server listening on http://localhost:8080")
    if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
        log.Fatalf("server error: %v", err)
    }
}

