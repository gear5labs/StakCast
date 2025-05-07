// src/services/UserService.ts
import { injectable, inject } from "tsyringe";
import AuthRepository from "../Auth/AuthRepository";
import bcrypt from "bcrypt";
import { IUser } from "./User.model";
import { ApplicationError } from "../../../utils/errorHandler";
import HttpStatusCodes from "../../../constants/HttpStatusCodes";
import  UserRepository from "./User.repository";

@injectable()
class UserService {
	constructor(
		@inject("UserRepository") private userRepository: UserRepository,
		@inject("AuthRepository") private authRepository: AuthRepository
	) {}

	async register(userDetails: Partial<IUser>): Promise<IUser> {
		const { email, username, password } = userDetails;
		
		if (!email || !password || !username) {
			throw new ApplicationError(
				"Email, username and password are required",
				HttpStatusCodes.UNPROCESSABLE_ENTITY
			);
		}

		// Check for existing user by email or username
		const existingUser = await this.userRepository.findByIdentifier(email) 
			|| await this.userRepository.findByIdentifier(username);
			
		if (existingUser) {
			throw new ApplicationError(
				"User with this email or username already exists",
				HttpStatusCodes.CONFLICT
			);
		}

		return this.userRepository.createUser(userDetails);
	}
}

export default UserService;
