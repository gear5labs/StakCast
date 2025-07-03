import { BigNumberish } from 'starknet';

// ==================== Smart Contract Event Types ====================
export interface MarketCreatedEvent {
    market_id: BigNumberish;
    creator: BigNumberish;
    market_type: number;
}

export interface MarketResolvedEvent {
    market_id: BigNumberish;
    resolver: BigNumberish;
    winning_choice: number;
}

export interface WagerPlacedEvent {
    market_id: BigNumberish;
    user: BigNumberish;
    choice: number;
    amount: BigNumberish;
    fee_amount: BigNumberish;
    net_amount: BigNumberish;
    wager_index: number;
}

// ==================== API Request/Response Types ====================
interface BaseMarketCreateRequest {
    title: string;
    description: string;
    choices: [string, string];
    category: string;
    imageUrl: string;
    endTime: number;
}

export interface GeneralMarketCreateRequest extends BaseMarketCreateRequest {
    type: 'general';
}

export interface CryptoMarketCreateRequest extends BaseMarketCreateRequest {
    type: 'crypto';
    comparisonType: 0 | 1;
    assetKey: string;
    targetValue: string;
}

export interface SportsMarketCreateRequest extends BaseMarketCreateRequest {
    type: 'sports';
    eventId: number;
    teamFlag: boolean;
}

export interface BusinessMarketCreateRequest extends BaseMarketCreateRequest {
    type: 'business';
    eventId: number;
}

export type CreateMarketRequest =
    | GeneralMarketCreateRequest
    | CryptoMarketCreateRequest
    | SportsMarketCreateRequest
    | BusinessMarketCreateRequest;

export interface ApiMarket {
    id: string;
    title: string;
    description: string;
    marketType: MarketType;
    category: string;
    imageUrl: string;
    endTime: number;
    isResolved: boolean;
    isOpen: boolean;
    winningChoice?: number;
    totalPool: string;
    creator: string;
    createdAt: number;
    updatedAt: number;
    choice0Label: string;
    choice0Staked: string;
    choice1Label: string;
    choice1Staked: string;
    comparisonType?: number;
    assetKey?: string;
    targetValue?: string;
    eventId?: number;
    teamFlag?: boolean;
}


export type MarketType = 'general' | 'crypto' | 'sports' | 'business';

// Enums used across the app
export enum ChoiceIndex {
    CHOICE_0 = 'CHOICE_0',
    CHOICE_1 = 'CHOICE_1',
}