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
  'status_code' : number,
}
export interface _SERVICE {
  'commit_batch' : (
      arg_0: { 'batch_id' : bigint, 'chunk_ids' : Array<bigint> },
    ) => Promise<undefined>,
  'create_batch' : () => Promise<{ 'batch_id' : bigint }>,
  'create_chunk' : (arg_0: Chunk) => Promise<{ 'chunk_id' : bigint }>,
  'http_request' : (arg_0: HttpRequest) => Promise<HttpResponse>,
}
