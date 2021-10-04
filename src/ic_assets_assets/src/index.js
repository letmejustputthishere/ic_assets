import { ic_assets } from "../../declarations/ic_assets";

let file;

const uploadChunk = async ({batch_id, chunk}) => ic_assets.create_chunk({
  batch_id,
  content: [...new Uint8Array(await chunk.arrayBuffer())]
})

const upload = async () => {
  if (!file) {
    console.error('No file selected');
    return;
  }

  const {batch_id} = await ic_assets.create_batch();

  console.log(batch_id);

  const promises = [];

  const chunkSize = 2000000;

  for (let start = 0; start < file.size; start += chunkSize) {
    const chunk = file.slice(start, start + chunkSize + 1);

    promises.push(uploadChunk({
      batch_id,
      chunk
    }));
  }

  const chunkIds = await Promise.all(promises);

  console.log(chunkIds);

  await ic_assets.commit_batch({
    batch_id,
    chunk_ids: chunkIds.map(({chunk_id}) => chunk_id)
  })

  console.log('uploaded');
}

const input = document.querySelector('input');
input?.addEventListener('change', ($event) => {
  file = $event.target.files?.[0];
});

const btn = document.querySelector('button');
btn?.addEventListener('click', upload);
