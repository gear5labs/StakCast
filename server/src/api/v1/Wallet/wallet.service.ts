import { inject, injectable } from "tsyringe";
import WalletRepository from "./wallet.repository";
import Wallet from "./wallet.entity";
import StarknetService from "../../../services/starknetService";
import { DeployResult } from "../../../types/wallet.types";

@injectable()
export default class WalletService {
	constructor(
		@inject(StarknetService)
		private starknetService: StarknetService,
		@inject(WalletRepository)
		private walletRepository: WalletRepository
	) {}

	async createWallet(userId: string, password: string): Promise<Wallet> {
		const wallet = await this.walletRepository.findByUserId(userId);

		if (wallet) {
			throw new Error("User already has wallet");
		}

		const walletData = await this.starknetService.generateStarknetAddress(password);

		return this.walletRepository.createWallet({
			userId: userId,
			publicKey: walletData.userPubKey,
			encryptedPrivateKey: walletData.userPrivateKey,
			address: walletData.userAddress,
		});
	}

	async deployWallet(userId: string, password: string): Promise<DeployResult> {
		const wallet = await this.getWalletByUserId(userId);

		if (wallet.deployed) {
			throw new Error("Wallet already deplyed");
		}

		const result = await this.starknetService.deployStarknetAccount(
			wallet.address,
			wallet.publicKey,
			wallet.encryptedPrivateKey,
			password
		);

		if (result.success) {
			this.walletRepository.updateWallet(wallet.id, {
				deployed: true,
			});
		}

		return result;
	}

	async getWalletByUserId(userId: string): Promise<Wallet> {
		const wallet = await this.walletRepository.findByUserId(userId);
		if (!wallet) {
			throw new Error("User does not have any wallet");
		}
		return wallet;
	}

	async getWalletById(id: string): Promise<Wallet> {
		const wallet = await this.walletRepository.findById(id);
		if (!wallet) {
			throw new Error("Wallet not found");
		}
		return wallet;
	}
}
