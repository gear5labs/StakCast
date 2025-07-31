import {
	Entity,
	PrimaryGeneratedColumn,
	Column,
	CreateDateColumn,
	UpdateDateColumn,
	ManyToOne,
	JoinColumn,
} from "typeorm";
import { User } from "../User/user.entity";

export enum UserRole {
	ADMIN = "admin",
	MODERATOR = "moderator",
	USER = "user",
}

@Entity("user_roles")
export class UserRoleEntity {
	@PrimaryGeneratedColumn("uuid")
	id!: string;

	@Column({ type: "enum", enum: UserRole, default: UserRole.USER })
	role!: UserRole;

	@Column()
	userId!: string;

	@ManyToOne(() => User, { eager: true })
	@JoinColumn({ name: "userId" })
	user!: User;

	@Column({ nullable: true })
	assignedBy!: string;

	@Column({ nullable: true })
	contractAddress!: string;

	@Column({ nullable: true })
	transactionHash!: string;

	@Column({ default: true })
	isActive!: boolean;

	@CreateDateColumn()
	createdAt!: Date;

	@UpdateDateColumn()
	updatedAt!: Date;
}

export default UserRoleEntity;
