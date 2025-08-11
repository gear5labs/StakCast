import { injectable } from "tsyringe";
import { Account, ec, RpcProvider, hash, CallData, Contract } from "starknet";
import config from "../config/config";
import { decryptPrivateKey, encryptPrivateKey } from "../utils/starknetUtils";

@injectable()
export default class StarknetService {
	private readonly rpcProvider: RpcProvider;
	private readonly OZ_ACCOUNT_CLASS_HASH: string = "";
	private readonly FAUCET_ADDRESS: string = "";
	private readonly FAUCET_PK: string = "";
	private readonly DRIP_AMOUNT: number = 0;
	private readonly STRK_TOKEN: string = "";

	constructor() {
		this.OZ_ACCOUNT_CLASS_HASH = config.starknet.accountClassHash;

		this.rpcProvider = new RpcProvider({
			nodeUrl: config.starknet.nodeUrl,
			retries: 3,
		});

		this.FAUCET_ADDRESS = config.starknet.faucetAddress;
		this.FAUCET_PK = config.starknet.faucetPK;
		this.DRIP_AMOUNT = Number(config.starknet.dripAmount);
		this.STRK_TOKEN = config.starknet.strkToken;
	}

	private async fundWallet(recipient: string): Promise<{ success: boolean; message?: string; error?: any }> {
		try {
			const faucetAccount = new Account(this.rpcProvider, this.FAUCET_ADDRESS, this.FAUCET_PK);

			const { abi: tokenABI } = await this.rpcProvider.getClassAt(this.STRK_TOKEN);

			if (!tokenABI) {
				throw new Error(`No ABI found for ${this.STRK_TOKEN}`);
			}

			const tokenContract = new Contract(tokenABI, this.STRK_TOKEN, this.rpcProvider);
			tokenContract.connect(faucetAccount);

			// Prepare and send transfer
			const dripCall = tokenContract.populate("transfer", [recipient, this.DRIP_AMOUNT]);
			const res = await tokenContract.transfer(dripCall.calldata);

			await this.rpcProvider.waitForTransaction(res.transaction_hash);

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

	async generateStarknetAddress(userPassword: string) {
		const privateKey = ec.starkCurve.utils.randomPrivateKey();
		const publicKey = ec.starkCurve.getStarkKey(privateKey);

		const calldata = CallData.compile({ publicKey });
		const contractAddress = hash.calculateContractAddressFromHash(publicKey, this.OZ_ACCOUNT_CLASS_HASH, calldata, 0);

		const encryptedPrivateKey = encryptPrivateKey(privateKey, userPassword);

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
		const decrypted = decryptPrivateKey(encryptedPrivateKey, userPassword);

		if (!decrypted) {
			return {
				success: false,
				error: "Invalid password or corrupted encrypted private key.",
			};
		}

		const fundResponse = await this.fundWallet(userAddress);
		if (!fundResponse.success) {
			throw new Error(fundResponse.error);
		}

		const account = new Account(this.rpcProvider, userAddress, decrypted);

		try {
			const constructorCalldata = CallData.compile({ publicKey: userPubKey });

			const { transaction_hash, contract_address } = await account.deployAccount({
				classHash: this.OZ_ACCOUNT_CLASS_HASH,
				constructorCalldata,
				addressSalt: userPubKey,
			});

			await this.rpcProvider.waitForTransaction(transaction_hash);

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
