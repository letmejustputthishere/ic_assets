import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import Error "mo:base/Error";

import Debug "mo:base/Debug";

actor Assets {

    private type HeaderField = (Text, Text);
    private type HttpRequest = {
        url : Text;
        method : Text;
        body : [Nat8];
        headers : [HeaderField];
    };
    private type HttpResponse = {
        body : [Nat8];
        headers : [HeaderField];
        status_code : Nat16;
        streaming_strategy : ?StreamingStrategy;
    };

    private type StreamingStrategy = {
        #Callback : {
            token : StreamingCallbackToken;
            callback : shared query StreamingCallbackToken -> async StreamingCallbackHttpResponse;
        };
    };

    private type StreamingCallbackToken = {
        key : Text;
        index : Nat;
    };

    public type StreamingCallbackHttpResponse = {
        body : [Nat8];
    };

    private var nextBatchID: Nat = 0;
    private var nextChunkID: Nat = 0;

    private type Chunk = {
        batch_id : Nat;
        content  : [Nat8];
    };

    private type AssetEncoding = {
        modified       : Int;
        content_chunks : [[Nat8]];
        total_length   : Nat;
        certified      : Bool;
        // TODO do we need sha256         : [Nat8]; ?
    };

    private type Asset = {
        encoding: AssetEncoding;
        content_type: Text;
    };

    private let chunks: HashMap.HashMap<Nat, Chunk> = HashMap.HashMap<Nat, Chunk>(
        0, Nat.equal, Hash.hash,
    );

    private let assets: HashMap.HashMap<Text, Asset> = HashMap.HashMap<Text, Asset>(
        0, Text.equal, Text.hash,
    );

    public shared query({caller}) func http_request(
        request : HttpRequest,
    ) : async HttpResponse {
        if (request.method == "GET") {
            // remove ?canisterId=.... from /1?canisterId=....
            let split: Iter.Iter<Text> = Text.split(request.url, #char '?');
            let key: Text = Iter.toArray(split)[0];

            let asset: ?Asset = assets.get(key);

            switch (asset) {
                case (?{content_type: Text; encoding: AssetEncoding;}) {
                    return {
                        body = encoding.content_chunks[0];
                        headers = [ ("Content-Type", content_type), 
                                    ("accept-ranges", "bytes"),
                                    ("cache-control", "private, max-age=0") ];
                        status_code = 200;
                        streaming_strategy = create_strategy(
                            key, 0, {content_type; encoding;}, encoding,
                        );
                    };
                };
                case null {
                };
            };
        };

        return {
            body = Blob.toArray(Text.encodeUtf8(request.url));
            headers = [];
            status_code = 200;
            streaming_strategy = null;
        };
    };

    private func create_strategy(
        key           : Text,
        index         : Nat,
        asset         : Asset,
        encoding      : AssetEncoding,
    ) : ?StreamingStrategy {
        switch (create_token(key, index, asset, encoding)) {
            case (null) { null };
            case (? token) {
                ?#Callback({
                    token;
                    callback = http_request_streaming_callback;
                });
            };
        };
    };

    public shared query({caller}) func http_request_streaming_callback(
        st : StreamingCallbackToken,
    ) : async StreamingCallbackHttpResponse {

        Debug.print(debug_show("A"));
        Debug.print(debug_show(st.index));

        switch (assets.get(st.key)) {
            case (null) throw Error.reject("key not found: " # st.key);
            case (? asset) {
                return {
                        token = create_token(
                        st.key,
                        st.index,
                        asset, 
                        asset.encoding,
                    );
                    body  = asset.encoding.content_chunks[st.index];
                };
            };
        };
    };

    private func create_token(
        key              : Text,
        chunk_index      : Nat,
        asset            : Asset,
        encoding         : AssetEncoding,
    ) : ?StreamingCallbackToken {

        Debug.print(debug_show("B"));
        Debug.print(debug_show(chunk_index));
        Debug.print(debug_show(encoding.content_chunks.size()));
        Debug.print(debug_show(key));

        if (chunk_index + 1 >= encoding.content_chunks.size()) {
            null;
        } else {
            ?{
                key;
                index = chunk_index + 1;
            };
        };
    };

    public shared({caller}) func create_batch() : async {
        batch_id : Nat
    } {
        nextBatchID := nextBatchID + 1;
        return {batch_id = nextBatchID};
    };

    public shared({caller}) func create_chunk(chunk: Chunk) : async {
        chunk_id : Nat
    } {
        nextChunkID := nextChunkID + 1;

        chunks.put(nextChunkID, chunk);

        return {chunk_id = nextChunkID};
    };

    public shared({caller}) func commit_batch(
        {batch_id: Nat; chunk_ids: [Nat]; content_type: Text;} : {
            batch_id: Nat;
            content_type: Text;
            chunk_ids: [Nat];
        },
    ) : async () {
         var content_chunks : [[Nat8]] = [];

         for (chunk_id in chunk_ids.vals()) {
            let chunk: ?Chunk = chunks.get(chunk_id);

            switch (chunk) {
                case (?{content}) {
                    content_chunks := Array.append<[Nat8]>(content_chunks, [content]);
                };
                case null {
                };
            };
         };

         if (content_chunks.size() > 0) {
            var total_length = 0;
            for (chunk in content_chunks.vals()) total_length += chunk.size();    

            assets.put(Text.concat("/", Nat.toText(batch_id)), {
                content_type = content_type;
                encoding = {
                    modified  = Time.now();
                    content_chunks;
                    certified = false;
                    total_length
                };
            });
         };
    };

};
 