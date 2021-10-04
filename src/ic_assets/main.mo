import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Blob "mo:base/Blob";
import Iter "mo:base/Iter";

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
                        headers = [ ("content-type", content_type) ];
                        status_code = 200;
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
            chunk_ids: [Nat]
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
 