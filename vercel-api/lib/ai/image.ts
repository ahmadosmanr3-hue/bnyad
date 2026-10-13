import { RequestError } from '../http';
const invalid = () => { throw new RequestError('Use a valid JPEG or PNG up to 1600 pixels per side.',422); };
function dimensions(width: number, height: number) { if (width < 1 || height < 1 || width > 1600 || height > 1600) invalid(); }

/** Strip EXIF/GPS/comments and ancillary PNG metadata without decoding pixels.
 * No photo, extracted metadata or image bytes are persisted or logged. */
export function sanitizeImage(bytes: Buffer, mimeType: string): Buffer {
  if (mimeType === 'image/png') {
    const signature = Buffer.from([137,80,78,71,13,10,26,10]);
    if (!bytes.subarray(0,8).equals(signature)) return invalid();
    const kept: Buffer[] = [signature]; let offset = 8, header = false;
    while (offset + 12 <= bytes.length) {
      const length = bytes.readUInt32BE(offset), type = bytes.toString('ascii',offset+4,offset+8), end = offset + 12 + length;
      if (end > bytes.length) return invalid();
      if (!header) { if (type !== 'IHDR' || length !== 13) return invalid(); dimensions(bytes.readUInt32BE(offset+8),bytes.readUInt32BE(offset+12)); header = true; }
      if (['IHDR','PLTE','IDAT','IEND','tRNS'].includes(type)) kept.push(bytes.subarray(offset,end));
      offset = end;
      if (type === 'IEND') { if (offset !== bytes.length) return invalid(); return Buffer.concat(kept); }
    }
    return invalid();
  }
  if (mimeType !== 'image/jpeg' || bytes[0] !== 255 || bytes[1] !== 216 || bytes[bytes.length-2] !== 255 || bytes[bytes.length-1] !== 217) return invalid();
  const kept: Buffer[] = [bytes.subarray(0,2)]; let offset = 2, frame = false;
  while (offset + 4 <= bytes.length) {
    if (bytes[offset] !== 255) return invalid();
    const marker = bytes[offset+1];
    if (marker === 218) { if (!frame) return invalid(); kept.push(bytes.subarray(offset)); return Buffer.concat(kept); }
    const length = bytes.readUInt16BE(offset+2), end = offset + 2 + length;
    if (length < 2 || end > bytes.length) return invalid();
    if ([192,193,194].includes(marker)) { if (length < 8) return invalid(); dimensions(bytes.readUInt16BE(offset+7),bytes.readUInt16BE(offset+5)); frame = true; }
    if (!(marker >= 224 && marker <= 239) && marker !== 254) kept.push(bytes.subarray(offset,end));
    offset = end;
  }
  return invalid();
}
