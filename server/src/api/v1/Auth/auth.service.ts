import { injectable, inject } from "tsyringe";
import jwt from "jsonwebtoken";
import AuthRepository from "./auth.repository";
import { ApplicationError } from "../../../utils/errorHandler";
import HttpStatusCodes from "../../../constants/HttpStatusCodes";
import UserRepository from "../User/user.repository";
import User from "../User/user.entity";

@injectable()
export default class AuthService {
	private readonly JWT_SECRET = process.env.JWT_SECRET || "your-secret-key";
	private readonly REFRESH_TOKEN_SECRET = process.env.REFRESH_TOKEN_SECRET || "your-refresh-secret-key";

	constructor(
		@inject(AuthRepository)
		private authRepository: AuthRepository,
		@inject(UserRepository)
		private userRepository: UserRepository
	) {}

	async register(email: string, password: string, firstName: string, lastName: string) {
		const existingUser = await this.userRepository.findByEmail(email);
		if (existingUser) {
			throw new ApplicationError("Email already registered", HttpStatusCodes.CONFLICT);
		}

		const user = await this.userRepository.createUser({
			email,
			firstName,
			lastName
		});

		await this.authRepository.createAuth(user.id, password);

		const tokens = await this.generateTokens(user.id);
		return { user, ...tokens };
	}

	async login(email: string, password: string) {
		const user = await this.userRepository.findByEmail(email);
		if (!user) {
			throw new ApplicationError("Invalid credentials", HttpStatusCodes.UNAUTHORIZED);
		}

		const auth = await this.authRepository.findByUserId(user.id);
		if (!auth || !await auth.verifyPassword(password)) {
			throw new ApplicationError("Invalid credentials", HttpStatusCodes.UNAUTHORIZED);
		}

		const tokens = await this.generateTokens(user.id);
		return { user, ...tokens };
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

	private async generateTokens(userId: string) {
		const accessToken = jwt.sign({ id: userId }, this.JWT_SECRET, { expiresIn: "15m" });
		const refreshToken = jwt.sign({ id: userId }, this.REFRESH_TOKEN_SECRET, { expiresIn: "7d" });
		
		const expiresIn = new Date();
		expiresIn.setDate(expiresIn.getDate() + 7); // 7 days
		await this.authRepository.updateRefreshToken(userId, refreshToken, expiresIn);
		
		return { accessToken, refreshToken };
	}
}
