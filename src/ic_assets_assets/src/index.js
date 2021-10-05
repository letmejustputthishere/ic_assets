import { ic_assets } from "../../declarations/ic_assets";

let file;
let batchId;

const uploadChunk = async ({batch_id, chunk}) => ic_assets.create_chunk({
  batch_id,
  content: [...new Uint8Array(await chunk.arrayBuffer())]
})

const upload = async () => {
  console.log('start upload');

  if (!file) {
    console.error('No file selected');
    return;
  }

  const {batch_id} = await ic_assets.create_batch();

  console.log(batch_id);

  const promises = [];

  const chunkSize = 700000;

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
    chunk_ids: chunkIds.map(({chunk_id}) => chunk_id),
    content_type: file.type
  })

  batchId = batch_id;

  console.log('uploaded');
}

const download = () => {
  console.log('download', batchId);

  if (!batchId) {
    return;
  }

  const newImage = document.createElement('img');
  newImage.src = `http://localhost:8000/${batchId}?canisterId=rrkah-fqaaa-aaaaa-aaaaq-cai`;

  const img = document.querySelector('section:last-of-type img');
  img?.parentElement.removeChild(img);

  const section = document.querySelector('section:last-of-type');
  section?.appendChild(newImage);
}

const input = document.querySelector('input');
input?.addEventListener('change', ($event) => {
  file = $event.target.files?.[0];
});

const btnUpload = document.querySelector('button.upload');
btnUpload?.addEventListener('click', upload);

const btnDownload = document.querySelector('button.download');
btnDownload?.addEventListener('click', download);
