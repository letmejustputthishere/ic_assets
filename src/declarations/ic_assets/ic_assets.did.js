export const idlFactory = ({ IDL }) => {
  const Chunk = IDL.Record({
    'content' : IDL.Vec(IDL.Nat8),
    'batch_id' : IDL.Nat,
  });
  const HeaderField = IDL.Tuple(IDL.Text, IDL.Text);
  const HttpRequest = IDL.Record({
    'url' : IDL.Text,
    'method' : IDL.Text,
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HeaderField),
  });
  const HttpResponse = IDL.Record({
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HeaderField),
    'status_code' : IDL.Nat16,
  });
  return IDL.Service({
    'commit_batch' : IDL.Func(
        [
          IDL.Record({
            'batch_id' : IDL.Nat,
            'content_type' : IDL.Text,
            'chunk_ids' : IDL.Vec(IDL.Nat),
          }),
        ],
        [],
        [],
      ),
    'create_batch' : IDL.Func([], [IDL.Record({ 'batch_id' : IDL.Nat })], []),
    'create_chunk' : IDL.Func(
        [Chunk],
        [IDL.Record({ 'chunk_id' : IDL.Nat })],
        [],
      ),
    'http_request' : IDL.Func([HttpRequest], [HttpResponse], ['query']),
  });
};
export const init = ({ IDL }) => { return []; };
