import { injectable, inject } from "tsyringe";
import jwt from "jsonwebtoken";
import AuthRepository from "./auth.repository";
import { ApplicationError } from "../../../utils/errorHandler";
import HttpStatusCodes from "../../../constants/HttpStatusCodes";
import QueueService from "../../../services/queueService";
import config from "../../../config/config";
import UserService from "../User/user.service";
import WalletService from "../Wallet/wallet.service";
import AppDataSource from "../../../config/DataSource";
import { DataSource, QueryRunner } from "typeorm";

@injectable()
export default class AuthService {
	private readonly JWT_SECRET = process.env.JWT_SECRET || "your-secret-key";
	private readonly REFRESH_TOKEN_SECRET = process.env.REFRESH_TOKEN_SECRET || "your-refresh-secret-key";
	private readonly dataSource: DataSource;
	constructor(
		@inject(AuthRepository)
		private authRepository: AuthRepository,
		@inject(UserService)
		private userService: UserService,
		@inject(WalletService)
		private walletService: WalletService,
		@inject(QueueService)
		private queueService: QueueService
	) {
		this.dataSource = AppDataSource;
	}

	async register(email: string, password: string, firstName: string, lastName: string, walletPassword: string) {
		const existingUser = await this.userService.getUserByEmail(email);

		if (existingUser) {
			throw new ApplicationError("Email already registered", HttpStatusCodes.CONFLICT);
		}

		const queryRunner = this.dataSource.createQueryRunner();
		await queryRunner.connect();
		await queryRunner.startTransaction();

		try {
			const user = await this.userService.createUser(
				{
					email,
					firstName,
					lastName,
				},
				queryRunner
			);

			const wallet = await this.walletService.createWallet(user.id, walletPassword, queryRunner);

			await this.authRepository.createAuth(user.id, password, queryRunner);

			const tokens = await this.generateTokens(user.id, queryRunner);

			await queryRunner.commitTransaction();

			return { ...wallet, user, ...tokens };
		} catch (err) {
			await queryRunner.rollbackTransaction();
			throw err;
		} finally {
			await queryRunner.release();
		}
	}

	async login(email: string, password: string) {
		const user = await this.userService.getUserByEmail(email);
		if (!user) {
			throw new ApplicationError("Invalid credentials", HttpStatusCodes.UNAUTHORIZED);
		}

		const auth = await this.authRepository.findByUserId(user.id);
		if (!auth || !(await auth.verifyPassword(password))) {
			throw new ApplicationError("Invalid credentials", HttpStatusCodes.UNAUTHORIZED);
		}

		const wallet = await this.walletService.getWalletByUserId(user.id);

		if (!wallet.deployed) {
			await this.walletService.deployWallet(user.id, password);
		}

		const tokens = await this.generateTokens(user.id);

		return { ...wallet, user, ...tokens };
	}

	async refreshToken(refreshToken: string) {
		try {
			const decoded = jwt.verify(refreshToken, this.REFRESH_TOKEN_SECRET) as { id: string };
			const auth = await this.authRepository.findByUserId(decoded.id);

			if (!auth || auth.refreshToken !== refreshToken) {
				throw new ApplicationError("Invalid refresh token", HttpStatusCodes.UNAUTHORIZED);
			}

			const tokens = await this.generateTokens(decoded.id);
			return tokens;
		} catch (error) {
			throw new ApplicationError("Invalid refresh token", HttpStatusCodes.UNAUTHORIZED);
		}
	}

	async logout(userId: string) {
		await this.authRepository.removeRefreshToken(userId);
	}

	async validateToken(token: string): Promise<{ id: string }> {
		try {
			const decoded = jwt.verify(token, this.JWT_SECRET) as { id: string };
			const auth = await this.authRepository.findByUserId(decoded.id);

			if (!auth) {
				throw new ApplicationError("Invalid token", HttpStatusCodes.UNAUTHORIZED);
			}

			return { id: decoded.id };
		} catch (error) {
			throw new ApplicationError("Invalid token", HttpStatusCodes.UNAUTHORIZED);
		}
	}

	private async generateTokens(userId: string, queryRunner?: QueryRunner) {
		const accessToken = jwt.sign({ id: userId }, this.JWT_SECRET, { expiresIn: "15m" });
		const refreshToken = jwt.sign({ id: userId }, this.REFRESH_TOKEN_SECRET, { expiresIn: "7d" });

		const expiresIn = new Date();
		expiresIn.setDate(expiresIn.getDate() + 7); // 7 days
		await this.authRepository.updateRefreshToken(userId, refreshToken, expiresIn, queryRunner);
		return { accessToken, refreshToken };
	}

	async changePassword(userId: string, currentPassword: string, newPassword: string) {
		const auth = await this.authRepository.findByUserId(userId);

		if (!auth || !(await auth.verifyPassword(currentPassword))) {
			throw new ApplicationError("Password is incorrect", HttpStatusCodes.UNAUTHORIZED);
		}

		auth.password = newPassword;
		await auth.hashPassword();
		await this.authRepository.save(auth);
	}

	async sendPasswordResetMail(email: string) {
		const user = await this.userService.getUserByEmail(email);
		if (!user) return; // Don't reveal if email exists

		const resetToken = jwt.sign({ id: user.id }, this.JWT_SECRET, { expiresIn: "1h" });
		const resetUrl = `${config.email.url}/reset-password?token=${resetToken}`;

		// Add job to queue instead of sending email directly
		await this.queueService.addEmailJob({
			type: "PASSWORD_RESET",
			data: {
				email: user.email,
				name: `${user.firstName} ${user.lastName}`,
				resetToken,
				resetUrl,
			},
		});
	}

	async resetPassword(token: string, newPassword: string) {
		const queryRunner = this.dataSource.createQueryRunner();
		await queryRunner.connect();
		await queryRunner.startTransaction();
		try {
			const decoded = jwt.verify(token, this.JWT_SECRET) as { id: string };
			await this.authRepository.updatePassword(decoded.id, newPassword, queryRunner);
		} catch {
			throw new ApplicationError("Invalid or expired token", HttpStatusCodes.UNAUTHORIZED);
		} finally {
			await queryRunner.release();
		}
	}

	async googleSignIn(idToken: string) {
		const email = "extracted_from_idToken@example.com";
		let user = await this.userService.getUserByEmail(email);
		if (!user) {
			user = await this.userService.createUser({ email, firstName: "Google", lastName: "User" });
			await this.authRepository.createAuth(user.id, crypto.randomUUID());
		}
		const tokens = await this.generateTokens(user.id);
		return { user, ...tokens };
	}
}
