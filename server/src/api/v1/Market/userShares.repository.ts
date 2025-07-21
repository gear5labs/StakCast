import { injectable } from "tsyringe";
import { Repository } from "typeorm";
import AppDataSource from "../../../config/DataSource";
import UserShares from "./userShares.entity";
import User from "../User/user.entity";
import Market from "./buyshares.entity";

@injectable()
export default class UserSharesRepository {
  private userSharesRepository: Repository<UserShares>;

  constructor() {
    this.userSharesRepository = AppDataSource.getRepository(UserShares);
  }

  async findByUserAndMarket(user: User, market: Market): Promise<UserShares | null> {
    return this.userSharesRepository.findOne({ where: { user, market } });
  }

  async save(userShares: UserShares): Promise<UserShares> {
    return this.userSharesRepository.save(userShares);
  }

  create(data: Partial<UserShares>): UserShares {
    return this.userSharesRepository.create(data);
  }
}
