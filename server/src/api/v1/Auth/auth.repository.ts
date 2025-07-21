import { injectable } from "tsyringe";
import { Repository } from "typeorm";
import AppDataSource from "../../../config/DataSource";
import Auth from "./auth.entity";

@injectable()
export default class AuthRepository {
	private authRepository: Repository<Auth>;

	constructor() {
		this.authRepository = AppDataSource.getRepository(Auth);
	}

	async createAuth(userId: string, password: string): Promise<Auth> {
		const auth = this.authRepository.create({ userId, password });
		await auth.hashPassword();
		return this.authRepository.save(auth);
	}

	async findByUserId(userId: string): Promise<Auth | null> {
		return this.authRepository.findOne({ where: { userId } });
	}

	async updateRefreshToken(userId: string, refreshToken: string, expiresIn: Date): Promise<Auth | null> {
		const auth = await this.findByUserId(userId);
		if (auth) {
			auth.refreshToken = refreshToken;
			auth.refreshTokenExpires = expiresIn;
			return this.authRepository.save(auth);
		}
		return null;
	}

	async removeRefreshToken(userId: string): Promise<void> {
		await this.authRepository.update(
			{ userId },
			{ refreshToken: undefined, refreshTokenExpires: undefined }
		);
	}

	async save(auth: Auth): Promise<Auth> {
		return this.authRepository.save(auth);
	}
}
