import { Repository } from 'typeorm';
import AppDataSource from '../../../config/DataSource';
import { Market } from './market.entity';
import { MarketType, ChoiceIndex, ApiMarket, MarketResolvedEvent, WagerPlacedEvent } from '../../../types/backend.types';
import { u256ToDecimalString, u64ToDate, cairoChoiceIndexToTypeORM, prismaMarketToApiMarket } from '../../../utils/converters';
import { BigNumberish, num } from 'starknet';

export class MarketRepository {
  private marketRepository: Repository<Market>;

  constructor() {
    this.marketRepository = AppDataSource.getRepository(Market);
  }

  async createMarket(marketDetails: any, blockTimestamp: number): Promise<Market> {
    const newMarket = this.marketRepository.create({
      id: num.toHex(marketDetails.market_id),
      creator: num.toHex(marketDetails.creator),
      marketType: marketDetails.marketType,
      title: marketDetails.title,
      description: marketDetails.description,
      category: marketDetails.category,
      imageUrl: marketDetails.image_url,
      endTime: BigInt(marketDetails.end_time).toString(),
      isResolved: marketDetails.is_resolved,
      isOpen: marketDetails.is_open,
      totalPool: u256ToDecimalString(marketDetails.total_pool),
      createdAt: u64ToDate(blockTimestamp),
      updatedAt: u64ToDate(blockTimestamp),
      choice0Label: marketDetails.choice0Label,
      choice0Staked: u256ToDecimalString(marketDetails.choice0Staked || 0),
      choice1Label: marketDetails.choice1Label,
      choice1Staked: u256ToDecimalString(marketDetails.choice1Staked || 0),
      comparisonType: marketDetails.comparison_type,
      assetKey: marketDetails.asset_key,
      targetValue: marketDetails.target_value ? BigInt(marketDetails.target_value).toString() : null,
      eventId: marketDetails.event_id ? BigInt(marketDetails.event_id).toString() : null,
      teamFlag: marketDetails.team_flag,
    });
    return this.marketRepository.save(newMarket);
  }

  async updateMarketResolution(event: MarketResolvedEvent, blockTimestamp: number): Promise<Market> {
    const marketIdHex = num.toHex(event.market_id);
    const winningChoice = cairoChoiceIndexToTypeORM(event.winning_choice);
    await this.marketRepository.update(
      { id: marketIdHex },
      {
        isResolved: true,
        isOpen: false,
        winningChoice,
        updatedAt: u64ToDate(blockTimestamp),
      }
    );
    return this.marketRepository.findOneByOrFail({ id: marketIdHex });
  }

  async updateMarketWager(event: WagerPlacedEvent, blockTimestamp: number): Promise<Market> {
    const marketIdHex = num.toHex(event.market_id);
    const wagerAmount = u256ToDecimalString(event.amount);
    const choice = cairoChoiceIndexToTypeORM(event.choice);
    const market = await this.marketRepository.findOneByOrFail({ id: marketIdHex });
    market.totalPool = (BigInt(market.totalPool) + BigInt(wagerAmount)).toString();
    if (choice === ChoiceIndex.CHOICE_0) {
      market.choice0Staked = (BigInt(market.choice0Staked) + BigInt(wagerAmount)).toString();
    } else {
      market.choice1Staked = (BigInt(market.choice1Staked) + BigInt(wagerAmount)).toString();
    }
    market.updatedAt = u64ToDate(blockTimestamp);
    return this.marketRepository.save(market);
  }

  async getMarkets(
    where: any,
    limit?: number,
    offset?: number
  ): Promise<Market[]> {
    const [markets] = await this.marketRepository.findAndCount({
      where,
      take: limit,
      skip: offset,
      order: { createdAt: 'DESC' },
    });
    return markets;
  }

  async getMarketById(marketId: string): Promise<Market | null> {
    return this.marketRepository.findOneBy({ id: marketId });
  }
}
