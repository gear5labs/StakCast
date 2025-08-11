import { injectable } from "tsyringe";
import { Repository, QueryRunner } from "typeorm";
import AppDataSource from "../../../config/DataSource";
import Wallet from "./wallet.entity";

@injectable()
export default class WalletRepository {
	private walletRepository: Repository<Wallet>;

	constructor() {
		this.walletRepository = AppDataSource.getRepository(Wallet);
	}

	async createWallet(walletData: Partial<Wallet>, queryRunner?: QueryRunner): Promise<Wallet> {
		const repository = queryRunner ? queryRunner.manager.getRepository(Wallet) : this.walletRepository;
		const walletInfo = repository.create(walletData);
		return repository.save(walletInfo);
	}

	async findByUserId(userId: string, queryRunner?: QueryRunner): Promise<Wallet | null> {
		const repository = queryRunner ? queryRunner.manager.getRepository(Wallet) : this.walletRepository;
		return repository.findOne({ where: { userId: userId } });
	}

	async findById(id: string, queryRunner?: QueryRunner): Promise<Wallet | null> {
		const repository = queryRunner ? queryRunner.manager.getRepository(Wallet) : this.walletRepository;
		return repository.findOne({ where: { id: id } });
	}

	async updateWallet(walletId: string, walletData: Partial<Wallet>, queryRunner?: QueryRunner): Promise<Wallet | null> {
		const repository = queryRunner ? queryRunner.manager.getRepository(Wallet) : this.walletRepository;
		await repository.update(walletId, walletData);
		return this.findById(walletId, queryRunner);
	}
}
