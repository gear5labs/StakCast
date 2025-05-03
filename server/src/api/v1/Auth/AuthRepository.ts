import { injectable } from "tsyringe";
import AuthModel, { IAuthModel } from "./AuthToken.model";
import UserModel from "../User/User.model";
import { DeviceInfo } from "../../../types/auth.types";
import  UserRepository  from "../User/User.repository";

@injectable()
export default class AuthRepository {
	constructor(private userRepository: UserRepository) {}

	public async findUserByDetails(identifier: string) {
		return this.userRepository.findByIdentifier(identifier);
	}

	public async storeToken(tokenData: {
		userId: string;
		token: string;
		deviceInfo: DeviceInfo;
		lastUsed: Date;
		useCount: number;
		maxUses: number;
	}) {
		const authToken = new AuthModel(tokenData);
		return authToken.save();
	}

	public async findTokenByRefreshToken(token: string) {
		return AuthModel.findOne({ token });
	}

	public async updateTokenUsage(token: string) {
		return AuthModel.findOneAndUpdate(
			{ token },
			{
				$inc: { useCount: 1 },
				$set: { lastUsed: new Date() },
			},
			{ new: true }
		);
	}

	public async removeToken(userId: string, token: string) {
		return AuthModel.deleteOne({ userId, token });
	}
}
