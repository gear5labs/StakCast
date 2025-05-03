import { injectable } from "tsyringe";
import User, { IUser } from "./User.model";


export default class UserRepository {
	private constructor() {}

	async createUser(userData: Partial<IUser>): Promise<IUser> {
		const user = new User(userData);
		return await user.save();
	}

	async findByUsername(username: string): Promise<IUser | null> {
		return await User.findOne({ username });
	}

	async findById(userId: string): Promise<IUser | null> {
		return await User.findById(userId);
	}

	async findByIdentifier(identifier: string): Promise<IUser | null> {
		return User.findOne({
			$or: [{ email: identifier }, { username: identifier }],
		});
	}
}
