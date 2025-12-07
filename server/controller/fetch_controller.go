package controller

import (
    "context"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "net/url"
    "time"
)

// FetchController is a thin abstraction around http.Client with helpers
// for building URLs and decoding JSON. Other controllers should depend on it
// to access external APIs.
type FetchController struct {
    Client *http.Client
}

func NewFetchController() *FetchController {
    return &FetchController{
        Client: &http.Client{Timeout: 10 * time.Second},
    }
}

// BuildURL builds a URL with query parameters.
func (f *FetchController) BuildURL(base string, q map[string]string) (string, error) {
    u, err := url.Parse(base)
    if err != nil {
        return "", err
    }
    qs := u.Query()
    for k, v := range q {
        if v != "" {
            qs.Set(k, v)
        }
    }
    u.RawQuery = qs.Encode()
    return u.String(), nil
}

// HTTPError represents a non-2xx response from a remote server.
type HTTPError struct {
    StatusCode int
    Body       string
}

func (e *HTTPError) Error() string { return fmt.Sprintf("remote error %d: %s", e.StatusCode, e.Body) }

// GetJSON performs a GET request and decodes a JSON response into out.
func (f *FetchController) GetJSON(ctx context.Context, fullURL string, headers map[string]string, out any) error {
    req, err := http.NewRequestWithContext(ctx, http.MethodGet, fullURL, nil)
    if err != nil {
        return err
    }
    for k, v := range headers {
        req.Header.Set(k, v)
    }

    resp, err := f.Client.Do(req)
    if err != nil {
        return err
    }
    defer resp.Body.Close()

    if resp.StatusCode < 200 || resp.StatusCode >= 300 {
        b, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
        return &HTTPError{StatusCode: resp.StatusCode, Body: string(b)}
    }

    dec := json.NewDecoder(resp.Body)
    // Allow unknown fields so partial structs can decode
    return dec.Decode(out)
}
