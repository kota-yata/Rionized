package controller

import (
	"context"
	"log"
	"os"
	"strconv"
)

const oneCall3 = "https://api.openweathermap.org/data/3.0/onecall"

// OneCallResponse is a partial model of the One Call API 3.0 response
// containing only fields we need: current weather and minutely forecast.
type OneCallResponse struct {
	Lat            float64 `json:"lat"`
	Lon            float64 `json:"lon"`
	Timezone       string  `json:"timezone"`
	TimezoneOffset int     `json:"timezone_offset"`
	Current        struct {
		Dt        int64   `json:"dt"`
		Temp      float64 `json:"temp"`
		FeelsLike float64 `json:"feels_like"`
		Pressure  int     `json:"pressure"`
		Humidity  int     `json:"humidity"`
		UVI       float64 `json:"uvi"`
		Clouds    int     `json:"clouds"`
		WindSpeed float64 `json:"wind_speed"`
		WindDeg   int     `json:"wind_deg"`
	} `json:"current"`
	Minutely []struct {
		Dt            int64   `json:"dt"`
		Precipitation float64 `json:"precipitation"`
	} `json:"minutely"`
}

// Public DTO for app consumption (server output shape)
type WeatherDTO struct {
	UVIndex         float64 `json:"uvIndex"`
	TemperatureC    float64 `json:"temperatureC"`
	HumidityPercent int     `json:"humidityPercent"`
	Precip10Min     float64 `json:"precip10min"`
}

// FetchWeather retrieves weather from OpenWeather and normalizes it for the app.
func FetchWeather(ctx context.Context, f *FetchController, lat, lon float64, units, lang string) (WeatherDTO, error) {
	apiKey := os.Getenv("OPENWEATHER_API_KEY")
	q := map[string]string{
		"lat":   strconv.FormatFloat(lat, 'f', 6, 64),
		"lon":   strconv.FormatFloat(lon, 'f', 6, 64),
		"appid": apiKey,
	}
	if units != "" {
		q["units"] = units
	}
	if lang != "" {
		q["lang"] = lang
	}

	base := os.Getenv("OPENWEATHER_ONECALL_BASE")
	if base == "" {
		base = oneCall3
	}

	u, err := f.BuildURL(base, q)
	if err != nil {
		return WeatherDTO{}, err
	}

	var oc OneCallResponse
	if err := f.GetJSON(ctx, u, nil, &oc); err != nil {
		log.Printf("FetchWeather: GetJSON error: %v", err)
		return WeatherDTO{}, err
	}

	// Determine precipitation 10 minutes later from minutely data
	target := oc.Current.Dt + 10*60
	var precip10 float64
	var picked bool
	for _, m := range oc.Minutely {
		if m.Dt >= target {
			precip10 = m.Precipitation
			picked = true
			break
		}
	}
	if !picked && len(oc.Minutely) > 0 {
		precip10 = oc.Minutely[len(oc.Minutely)-1].Precipitation
	}

	wd := WeatherDTO{
		UVIndex:         oc.Current.UVI,
		TemperatureC:    oc.Current.Temp, // expects units=metric for Celsius
		HumidityPercent: oc.Current.Humidity,
		Precip10Min:     precip10,
	}
	return wd, nil
}
