FROM golang:1.21

WORKDIR /app

COPY go.mod go.sum ./
COPY *.go ./

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o /icap-server

EXPOSE 3144

CMD ["/icap-server"]
