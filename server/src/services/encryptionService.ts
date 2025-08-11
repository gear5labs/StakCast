import { injectable } from "tsyringe";
import { randomBytes, createCipheriv, createDecipheriv, pbkdf2Sync } from "crypto";

export type GcmBlob = { ct: string; iv: string; tag: string }; // base64 fields
export type KeystoreRecord = {
	version: 1;
	data: GcmBlob; // AES-GCM(DEK, privateKey private key)
	wraps: {
		password: GcmBlob & { kdf: { algo: "pbkdf2-sha256"; iter: number; salt: string } };
		recovery: GcmBlob & { kdf: { algo: "none" } }; // raw 32B recovery key, no KDF
	};
};

@injectable()
export class EncryptionService {
	private aesGcmEnc(key: Buffer, privateKey: Buffer): GcmBlob {
		const iv = randomBytes(12);
		const c = createCipheriv("aes-256-gcm", key, iv);
		const ct = Buffer.concat([c.update(privateKey), c.final()]);
		const tag = c.getAuthTag();
		return { ct: ct.toString("base64"), iv: iv.toString("base64"), tag: tag.toString("base64") };
	}

	private aesGcmDec(key: Buffer, blob: GcmBlob): Buffer {
		const iv = Buffer.from(blob.iv, "base64");
		const tag = Buffer.from(blob.tag, "base64");
		const ct = Buffer.from(blob.ct, "base64");
		const d = createDecipheriv("aes-256-gcm", key, iv);
		d.setAuthTag(tag);
		return Buffer.concat([d.update(ct), d.final()]);
	}

	// Prefer Argon2id if you can add it; PBKDF2 fallback here
	private deriveKEK(password: string, saltB64: string, iter = 150_000): Buffer {
		const salt = Buffer.from(saltB64, "base64");
		return pbkdf2Sync(Buffer.from(password, "utf8"), salt, iter, 32, "sha256");
	}

	// ---------- public API ----------
	/**
	 * Create keystore with envelope encryption and one-time recovery key.
	 * Returns keystore record + recovery key (hex) to show once.
	 */
	createKeystore(privateKey: Uint8Array, password: string): { record: KeystoreRecord; recoveryKeyHex: string } {
		const DEK = randomBytes(32);

		const data = this.aesGcmEnc(DEK, Buffer.from(privateKey));

		const salt = randomBytes(16).toString("base64");
		const iter = 150_000;
		const KEKpwd = this.deriveKEK(password, salt, iter);
		const wrappedPwd = this.aesGcmEnc(KEKpwd, DEK);

		const recoveryKey = randomBytes(32);
		const wrappedRecovery = this.aesGcmEnc(recoveryKey, DEK);

		const record: KeystoreRecord = {
			version: 1,
			data,
			wraps: {
				password: { ...wrappedPwd, kdf: { algo: "pbkdf2-sha256", iter, salt } },
				recovery: { ...wrappedRecovery, kdf: { algo: "none" } },
			},
		};

		return { record, recoveryKeyHex: recoveryKey.toString("hex") };
	}

	/** Unlock keystore with password → private key bytes */
	unlockWithPassword(record: KeystoreRecord, password: string): Uint8Array {
		try {
			const { iter, salt } = record.wraps.password.kdf;
			const KEKpwd = this.deriveKEK(password, salt, iter);
			const DEK = this.aesGcmDec(KEKpwd, record.wraps.password);
			const privateKey = this.aesGcmDec(DEK, record.data);
			return new Uint8Array(privateKey);
		} catch {
			throw new Error("Invalid password or corrupted keystore.");
		}
	}

	/** Change password (rewrap DEK under new password). Returns updated keystore JSON string. */
	changeKeystorePassword(keystoreJson: string, oldPassword: string, newPassword: string): string {
		const record = JSON.parse(keystoreJson) as KeystoreRecord;

		const { iter, salt } = record.wraps.password.kdf;
		const oldKEK = this.deriveKEK(oldPassword, salt, iter);
		const DEK = this.aesGcmDec(oldKEK, record.wraps.password);

		const newSalt = randomBytes(16).toString("base64");
		const newIter = 150_000;
		const newKEK = this.deriveKEK(newPassword, newSalt, newIter);
		record.wraps.password = {
			...this.aesGcmEnc(newKEK, DEK),
			kdf: { algo: "pbkdf2-sha256", iter: newIter, salt: newSalt },
		};

		return JSON.stringify(record);
	}

	/**
	 * Recover with recovery key (hex), set a new password, and rotate recovery key.
	 * Returns updated keystore JSON and a NEW recovery key (hex).
	 */
	recoverAndRotate(
		keystoreJson: string,
		recoveryKeyHex: string,
		newPassword: string
	): {
		updatedKeystoreJson: string;
		newRecoveryKeyHex: string;
	} {
		const record = JSON.parse(keystoreJson) as KeystoreRecord;

		const recoveryKey = Buffer.from(recoveryKeyHex, "hex");
		const DEK = this.aesGcmDec(recoveryKey, record.wraps.recovery);

		const newSalt = randomBytes(16).toString("base64");
		const newIter = 150_000;
		const newKEK = this.deriveKEK(newPassword, newSalt, newIter);
		record.wraps.password = {
			...this.aesGcmEnc(newKEK, DEK),
			kdf: { algo: "pbkdf2-sha256", iter: newIter, salt: newSalt },
		};

		const newRecoveryKey = randomBytes(32);
		record.wraps.recovery = { ...this.aesGcmEnc(newRecoveryKey, DEK), kdf: { algo: "none" } };

		return {
			updatedKeystoreJson: JSON.stringify(record),
			newRecoveryKeyHex: newRecoveryKey.toString("hex"),
		};
	}
}
