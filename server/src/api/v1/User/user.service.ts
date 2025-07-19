// src/services/UserService.ts
import { injectable } from "tsyringe";
import { DataSource } from "typeorm";
import UserRepository from "./user.repository";
import User from "./user.entity";
import AppDataSource from "../../../config/DataSource";

@injectable()
export default class UserService {
	constructor(private userRepository: UserRepository) {}

	async createUser(userData: { email: string; firstName: string; lastName: string }): Promise<User> {
		const existingUser = await this.userRepository.findByEmail(userData.email);
		if (existingUser) {
			throw new Error("User already exists");
		}
		return this.userRepository.createUser(userData);
	}

	async getUserById(userId: string): Promise<User> {
		const user = await this.userRepository.findById(userId);
		if (!user) {
			throw new Error("User not found");
		}
		return user;
	}

	async getUserByEmail(email: string): Promise<User> {
		const user = await this.userRepository.findByEmail(email);
		if (!user) {
			throw new Error("User not found");
		}
		return user;
	}

	async updateUser(userId: string, userData: Partial<User>): Promise<User> {
		const user = await this.userRepository.updateUser(userId, userData);
		if (!user) {
			throw new Error("User not found");
		}
		return user;
	}

	async createUserWithTransaction(userData: { email: string; firstName: string; lastName: string }): Promise<User> {
		const queryRunner = AppDataSource.createQueryRunner();
		await queryRunner.connect();
		await queryRunner.startTransaction();

		try {
			const user = await this.userRepository.createUser(userData, queryRunner);
			await queryRunner.commitTransaction();
			return user;
		} catch (error) {
			await queryRunner.rollbackTransaction();
			throw error;
		} finally {
			await queryRunner.release();
		}
	}
}
