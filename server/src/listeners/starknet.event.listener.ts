import { RpcProvider, hash, num } from 'starknet';
import { starknetProvider, predictionHubContract } from '../config/starknet';
import { StarknetService } from '../services/starknet.service';
import fs from 'fs';
import path from 'path';
import { MarketService } from '../api/v1/market/market.service';

// Initialize services
const marketService = new MarketService();
const starknetService = new StarknetService();

// File to track last processed block
const LAST_BLOCK_FILE = path.resolve(__dirname, '../../../last_processed_block.txt');

/**
 * Reads the last processed block number from file
 */
function readLastProcessedBlock(): number {
    try {
        if (fs.existsSync(LAST_BLOCK_FILE)) {
            return parseInt(fs.readFileSync(LAST_BLOCK_FILE, 'utf-8').trim());
        }
    } catch (error) {
        console.error('Error reading last processed block file, starting from 0:', error);
    }
    return 0;
}

/**
 * Writes the latest processed block number to file
 */
function writeLastProcessedBlock(blockNumber: number): void {
    try {
        fs.writeFileSync(LAST_BLOCK_FILE, blockNumber.toString());
    } catch (error) {
        console.error('Error writing last processed block file:', error);
    }
}

// Event selectors
const MARKET_CREATED_EVENT_HASH = hash.getSelectorFromName('MarketCreated');
const MARKET_RESOLVED_EVENT_HASH = hash.getSelectorFromName('MarketResolved');
const WAGER_PLACED_EVENT_HASH = hash.getSelectorFromName('WagerPlaced');

/**
 * Starts the StarkNet event listener
 */
export async function startStarknetEventListener(): Promise<void> {
    let lastProcessedBlock = readLastProcessedBlock();
    const POLLING_INTERVAL_MS = 10000;

    const fetchAndProcessEvents = async () => {
        try {
            const latestBlock = await starknetProvider.getBlock('latest');
            const newLatestBlockNumber = latestBlock.block_number;

            if (newLatestBlockNumber > lastProcessedBlock) {
                for (let blockNum = lastProcessedBlock + 1; blockNum <= newLatestBlockNumber; blockNum++) {
                    const block = await starknetProvider.getBlockWithTxHashes(blockNum);
                    const blockTimestamp = block.timestamp;

                    const { events } = await starknetProvider.getEvents({
                        address: predictionHubContract.address,
                        from_block: { block_number: blockNum },
                        to_block: { block_number: blockNum },
                        chunk_size: 100,
                    });

                    for (const event of events) {
                        const eventSelector = event.keys[0];
                        const txHash = event.transaction_hash;

                        try {
                            const txReceipt = await starknetProvider.getTransactionReceipt(txHash);

                            // Parse events from transaction receipt
                            type ParsedEvents = {
                                MarketCreated?: Array<{ market_id: any; market_type: any }>;
                                MarketResolved?: Array<{ market_id: any; resolver: any; winning_choice: any }>;
                                WagerPlaced?: Array<{ market_id: any; user: any; choice: any; amount: any; fee_amount: any; net_amount: any; wager_index: any }>;
                                [key: string]: any;
                            };
                            const parsedEvents: ParsedEvents = predictionHubContract.parseEvents(txReceipt);

                            if (
                                eventSelector === MARKET_CREATED_EVENT_HASH &&
                                Array.isArray(parsedEvents['MarketCreated']) &&
                                parsedEvents['MarketCreated'].length > 0 &&
                                parsedEvents['MarketCreated'][0] !== undefined
                            ) {
                                const marketCreatedData = parsedEvents['MarketCreated'][0];
                                if (marketCreatedData && marketCreatedData.market_id !== undefined && marketCreatedData.market_type !== undefined) {
                                    const fullMarketDetails = await starknetService.getMarketDetailsFromContract(
                                        marketCreatedData.market_id,
                                        marketCreatedData.market_type
                                    );
                                    await marketService.createMarket({ ...fullMarketDetails, blockTimestamp });
                                }
                            } else if (
                                eventSelector === MARKET_RESOLVED_EVENT_HASH &&
                                Array.isArray(parsedEvents['MarketResolved']) &&
                                parsedEvents['MarketResolved'].length > 0 &&
                                parsedEvents['MarketResolved'][0] !== undefined
                            ) {
                                const marketResolvedData = parsedEvents['MarketResolved'][0];
                                if (marketResolvedData) {
                                    await marketService.updateMarketResolution(marketResolvedData, blockTimestamp);
                                }
                            } else if (
                                eventSelector === WAGER_PLACED_EVENT_HASH &&
                                Array.isArray(parsedEvents['WagerPlaced']) &&
                                parsedEvents['WagerPlaced'].length > 0 &&
                                parsedEvents['WagerPlaced'][0] !== undefined
                            ) {
                                const wagerPlacedData = parsedEvents['WagerPlaced'][0];
                                if (wagerPlacedData) {
                                    await marketService.updateMarketWager(wagerPlacedData, blockTimestamp);
                                }
                            }

                        } catch (eventProcessingError) {
                            console.error(`Error processing event in TX ${txHash}:`, eventProcessingError);
                        }
                    }

                    writeLastProcessedBlock(blockNum);
                }

                lastProcessedBlock = newLatestBlockNumber;
            }

        } catch (error) {
            console.error('Error in Starknet event listener loop:', error);
        } finally {
            setTimeout(fetchAndProcessEvents, POLLING_INTERVAL_MS);
        }
    };

    fetchAndProcessEvents();
}