vcl 4.0;
import std;

backend default {
    .host = "mtg-nginx"; # nginx proxy container for yr
    .port = "80";
}

sub vcl_backend_response {
    set beresp.ttl = 1m;
    set beresp.grace = 1d;
}

sub vcl_recv {
    # Normalize the query arguments
    set req.url = std.querysort(req.url);

    # Remove has_js and CloudFlare/Google Analytics __* cookies.
    set req.http.Cookie = regsuball(req.http.Cookie, "(^|;\s*)(_[_a-z]+|has_js)=[^;]*", "");
    # Remove a ";" prefix, if present.
    set req.http.Cookie = regsub(req.http.Cookie, "^;\s*", "");

    # We don't use #
    if (req.url ~ "\#") {
      set req.url = regsub(req.url, "\#.*$", "");
    }

    # Strip a trailing ? if it exists
    if (req.url ~ "\?$") {
      set req.url = regsub(req.url, "\?$", "");
    }
}

sub vcl_deliver {
    # Add reponse header that indicates hit or miss on the cache
    # Should probably not be used in production
    if (obj.hits > 0) {
            set resp.http.X-Varnish-Cache = "HIT";
    } else {
            set resp.http.X-Varnish-Cache = "MISS";
    }
    set resp.http.Access-Control-Allow-Origin = "*";
}