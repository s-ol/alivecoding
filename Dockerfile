FROM nickblah/lua:5.3-luarocks-stretch AS build-env

WORKDIR /build
RUN apt-get update && \
    apt-get install -y --allow-unauthenticated \
      build-essential m4 libmarkdown2-dev

RUN luarocks install discount DISCOUNT_INCDIR=/usr/include/x86_64-linux-gnu && \
    luarocks install moonscript

COPY . /build/
RUN make docs

FROM nginx:alpine
COPY --from=build-env /build/docs /usr/share/nginx/html
RUN chmod 555 -R /usr/share/nginx/html
