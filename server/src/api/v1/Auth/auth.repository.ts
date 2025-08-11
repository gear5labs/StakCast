import { injectable } from "tsyringe";
import { QueryRunner, Repository } from "typeorm";
import AppDataSource from "../../../config/DataSource";
import Auth from "./auth.entity";

@injectable()
export default class AuthRepository {
	private authRepository: Repository<Auth>;

	constructor() {
		this.authRepository = AppDataSource.getRepository(Auth);
	}

	async createAuth(userId: string, password: string, queryRunner?: QueryRunner): Promise<Auth> {
		const repository = queryRunner ? queryRunner.manager.getRepository(Auth) : this.authRepository;
		const auth = repository.create({ userId, password });
		await auth.hashPassword();
		return repository.save(auth);
	}

	async findByUserId(userId: string, queryRunner?: QueryRunner): Promise<Auth | null> {
		const repository = queryRunner ? queryRunner.manager.getRepository(Auth) : this.authRepository;
		return repository.findOne({ where: { userId } });
	}

	async updateRefreshToken(
		userId: string,
		refreshToken: string,
		expiresIn: Date,
		queryRunner?: QueryRunner
	): Promise<Auth | null> {
		const repository = queryRunner ? queryRunner.manager.getRepository(Auth) : this.authRepository;
		const auth = await repository.findOne({ where: { userId } });
		if (auth) {
			auth.refreshToken = refreshToken;
			auth.refreshTokenExpires = expiresIn;
			return repository.save(auth);
		}
		return null;
	}

	async updatePassword(userId: string, newPassword: string, queryRunner?: QueryRunner): Promise<Auth> {
		const repository = queryRunner ? queryRunner.manager.getRepository(Auth) : this.authRepository;

		const auth = await this.findByUserId(userId, queryRunner);

		if (!auth) {
			throw new Error("User not found");
		}

		auth.password = newPassword;
		await auth.hashPassword();
		return repository.save(auth);
	}

	async removeRefreshToken(userId: string): Promise<void> {
		await this.authRepository.update({ userId }, { refreshToken: undefined, refreshTokenExpires: undefined });
	}
}
