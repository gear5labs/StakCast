import { Request, Response, NextFunction } from 'express';
import { injectable, inject } from 'tsyringe';
import Joi from 'joi';
import { MarketService } from './market.service';
import { StarknetService } from '../../../services/starknet.service';
import { CreateMarketRequest, ApiMarket, CryptoMarketCreateRequest, SportsMarketCreateRequest, BusinessMarketCreateRequest, MarketType } from '../../../types/backend.types';
import { stringToFelt252, dateToU64 } from '../../../utils/converters';
import { BigNumberish } from 'starknet';
import { predictionHubContract } from '../../../config/starknet';

@injectable()
export class MarketController {
  constructor(
    @inject(MarketService) private marketService: MarketService,
    @inject(StarknetService) private starknetService: StarknetService
  ) {}
  async getMarkets(req: Request, res: Response, next: NextFunction) {
    const schema = Joi.object({
      status: Joi.string().valid('open', 'resolved', 'all'),
      type: Joi.string().valid('general', 'crypto', 'sports', 'business'),
      category: Joi.string(),
      creator: Joi.string(),
      search: Joi.string(),
      limit: Joi.number().integer().min(1),
      offset: Joi.number().integer().min(0)
    });
    const { error } = schema.validate(req.query);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const { status, type, category, creator, search, limit, offset } = req.query;

    let marketType: MarketType | undefined;
    if (typeof type === 'string') {
      switch (type.toLowerCase()) {
        case 'general':
          marketType = 'general';
          break;
        case 'crypto':
          marketType = 'crypto';
          break;
        case 'sports':
          marketType = 'sports';
          break;
        case 'business':
          marketType = 'business';
          break;
      }
    }

    const parsedLimit = limit ? parseInt(limit as string) : undefined;
    const parsedOffset = offset ? parseInt(offset as string) : undefined;

    try {
      const markets = await this.marketService.getMarkets(
        status as 'open' | 'resolved' | 'all',
        marketType,
        category as string,
        creator as string,
        search as string,
        parsedLimit,
        parsedOffset
      );
      res.json(markets);
    } catch (error) {
      next(error);
    }
  }

  async getMarketById(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const market = await this.marketService.getMarketById(id);

      if (market) {
        res.json(market);
      } else {
        res.status(404).send('Market not found');
      }
    } catch (error) {
      next(error);
    }
  }

  async createMarket(req: Request, res: Response, next: NextFunction) {
    const marketRequest: CreateMarketRequest = req.body;

    if (
      !marketRequest.title ||
      !marketRequest.description ||
      !marketRequest.choices ||
      marketRequest.choices.length !== 2 ||
      !marketRequest.type ||
      !marketRequest.endTime
    ) {
      return res.status(400).send('Missing required market creation fields.');
    }

    const commonArgs = [
      stringToFelt252(marketRequest.title),
      stringToFelt252(marketRequest.description),
      stringToFelt252(marketRequest.choices[0]),
      stringToFelt252(marketRequest.choices[1]),
      stringToFelt252(marketRequest.category),
      stringToFelt252(marketRequest.imageUrl),
      dateToU64(new Date(marketRequest.endTime * 1000)),
    ];

    let contractCallArgs: (BigNumberish | boolean)[];
    let entrypoint: string;
    let marketTypeU8: number;

    switch (marketRequest.type) {
      case 'general':
        entrypoint = 'create_prediction';
        contractCallArgs = commonArgs;
        marketTypeU8 = 0;
        break;
      case 'crypto':
        entrypoint = 'create_crypto_prediction';
        const cryptoReq = marketRequest as CryptoMarketCreateRequest;
        contractCallArgs = [
          ...commonArgs,
          cryptoReq.comparisonType,
          stringToFelt252(cryptoReq.assetKey),
          BigInt(cryptoReq.targetValue),
        ];
        marketTypeU8 = 1;
        break;
      case 'sports':
        entrypoint = 'create_sports_prediction';
        const sportsReq = marketRequest as SportsMarketCreateRequest;
        contractCallArgs = [...commonArgs, sportsReq.eventId, sportsReq.teamFlag];
        marketTypeU8 = 2;
        break;
      case 'business':
        entrypoint = 'create_business_prediction';
        const businessReq = marketRequest as BusinessMarketCreateRequest;
        contractCallArgs = [...commonArgs, businessReq.eventId];
        marketTypeU8 = 3;
        break;
      default:
        return res.status(400).send('Invalid market type for creation.');
    }

    // Convert BigInt values in calldata to strings for JSON serialization
    const serializedCalldata = contractCallArgs.map(arg =>
      typeof arg === 'bigint' ? arg.toString() : arg
    );
    res.status(200).json({
      message: 'Market creation transaction data prepared for frontend.',
      contractAddress: predictionHubContract.address,
      entrypoint: entrypoint,
      calldata: serializedCalldata,
      marketType: marketTypeU8,
    });
  }
}