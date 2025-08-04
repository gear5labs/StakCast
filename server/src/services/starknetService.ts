import { injectable } from "tsyringe";
import CryptoJS from "crypto-js";
import { Account, ec, RpcProvider, hash, CallData } from "starknet";
import config from "../config/config";
import { uint8ArrayToWordArray, wordArrayToUint8Array } from "../utils/starknetUtils";
@injectable()
export default class StarknetService {
	private static isInitialized = false;
	private static rpcProvider: RpcProvider;

	private readonly OZ_ACCOUNT_CLASS_HASH: string = "";

	constructor() {
		this.OZ_ACCOUNT_CLASS_HASH = config.starknet.accountClassHash;

		if (!StarknetService.isInitialized) {
			this.connectProvider();
			StarknetService.isInitialized = true;
		}
	}

	private connectProvider() {
		StarknetService.rpcProvider = new RpcProvider({
			nodeUrl: config.starknet.nodeUrl,
			retries: 3,
		});
	}

	private encryptPrivateKey(privateKey: Uint8Array, password: string): string {
		const salt = CryptoJS.lib.WordArray.random(16);
		const key = CryptoJS.PBKDF2(password, salt, {
			keySize: 256 / 32,
			iterations: 100_000,
		});
		const data = uint8ArrayToWordArray(privateKey);
		const ciphertext = CryptoJS.AES.encrypt(data, key, { iv: salt });

		return JSON.stringify({
			ciphertext: ciphertext.toString(),
			salt: salt.toString(),
		});
	}

	private decryptPrivateKey(encryptedData: string, password: string): Uint8Array | null {
		try {
			const { ciphertext, salt } = JSON.parse(encryptedData);
			const saltWordArray = CryptoJS.enc.Hex.parse(salt);
			const key = CryptoJS.PBKDF2(password, saltWordArray, {
				keySize: 256 / 32,
				iterations: 100_000,
			});
			const decrypted = CryptoJS.AES.decrypt(ciphertext, key, { iv: saltWordArray });
			return wordArrayToUint8Array(decrypted);
		} catch (err) {
			console.error("Decryption failed:", err);
			return null;
		}
	}

	async generateStarknetAddress(userPassword: string) {
		const privateKey = ec.starkCurve.utils.randomPrivateKey();
		const publicKey = ec.starkCurve.getStarkKey(privateKey);

		const calldata = CallData.compile({ publicKey });
		const contractAddress = hash.calculateContractAddressFromHash(publicKey, this.OZ_ACCOUNT_CLASS_HASH, calldata, 0);

		const encryptedPrivateKey = this.encryptPrivateKey(privateKey, userPassword);

		return {
			success: true,
			userAddress: contractAddress,
			userPubKey: publicKey.toString(),
			userPrivateKey: encryptedPrivateKey,
		};
	}

	async deployStarknetAccount(
		userAddress: string,
		userPubKey: string,
		encryptedPrivateKey: string,
		userPassword: string
	) {
		const decrypted = this.decryptPrivateKey(encryptedPrivateKey, userPassword);

		if (!decrypted) {
			return {
				success: false,
				error: "Invalid password or corrupted encrypted private key.",
			};
		}

		const account = new Account(StarknetService.rpcProvider, userAddress, decrypted);

		try {
			const constructorCalldata = CallData.compile({ publicKey: userPubKey });

			const { transaction_hash, contract_address } = await account.deployAccount({
				classHash: this.OZ_ACCOUNT_CLASS_HASH,
				constructorCalldata,
				addressSalt: userPubKey,
			});

			await StarknetService.rpcProvider.waitForTransaction(transaction_hash);

			return {
				success: true,
				userAddress: contract_address,
				transactionHash: transaction_hash,
			};
		} catch (err: any) {
			console.error("Account deployment failed:", err);
			return {
				success: false,
				error: err?.message || "Unknown deployment error.",
			};
		}
	}
}
