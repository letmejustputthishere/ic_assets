import type { Principal } from '@dfinity/principal';
export interface Chunk { 'content' : Array<number>, 'batch_id' : bigint }
export type HeaderField = [string, string];
export interface HttpRequest {
  'url' : string,
  'method' : string,
  'body' : Array<number>,
  'headers' : Array<HeaderField>,
}
export interface HttpResponse {
  'body' : Array<number>,
  'headers' : Array<HeaderField>,
  'streaming_strategy' : [] | [StreamingStrategy],
  'status_code' : number,
}
export interface StreamingCallbackHttpResponse { 'body' : Array<number> }
export interface StreamingCallbackToken {
  'key' : string,
  'sha256' : [] | [Array<number>],
  'index' : bigint,
  'content_encoding' : string,
}
export type StreamingStrategy = {
    'Callback' : {
      'token' : StreamingCallbackToken,
      'callback' : [Principal, string],
    }
  };
export interface _SERVICE {
  'commit_batch' : (
      arg_0: {
        'batch_id' : bigint,
        'content_type' : string,
        'chunk_ids' : Array<bigint>,
      },
    ) => Promise<undefined>,
  'create_batch' : () => Promise<{ 'batch_id' : bigint }>,
  'create_chunk' : (arg_0: Chunk) => Promise<{ 'chunk_id' : bigint }>,
  'http_request' : (arg_0: HttpRequest) => Promise<HttpResponse>,
  'http_request_streaming_callback' : (
      arg_0: StreamingCallbackToken,
    ) => Promise<StreamingCallbackHttpResponse>,
}
