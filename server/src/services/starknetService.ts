import { injectable, inject } from "tsyringe";
import { Account, ec, RpcProvider, hash, CallData, Contract } from "starknet";
import config from "../config/config";
import { EncryptionService, KeystoreRecord } from "./encryptionService";

@injectable()
export class StarknetService {
	private static isInitialized = false;
	private static rpcProvider: RpcProvider;
	private readonly OZ_ACCOUNT_CLASS_HASH: string = "";
	private readonly FAUCET_ADDRESS: string = "";
	private readonly FAUCET_PK: string = "";
	private readonly DRIP_AMOUNT: number = 0;
	private readonly STRK_TOKEN: string = "";

	constructor(@inject(EncryptionService) private encryptionService: EncryptionService) {
		this.OZ_ACCOUNT_CLASS_HASH = config.starknet.accountClassHash;

		if (!StarknetService.isInitialized) {
			this.connectProvider();
			StarknetService.isInitialized = true;
		}
	}

	private get rpc() {
		return StarknetService.rpcProvider;
	}

	private connectProvider() {
		StarknetService.rpcProvider = new RpcProvider({
			nodeUrl: config.starknet.nodeUrl,
			retries: 3,
		});
	}

	private async fundWallet(recipient: string): Promise<{ success: boolean; message?: string; error?: any }> {
		try {
			const faucetAccount = new Account(this.rpc, this.FAUCET_ADDRESS, this.FAUCET_PK);

			const { abi: tokenABI } = await this.rpc.getClassAt(this.STRK_TOKEN);

			if (!tokenABI) {
				throw new Error(`No ABI found for ${this.STRK_TOKEN}`);
			}

			const tokenContract = new Contract(tokenABI, this.STRK_TOKEN, this.rpc);
			tokenContract.connect(faucetAccount);

			// Prepare and send transfer
			const dripCall = tokenContract.populate("transfer", [recipient, this.DRIP_AMOUNT]);
			const res = await tokenContract.transfer(dripCall.calldata);

			await this.rpc.waitForTransaction(res.transaction_hash);

			return {
				success: true,
				message: `Funded ${recipient} with ${this.DRIP_AMOUNT} strk tokens`,
			};
		} catch (error: any) {
			console.error(`Failed to fund wallet ${recipient}:`, error);
			return {
				success: false,
				error: error?.message || error,
			};
		}
	}

	// ---------- Public flows ----------
	/**
	 * Generate Starknet account + keystore (envelope encryption) + recovery key.
	 * Store `keystoreJson` in DB; show `recoveryKeyHex` once to the user.
	 */
	async generateStarknetAddress(userPassword: string) {
		const privateKey = ec.starkCurve.utils.randomPrivateKey();
		const publicKey = ec.starkCurve.getStarkKey(privateKey);

		const calldata = CallData.compile({ publicKey });
		const contractAddress = hash.calculateContractAddressFromHash(publicKey, this.OZ_ACCOUNT_CLASS_HASH, calldata, 0);

		const { record, recoveryKeyHex } = this.encryptionService.createKeystore(privateKey, userPassword);

		return {
			success: true,
			userAddress: contractAddress,
			userPubKey: publicKey.toString(),
			keystoreJson: JSON.stringify(record),
			recoveryKeyHex,
		};
	}

	async deployStarknetAccount(userAddress: string, userPubKey: string, keystoreJson: string, userPassword: string) {
		try {
			const record = JSON.parse(keystoreJson) as KeystoreRecord;
			const privateKeyBytes = this.encryptionService.unlockWithPassword(record, userPassword);

			const fundResponse = await this.fundWallet(userAddress);

			if (!fundResponse.success) {
				throw new Error(fundResponse.error);
			}

			const account = new Account(this.rpc, userAddress, privateKeyBytes);

			const constructorCalldata = CallData.compile({ publicKey: userPubKey });
			const { transaction_hash, contract_address } = await account.deployAccount({
				classHash: this.OZ_ACCOUNT_CLASS_HASH,
				constructorCalldata,
				addressSalt: userPubKey,
			});

			await this.rpc.waitForTransaction(transaction_hash);

			return {
				success: true,
				userAddress: contract_address,
				transactionHash: transaction_hash,
			};
		} catch (err: any) {
			console.error("Account deployment failed:", err);
			return { success: false, error: err?.message || "Unknown deployment error." };
		}
	}
}
