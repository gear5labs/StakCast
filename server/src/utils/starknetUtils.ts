import { randomBytes, pbkdf2Sync, createCipheriv, createDecipheriv } from "crypto";

export function encryptPrivateKey(privateKey: Uint8Array, password: string): string {
	// Derive a 32-byte key
	const salt = randomBytes(16);
	const key = pbkdf2Sync(Buffer.from(password, "utf8"), salt, 100_000, 32, "sha256");

	// GCM needs a 12-byte IV
	const iv = randomBytes(12);
	const cipher = createCipheriv("aes-256-gcm", key, iv);

	const ciphertext = Buffer.concat([cipher.update(Buffer.from(privateKey)), cipher.final()]);
	const tag = cipher.getAuthTag();

	return JSON.stringify({
		v: 1,
		kdf: "pbkdf2-sha256",
		iter: 100000,
		// base64 for compactness
		ct: ciphertext.toString("base64"),
		iv: iv.toString("base64"),
		salt: salt.toString("base64"),
		tag: tag.toString("base64"),
	});
}

export function decryptPrivateKey(encryptedData: string, password: string): Uint8Array | null {
	try {
		const parsed = JSON.parse(encryptedData);
		const salt = Buffer.from(parsed.salt, "base64");
		const iv = Buffer.from(parsed.iv, "base64");
		const tag = Buffer.from(parsed.tag, "base64");
		const ct = Buffer.from(parsed.ct, "base64");

		const key = pbkdf2Sync(Buffer.from(password, "utf8"), salt, parsed.iter ?? 100_000, 32, "sha256");

		const decipher = createDecipheriv("aes-256-gcm", key, iv);
		decipher.setAuthTag(tag);

		const plaintext = Buffer.concat([decipher.update(ct), decipher.final()]);
		return new Uint8Array(plaintext);
	} catch (err) {
		console.error("Decryption failed:", err);
		return null;
	}
}
