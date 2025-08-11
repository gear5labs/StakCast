import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToOne } from "typeorm";
import { Wallet } from "../Wallet/wallet.entity";

@Entity("users")
export class User {
	@PrimaryGeneratedColumn("uuid")
	id!: string;

	@Column({ unique: true })
	email!: string;

	@Column()
	firstName!: string;

	@Column()
	lastName!: string;

	@OneToOne(() => Wallet, wallet => wallet.user)
	wallet!: Wallet;

	@CreateDateColumn()
	createdAt!: Date;

	@UpdateDateColumn()
	updatedAt!: Date;
}

export default User;
