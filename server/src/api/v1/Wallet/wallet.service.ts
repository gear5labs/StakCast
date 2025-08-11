import { inject, injectable } from "tsyringe";
import WalletRepository from "./wallet.repository";
import Wallet from "./wallet.entity";
import { StarknetService } from "../../../services/starknetService";
import { DeployResult } from "../../../types/wallet.types";
import { QueryRunner } from "typeorm";
import { EncryptionService } from "../../../services/encryptionService";

@injectable()
export default class WalletService {
	constructor(
		@inject(EncryptionService)
		private encryptionService: EncryptionService,
		@inject(StarknetService)
		private starknetService: StarknetService,
		@inject(WalletRepository)
		private walletRepository: WalletRepository
	) {}

	async createWallet(userId: string, password: string, queryRunner?: QueryRunner) {
		const wallet = await this.walletRepository.findByUserId(userId);

		if (wallet) {
			throw new Error("User already has wallet");
		}

		const walletData = await this.starknetService.generateStarknetAddress(password);
		const res = await this.walletRepository.createWallet(
			{
				userId: userId,
				publicKey: walletData.userPubKey,
				keystoreJson: walletData.keystoreJson,
				address: walletData.userAddress,
			},
			queryRunner
		);

		return {
			walletId: res.id,
			recoveryKeyHex: walletData.recoveryKeyHex,
			walletAddress: res.address,
		};
	}

	async deployWallet(userId: string, password: string, queryRunner?: QueryRunner): Promise<DeployResult> {
		const wallet = await this.getWalletByUserId(userId, queryRunner);

		if (!wallet) {
			throw new Error("Wallet not found");
		}

		if (wallet.deployed) {
			throw new Error("Wallet already deplyed");
		}

		const result = await this.starknetService.deployStarknetAccount(
			wallet.address,
			wallet.publicKey,
			wallet.keystoreJson,
			password
		);

		if (result.success) {
			this.walletRepository.updateWallet(
				wallet.id,
				{
					deployed: true,
				},
				queryRunner
			);
		}

		return result;
	}

	async updateKeyStorePassword(userId: string, oldPassword: string, newPassword: string, queryRunner?: QueryRunner) {
		const wallet = await this.getWalletByUserId(userId, queryRunner);

		if (!wallet) {
			throw new Error("Wallet not found");
		}

		const updatedKeystoreJson = this.encryptionService.changeKeystorePassword(
			wallet.keystoreJson,
			oldPassword,
			newPassword
		);

		wallet.keystoreJson = updatedKeystoreJson;

		await this.walletRepository.updateWallet(wallet.id, wallet, queryRunner);
	}

	async recoverKeyStore(userId: string, recoveryKeyHex: string, newPassword: string, queryRunner?: QueryRunner) {
		const wallet = await this.getWalletByUserId(userId, queryRunner);

		if (!wallet) {
			throw new Error("Wallet not found");
		}

		const { updatedKeystoreJson, newRecoveryKeyHex } = this.encryptionService.recoverAndRotate(
			wallet.keystoreJson,
			recoveryKeyHex,
			newPassword
		);

		wallet.keystoreJson = updatedKeystoreJson;

		await this.walletRepository.updateWallet(wallet.id, wallet, queryRunner);

		return {
			newRecoveryKeyHex,
			wallet,
		};
	}

	async getWalletByUserId(userId: string, queryRunner?: QueryRunner): Promise<Wallet> {
		const wallet = await this.walletRepository.findByUserId(userId, queryRunner);
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
