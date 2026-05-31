FROM golang:1.23 AS base

WORKDIR /app

COPY go.mod .

RUN go mod download

COPY . .

RUN go build -o main .

#final image 
FROM gcr.io/distroless/base

COPY --from=base /app/main .

COPY --from=base /app/static ./static

EXPOSE 8080

CMD ["./main"]

