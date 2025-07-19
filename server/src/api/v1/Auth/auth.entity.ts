import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToOne, JoinColumn } from "typeorm";
import { User } from "../User/user.entity";
import bcrypt from "bcryptjs";

@Entity("auth")
export class Auth {
	@PrimaryGeneratedColumn("uuid")
	id!: string;

	@Column()
	userId!: string;

	@OneToOne(() => User)
	@JoinColumn({ name: "userId" })
	user!: User;

	@Column()
	password!: string;

	@Column({ nullable: true })
	refreshToken?: string;

	@Column({ type: "timestamp", nullable: true })
	refreshTokenExpires?: Date;

	@CreateDateColumn()
	createdAt!: Date;

	@UpdateDateColumn()
	updatedAt!: Date;

	async hashPassword() {
		if (this.password) {
			const salt = await bcrypt.genSalt(10);
			this.password = await bcrypt.hash(this.password, salt);
		}
	}

	async verifyPassword(password: string): Promise<boolean> {
		return bcrypt.compare(password, this.password);
	}
}

export default Auth;
