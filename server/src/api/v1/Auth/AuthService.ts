import { autoInjectable } from "tsyringe";
import bcrypt from "bcrypt";
import { ApplicationError } from "../../../utils/errorHandler";
import HttpStatusCodes from "../../../constants/HttpStatusCodes";
import { DeviceInfo } from "../../../types/auth.types";
import JwtHelper from "../../../utils/JWTHelper";
import AuthRepository from "./AuthRepository";
import  UserRepository  from "../User/User.repository";

@autoInjectable()
export default class AuthService {
	constructor(
		private userRepository: UserRepository,
		private jwtHelper: JwtHelper,
		private authRepository: AuthRepository
	) {}

	public async loginUser(identifier: string, password: string, deviceInfo: DeviceInfo) {
		const user = await this.authRepository.findUserByDetails(identifier);
		if (!user) {
			throw new ApplicationError("User not found", HttpStatusCodes.NOT_FOUND);
		}

		const isPasswordValid = await bcrypt.compare(password, user.password);
		if (!isPasswordValid) {
			throw new ApplicationError("Invalid password", HttpStatusCodes.UNAUTHORIZED);
		}

		const accessToken = this.jwtHelper.generateAccessToken(user._id as string);
		const refreshToken = this.jwtHelper.generateRefreshToken(user._id as string);

		await this.authRepository.storeToken({
			userId: user._id as string,
			token: refreshToken,
			deviceInfo,
			lastUsed: new Date(),
			useCount: 0,
			maxUses: 50,
		});

		return { accessToken, refreshToken, user };
	}

	public async registerUser(email: string, password: string, deviceInfo: DeviceInfo) {
		const existingUser = await this.authRepository.findUserByDetails(email);
		if (existingUser) {
			throw new ApplicationError("User already exists", HttpStatusCodes.CONFLICT);
		}

		const hashedPassword = await bcrypt.hash(password, 10);
		const user = await this.userRepository.createUser({ email, password: hashedPassword });

		const accessToken = this.jwtHelper.generateAccessToken(user._id as string);
		const refreshToken = this.jwtHelper.generateRefreshToken(user._id as string);

		await this.authRepository.storeToken({
			userId: user._id as string,
			token: refreshToken,
			deviceInfo,
			lastUsed: new Date(),
			useCount: 0,
			maxUses: 50,
		});

		return { accessToken, refreshToken, user };
	}

	public async validateTokenDevice(refreshToken: string, fingerprint: string) {
		const tokenRecord = await this.authRepository.findTokenByRefreshToken(refreshToken);

		if (!tokenRecord) {
			throw new ApplicationError("Invalid refresh token", HttpStatusCodes.UNAUTHORIZED);
		}

		if (tokenRecord.deviceInfo.fingerprint !== fingerprint) {
			throw new ApplicationError("Invalid device", HttpStatusCodes.UNAUTHORIZED);
		}

		if (tokenRecord.useCount >= tokenRecord.maxUses) {
			await this.authRepository.removeToken(`${tokenRecord.userId}`, refreshToken);
			throw new ApplicationError("Token use limit exceeded", HttpStatusCodes.UNAUTHORIZED);
		}

		const updatedToken = await this.authRepository.updateTokenUsage(refreshToken);
		return updatedToken;
	}

	public async verifyAccessToken(token: string) {
		return this.jwtHelper.verifyAccessToken(token);
	}

	// ... other existing methods ...
}
