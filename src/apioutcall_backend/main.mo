import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Nat8 "mo:base/Nat8";
import Cycles "mo:base/ExperimentalCycles";
import Error "mo:base/Error";
import Debug "mo:base/Debug";

actor {
    type HttpHeader = {
        name : Text;
        value : Text;
    };

    type HttpResponsePayload = {
        status : Nat;
        headers : [HttpHeader];
        body : [Nat8];
    };

    type HttpRequestArgs = {
        url : Text;
        max_response_bytes : ?Nat64;
        headers : [HttpHeader];
        body : ?[Nat8];
        method : {#get; #post; #head};
        transform : ?{
            function : shared query (HttpResponsePayload) -> async HttpResponsePayload;
            context : Blob;
        };
    };

    public func sendHello() : async Text {
        let url = "https://[2600:1f18:6a6d:800:2e59:8111:bb75:202]/transfer";
        let request_body = "{\"message\": \"hello\"}";

        let request_body_as_Blob : Blob = Text.encodeUtf8(request_body);
        let request_body_as_nat8 : [Nat8] = Blob.toArray(request_body_as_Blob);

        let request : HttpRequestArgs = {
            url = url;
            max_response_bytes = ?10000;
            headers = [
                { name = "Host"; value = "[2600:1f18:6a6d:800:2e59:8111:bb75:202]:3000" },
                { name = "Content-Type"; value = "application/json" },
                { name = "X-Auth-Token"; value = "Fpf#}'CY\"Pquy^c[wA)>(;emg/]:ZHs=!84WaDrL.hSKR_5X+k" }
            ];
            body = ?request_body_as_nat8;
            method = #post;
            transform = null;
        };

        Cycles.add(200_000_000_000);
        let ic : actor { http_request : HttpRequestArgs -> async HttpResponsePayload } = actor "aaaaa-aa";
        
        try {
            let response = await ic.http_request(request);
            let response_body: Blob = Blob.fromArray(response.body);
            let decoded_text: Text = switch (Text.decodeUtf8(response_body)) {
                case (null) { "No value returned" };
                case (?y) { y };
            };
            Debug.print("Response: " # decoded_text);
            decoded_text
        } catch (error) {
            Debug.print("Error: " # Error.message(error));
            "Error: " # Error.message(error)
        }
    };

    public query func transform(raw : HttpResponsePayload) : async HttpResponsePayload {
        {
            status = raw.status;
            body = raw.body;
            headers = [
                { name = "Content-Security-Policy"; value = "default-src 'self'" },
                { name = "Referrer-Policy"; value = "strict-origin" },
                { name = "Permissions-Policy"; value = "geolocation=(self)" },
                { name = "Strict-Transport-Security"; value = "max-age=63072000" },
                { name = "X-Frame-Options"; value = "DENY" },
                { name = "X-Content-Type-Options"; value = "nosniff" },
            ];
        }
    };
};