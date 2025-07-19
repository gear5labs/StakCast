import { injectable } from "tsyringe";
import { Repository, QueryRunner } from "typeorm";
import AppDataSource from "../../../config/DataSource";
import User from "./user.entity";

@injectable()
export default class UserRepository {
	private userRepository: Repository<User>;

	constructor() {
		this.userRepository = AppDataSource.getRepository(User);
	}

	async createUser(userData: Partial<User>, queryRunner?: QueryRunner): Promise<User> {
		const repository = queryRunner ? queryRunner.manager.getRepository(User) : this.userRepository;
		const user = repository.create(userData);
		return repository.save(user);
	}

	async findByEmail(email: string): Promise<User | null> {
		return this.userRepository.findOne({ where: { email } });
	}

	async findById(userId: string): Promise<User | null> {
		return this.userRepository.findOne({ where: { id: userId } });
	}

	async updateUser(userId: string, userData: Partial<User>): Promise<User | null> {
		await this.userRepository.update(userId, userData);
		return this.findById(userId);
	}
}
