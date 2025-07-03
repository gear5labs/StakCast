import { BigNumberish, shortString, num } from 'starknet';
import { ChoiceIndex, ApiMarket, MarketType } from '../types/backend.types';
import { Market } from '../api/v1/market/market.entity';

/**
 * Converts a felt252 value (string or number) to a readable string using StarkNet's shortString.decodeShortString
 */
export function felt252ToString(felt: BigNumberish): string {
    if (typeof felt === 'string' && felt.startsWith('0x')) {
        return shortString.decodeShortString(felt);
    }
    return shortString.decodeShortString(num.toHex(felt));
}

/**
 * Converts a regular string to a felt252 encoded value
 */
export function stringToFelt252(str: string): BigNumberish {
    return shortString.encodeShortString(str);
}

/**
 * Converts U256 value to a decimal string representation
 */
export function u256ToDecimalString(value: BigNumberish): string {
    return value.toString();
}

/**
 * Converts Cairo's u64 timestamp to JavaScript Date object
 */
export function u64ToDate(timestamp: number | BigInt): Date {
    return new Date(Number(timestamp) * 1000); // Cairo uses seconds, JS uses ms
}

/**
 * Converts JS Date to Cairo-compatible u64 timestamp
 */
export function dateToU64(date: Date): number {
    return Math.floor(date.getTime() / 1000);
}

/**
 * Maps Cairo market_type number to TypeScript enum
 */
export function cairoMarketTypeToMarketType(type: number): MarketType {
    switch (type) {
        case 0:
            return 'general';
        case 1:
            return 'crypto';
        case 2:
            return 'sports';
        case 3:
            return 'business';
        default:
            throw new Error(`Unknown market type: ${type}`);
    }
}

/**
 * Maps Cairo choice index (0 | 1) to ChoiceIndex enum
 */
export function cairoChoiceIndexToTypeORM(choice: number): ChoiceIndex {
    switch (choice) {
        case 0:
            return ChoiceIndex.CHOICE_0;
        case 1:
            return ChoiceIndex.CHOICE_1;
        default:
            throw new Error(`Unknown choice index: ${choice}`);
    }
}

/**
 * Converts a TypeORM Market entity to an API-friendly format
 */
export function prismaMarketToApiMarket(market: Market): ApiMarket {
    return {
        id: market.id,
        title: market.title,
        description: market.description,
        marketType: market.marketType,
        category: market.category,
        imageUrl: market.imageUrl,
        endTime: Number(market.endTime) * 1000, // Convert Cairo seconds → JS milliseconds
        isResolved: market.isResolved,
        isOpen: market.isOpen,
        winningChoice:
            market.winningChoice === ChoiceIndex.CHOICE_0 ? 0 : market.winningChoice === ChoiceIndex.CHOICE_1 ? 1 : undefined,
        totalPool: market.totalPool.toString(),
        creator: market.creator,
        createdAt: market.createdAt instanceof Date ? market.createdAt.getTime() : new Date(market.createdAt).getTime(),
        updatedAt: market.updatedAt instanceof Date ? market.updatedAt.getTime() : new Date(market.updatedAt).getTime(),
        choice0Label: market.choice0Label,
        choice0Staked: market.choice0Staked.toString(),
        choice1Label: market.choice1Label,
        choice1Staked: market.choice1Staked.toString(),
        ...(market.marketType === 'crypto' && {
            comparisonType: market.comparisonType || undefined,
            assetKey: market.assetKey || undefined,
            targetValue: market.targetValue ? market.targetValue.toString() : undefined,
        }),
        ...(market.marketType === 'sports' && {
            eventId: market.eventId ? Number(market.eventId) : undefined,
            teamFlag: market.teamFlag || undefined,
        }),
        ...(market.marketType === 'business' && {
            eventId: market.eventId ? Number(market.eventId) : undefined,
        }),
    };
}