import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, Unique } from "typeorm";
import User from "../User/user.entity";
import Market from "./buyshares.entity";

@Entity("user_shares")
@Unique(["user", "market"])
export class UserShares {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @ManyToOne(() => User, { eager: true })
  user!: User;

  @ManyToOne(() => Market, { eager: true })
  market!: Market;

  @Column({ type: 'int', default: 0 })
  shares!: number;
}

export default UserShares;
