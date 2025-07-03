import { MarketRepository } from './market.repositry';
import { Market } from './market.entity';
import {
  ApiMarket,
  MarketCreatedEvent,
  MarketResolvedEvent,
  WagerPlacedEvent,
  MarketType,
  ChoiceIndex,
} from '../../../types/backend.types';
import {
  u256ToDecimalString,
  u64ToDate,
  cairoChoiceIndexToTypeORM,
  prismaMarketToApiMarket,
  cairoMarketTypeToMarketType,
} from '../../../utils/converters';
import { BigNumberish, num } from 'starknet';

export class MarketService {
  private marketRepository: MarketRepository;

  constructor() {
    this.marketRepository = new MarketRepository();
  }

  async createMarket(marketDetails: any, blockTimestamp: number): Promise<ApiMarket> {
    // You may need to convert market_type to marketType here if needed
    const savedMarket = await this.marketRepository.createMarket(marketDetails, blockTimestamp);
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