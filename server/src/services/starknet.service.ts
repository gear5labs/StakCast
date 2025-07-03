import { RpcProvider, Contract, BigNumberish, num } from 'starknet';
import { predictionHubContract, starknetProvider } from '../config/starknet';
import { felt252ToString, cairoMarketTypeToMarketType } from '../utils/converters';
import { MarketType, ChoiceIndex } from '../types/backend.types';
import { cairoChoiceIndexToTypeORM } from '../utils/converters';

export class StarknetService {
  private readonly provider: RpcProvider;
  private readonly predictionHub: Contract;

  constructor() {
    this.provider = starknetProvider;
    this.predictionHub = predictionHubContract;
  }

  /**
   * Fetches market details from the StarkNet contract based on market ID and type
   */
  async getMarketDetailsFromContract(marketId: BigNumberish, marketType: number): Promise<any> {
    try {
      let methodName: string;

      switch (marketType) {
        case 0:
          methodName = 'get_prediction';
          break;
        case 1:
          methodName = 'get_crypto_prediction';
          break;
        case 2:
          methodName = 'get_sports_prediction';
          break;
        case 3:
          methodName = 'get_business_prediction';
          break;
        default:
          throw new Error(`Invalid market type (${marketType}) for contract query.`);
      }

      const response = await this.predictionHub.call(methodName, [marketId]);
      type MarketData = {
        market_id: BigNumberish;
        title: BigNumberish;
        description: BigNumberish;
        choices: {
          label0: BigNumberish;
          label1: BigNumberish;
          staked_amount0: BigNumberish;
          staked_amount1: BigNumberish;
        };
        category: BigNumberish;
        image_url: BigNumberish;
        is_resolved: boolean;
        is_open: boolean;
        end_time: BigNumberish;
        winning_choice: { is_some: boolean; v0: number };
        total_pool: BigNumberish;
        creator: BigNumberish;
      };
      const marketData = response as MarketData;

      return {
        market_id: num.toBigInt(marketData.market_id),
        title: felt252ToString(marketData.title),
        description: felt252ToString(marketData.description),
        choice0Label: felt252ToString(marketData.choices.label0),
        choice1Label: felt252ToString(marketData.choices.label1),
        choice0Staked: num.toBigInt(marketData.choices.staked_amount0),
        choice1Staked: num.toBigInt(marketData.choices.staked_amount1),
        category: felt252ToString(marketData.category),
        image_url: felt252ToString(marketData.image_url),
        is_resolved: marketData.is_resolved,
        is_open: marketData.is_open,
        end_time: marketData.end_time,
        winning_choice: marketData.winning_choice.is_some ? cairoChoiceIndexToTypeORM(marketData.winning_choice.v0) : null,
        total_pool: num.toBigInt(marketData.total_pool),
        creator: num.toHex(marketData.creator),
        market_type: cairoMarketTypeToMarketType(marketType),
      };
    } catch (error) {
      console.error(`Error fetching market ${num.toHex(marketId)} from contract:`, error);
      throw new Error('Failed to fetch market details from StarkNet contract');
    }
  }
}