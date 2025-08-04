import CryptoJS from "crypto-js";

export function uint8ArrayToWordArray(u8Array: Uint8Array): CryptoJS.lib.WordArray {
	const words = [];
	for (let i = 0; i < u8Array.length; i += 4) {
		words.push((u8Array[i] << 24) | (u8Array[i + 1] << 16) | (u8Array[i + 2] << 8) | u8Array[i + 3]);
	}
	return CryptoJS.lib.WordArray.create(words, u8Array.length);
}

export function wordArrayToUint8Array(wordArray: CryptoJS.lib.WordArray): Uint8Array {
	const { words, sigBytes } = wordArray;
	const u8 = new Uint8Array(sigBytes);
	for (let i = 0; i < sigBytes; i++) {
		u8[i] = (words[i >>> 2] >>> (24 - (i % 4) * 8)) & 0xff;
	}
	return u8;
}
