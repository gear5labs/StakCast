import {
	Entity,
	PrimaryGeneratedColumn,
	Column,
	CreateDateColumn,
	UpdateDateColumn,
	OneToOne,
	JoinColumn,
} from "typeorm";
import { User } from "../User/user.entity";
import { boolean } from "zod";

@Entity("wallets")
export class Wallet {
	@PrimaryGeneratedColumn("uuid")
	id!: string;

	@Column({ unique: true })
	address!: string;

	@Column()
	publicKey!: string;

	@Column({ type: "text" })
	keystoreJson!: string;

	@Column({ type: "bool", default: false })
	deployed!: boolean;

	@OneToOne(() => User, { onDelete: "CASCADE" })
	@JoinColumn({ name: "userId" })
	user!: User;

	@Column()
	userId!: string;

	@CreateDateColumn()
	createdAt!: Date;

	@UpdateDateColumn()
	updatedAt!: Date;
}

export default Wallet;
