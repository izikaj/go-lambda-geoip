.PHONY: download build clean purify deploy

download:
	curl -o GeoLite2-City.tar.gz "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=$(MAXMIND_LICENSE_KEY)&suffix=tar.gz"
	curl -o GeoLite2-Country.tar.gz "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country&license_key=$(MAXMIND_LICENSE_KEY)&suffix=tar.gz"

purify:
	echo '' > GeoLite2-Country.mmdb
	go-bindata -nocompress -o country/bindata.go GeoLite2-Country.mmdb
	go-bindata -nocompress -o geocoder/bindata.go GeoLite2-Country.mmdb
	rm GeoLite2-Country.mmdb

	echo '' > GeoLite2-City.mmdb
	go-bindata -nocompress -o city/bindata.go GeoLite2-City.mmdb
	rm GeoLite2-City.mmdb

build:
	tar -xf GeoLite2-Country.tar.gz
	mv GeoLite2-Country_*/GeoLite2-Country.mmdb GeoLite2-Country.mmdb
	rm -rf GeoLite2-Country_*
	go-bindata -nocompress -o country/bindata.go GeoLite2-Country.mmdb
	go-bindata -nocompress -o geocoder/bindata.go GeoLite2-Country.mmdb
	rm GeoLite2-Country.mmdb

	tar -xf GeoLite2-City.tar.gz
	mv GeoLite2-City_*/GeoLite2-City.mmdb GeoLite2-City.mmdb
	rm -rf GeoLite2-City_*
	go-bindata -nocompress -o city/bindata.go GeoLite2-City.mmdb
	rm GeoLite2-City.mmdb

	env GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o bin/country country/*.go
	env GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o bin/city city/*.go
	env GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o bin/geocoder geocoder/*.go

clean: purify
	rm -rf ./bin
	rm -rf GeoLite2-City_*
	rm -rf GeoLite2-Country_*

deploy: clean build purify
	sls deploy --verbose
