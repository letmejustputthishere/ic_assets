import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Array "mo:base/Array";
import Time "mo:base/Time";

actor Assets {

    private type HeaderField = (Text, Text);
    private type HttpRequest = {
        url : Text;
        method : Text;
        body : [Nat8];
        headers : [HeaderField];
    };
    private type HttpResponse = {
        body : Blob;
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

    private let chunks: HashMap.HashMap<Nat, Chunk> = HashMap.HashMap<Nat, Chunk>(
        0, Nat.equal, Hash.hash,
    );

    private let assets: HashMap.HashMap<Nat, AssetEncoding> = HashMap.HashMap<Nat, AssetEncoding>(
        0, Nat.equal, Hash.hash,
    );

    public shared query({caller}) func http_request(
        r : HttpRequest,
    ) : async HttpResponse {
        return {
            body = Text.encodeUtf8("Hello World!");
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
        {batch_id: Nat; chunk_ids: [Nat]} : {
            batch_id: Nat;
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

            assets.put(batch_id, {
                modified  = Time.now();
                content_chunks;
                certified = false;
                total_length
            });
         };
    };

};
 