import { MarketRepository } from './market.repository';
import { Market, MarketType as MarketTypeEnum } from './market.entity';
import {
  ApiMarket,
  MarketCreatedEvent,
  MarketResolvedEvent,
  WagerPlacedEvent,
  MarketType,
  ChoiceIndex,
  CreateMarketRequest,
  CryptoMarketCreateRequest,
  SportsMarketCreateRequest,
  BusinessMarketCreateRequest
} from '../../../types/backend.types';
import {
  u256ToDecimalString,
  u64ToDate,
  cairoChoiceIndexToTypeORM,
  prismaMarketToApiMarket,
  cairoMarketTypeToMarketType,
} from '../../../utils/converters';
import { BigNumberish, num } from 'starknet';
import { injectable, inject } from 'tsyringe';

@injectable()
export class MarketService {
  constructor(
    @inject(MarketRepository) private marketRepository: MarketRepository
  ) {}

  async createMarket(marketDetails: CreateMarketRequest & { market_id: string, creator: string, total_pool: string, is_resolved: boolean, is_open: boolean, choice0Staked?: string, choice1Staked?: string, blockTimestamp: number }): Promise<ApiMarket> {
    // Prepare and transform data for Market entity
    const {
      market_id,
      creator,
      type,
      title,
      description,
      category,
      imageUrl,
      endTime,
      choices,
      total_pool,
      is_resolved,
      is_open,
      choice0Staked,
      choice1Staked,
      blockTimestamp,
      ...rest
    } = marketDetails;

    // Convert string type to MarketType enum
    let marketType = (Object.values(MarketTypeEnum) as string[]).includes(type)
      ? (type as MarketTypeEnum)
      : MarketTypeEnum.GENERAL;
    let comparisonType = null;
    let assetKey = null;
    let targetValue = null;
    let eventId = null;
    let teamFlag = null;

    if (type === 'crypto') {
      comparisonType = (marketDetails as CryptoMarketCreateRequest).comparisonType;
      assetKey = (marketDetails as CryptoMarketCreateRequest).assetKey;
      targetValue = (marketDetails as CryptoMarketCreateRequest).targetValue;
    } else if (type === 'sports') {
      eventId = (marketDetails as SportsMarketCreateRequest).eventId;
      teamFlag = (marketDetails as SportsMarketCreateRequest).teamFlag;
    } else if (type === 'business') {
      eventId = (marketDetails as BusinessMarketCreateRequest).eventId;
    }

    const marketEntity = {
      id: market_id,
      creator,
      marketType,
      title,
      description,
      category,
      imageUrl,
      endTime: BigInt(endTime).toString(),
      isResolved: is_resolved,
      isOpen: is_open,
      totalPool: total_pool,
      createdAt: new Date(blockTimestamp * 1000),
      updatedAt: new Date(blockTimestamp * 1000),
      choice0Label: choices[0],
      choice0Staked: choice0Staked || '0',
      choice1Label: choices[1],
      choice1Staked: choice1Staked || '0',
      comparisonType,
      assetKey,
      targetValue: targetValue ? BigInt(targetValue).toString() : null,
      eventId: eventId ? BigInt(eventId).toString() : null,
      teamFlag,
    };

    const savedMarket = await this.marketRepository.createMarket(marketEntity);
    return prismaMarketToApiMarket(savedMarket);
  }

  async updateMarketResolution(event: MarketResolvedEvent, blockTimestamp: number): Promise<ApiMarket> {
    const updatedMarket = await this.marketRepository.updateMarketResolution(event, blockTimestamp);
    return prismaMarketToApiMarket(updatedMarket);
  }

  async updateMarketWager(event: WagerPlacedEvent, blockTimestamp: number): Promise<void> {
    await this.marketRepository.updateMarketWager(event, blockTimestamp);
  }

  async getMarkets(
    status?: 'open' | 'resolved' | 'all',
    marketType?: MarketType,
    category?: string,
    creator?: string,
    search?: string,
    limit?: number,
    offset?: number
  ): Promise<ApiMarket[]> {
    const where: any = {};
    if (status === 'open') {
      where.isOpen = true;
      where.isResolved = false;
    } else if (status === 'resolved') {
      where.isResolved = true;
    }
    if (marketType) {
      where.marketType = marketType;
    }
    if (category) {
      where.category = category;
    }
    if (creator) {
      where.creator = creator;
    }
    if (search) {
      where.title = () => `ILIKE '%${search}%'`;
    }
    const markets = await this.marketRepository.getMarkets(where, limit, offset);
    return markets.map(prismaMarketToApiMarket);
  }

  async getMarketById(marketId: string): Promise<ApiMarket | null> {
    const market = await this.marketRepository.getMarketById(marketId);
    return market ? prismaMarketToApiMarket(market) : null;
  }
}