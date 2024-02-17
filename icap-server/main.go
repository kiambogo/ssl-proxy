package main

import (
	"fmt"
	"log"

	"github.com/go-icap/icap"
)

func main() {
	log.Printf("Starting ICAP listener")
	icap.HandleFunc("/", logReq)
	err := icap.ListenAndServe(":1344", icap.HandlerFunc(logReq))
	if err != nil {
		log.Fatalf("Error starting ICAP server: %v", err)
	}
}

func logReq(w icap.ResponseWriter, req *icap.Request) {
	h := w.Header()

	h.Set("Service", "ICAP service")

	switch req.Method {
	case "OPTIONS":
		h.Set("Methods", "REQMOD")
		h.Set("Allow", "204")
		h.Set("Preview", "0")
		h.Set("Transfer-Preview", "*")
		w.WriteHeader(200, nil, false)

	case "REQMOD":
		// Passthrough CONNECT header unmodified
		if req.Request.Method == "CONNECT" {
			w.WriteHeader(204, nil, false)
		}

		log.Printf("ICAP Request received:\n\tURL: %s\n\tMethod: %s\n\tHeaders: %v\n", req.URL.String(), req.Method, req.Header)
		log.Printf("Request received:\n\tURL: %s\n\tMethod: %s\n\tHeaders: %v\n", req.Request.URL.String(), req.Request.Method, req.Request.Header)

		req.Request.Header.Set("Authorization", "Bearer <GITHUB TOKEN>")

		log.Printf("Request modified:\n\tURL: %s\n\tMethod: %s\n\tHeaders: %v\n", req.Request.URL.String(), req.Request.Method, req.Request.Header)

		w.WriteHeader(200, req.Request, false)

	default:
		w.WriteHeader(405, nil, false)
		fmt.Println("Invalid request method")
	}
}
