import { injectable } from "tsyringe";
import { Repository } from "typeorm";
import AppDataSource from "../../../config/DataSource";
import Market from "./buyshares.entity";

@injectable()
export default class MarketRepository {
  private marketRepository: Repository<Market>;

  constructor() {
    this.marketRepository = AppDataSource.getRepository(Market);
  }

  async findById(marketId: string): Promise<Market | null> {
    return this.marketRepository.findOne({ where: { id: marketId } });
  }
}
