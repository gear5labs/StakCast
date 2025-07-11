import { RoleService } from './role.service';
import { RoleType } from './role.entity';

export interface ContractEvent {
  type: 'ModeratorAdded' | 'ModeratorRemoved';
  userId: string;
  blockNumber?: number;
  transactionHash?: string;
  timestamp?: Date;
}

export class ContractSyncService {
  private roleService: RoleService;

  constructor() {
    this.roleService = new RoleService();
  }

  /**
   * Process a contract event and sync it with the database
   */
  async processContractEvent(event: ContractEvent): Promise<void> {
    try {
      console.log(`Processing contract event: ${event.type} for user ${event.userId}`);

      switch (event.type) {
        case 'ModeratorAdded':
          await this.handleModeratorAdded(event.userId);
          break;
        case 'ModeratorRemoved':
          await this.handleModeratorRemoved(event.userId);
          break;
        default:
          console.warn(`Unknown event type: ${event.type}`);
      }
    } catch (error: any) {
      console.error(`Failed to process contract event: ${error.message}`);
      throw error;
    }
  }

  /**
   * Handle ModeratorAdded event
   */
  private async handleModeratorAdded(userId: string): Promise<void> {
    const result = await this.roleService.assignRole(userId, RoleType.MODERATOR);
    if (!result.success) {
      // If role already exists, that's okay
      if (!result.message?.includes('already has')) {
        throw new Error(`Failed to assign moderator role: ${result.message}`);
      }
    }
    console.log(`Moderator role assigned to user ${userId}`);
  }

  /**
   * Handle ModeratorRemoved event
   */
  private async handleModeratorRemoved(userId: string): Promise<void> {
    const result = await this.roleService.revokeRole(userId, RoleType.MODERATOR);
    if (!result.success) {
      // If role doesn't exist, that's okay
      if (!result.message?.includes('does not have')) {
        throw new Error(`Failed to revoke moderator role: ${result.message}`);
      }
    }
    console.log(`Moderator role revoked from user ${userId}`);
  }

  /**
   * Batch process multiple contract events
   */
  async processBatchEvents(events: ContractEvent[]): Promise<{ processed: number; failed: number }> {
    let processed = 0;
    let failed = 0;

    for (const event of events) {
      try {
        await this.processContractEvent(event);
        processed++;
      } catch (error) {
        failed++;
        console.error(`Failed to process event for user ${event.userId}:`, error);
      }
    }

    return { processed, failed };
  }
}

// Example usage with Web3 or ethers.js (placeholder)
export class ContractEventListener {
  private syncService: ContractSyncService;

  constructor() {
    this.syncService = new ContractSyncService();
  }

  /**
   * Initialize contract event listening
   * This is a placeholder - replace with actual Web3/ethers.js implementation
   */
  async startListening(): Promise<void> {
    console.log('Starting contract event listener...');

    // Placeholder for contract event listening
    // In a real implementation, you would:
    // 1. Connect to your blockchain provider
    // 2. Set up event filters for your contract
    // 3. Listen for ModeratorAdded and ModeratorRemoved events
    // 4. Call this.syncService.processContractEvent() for each event

    // Example:
    // const contract = new ethers.Contract(contractAddress, abi, provider);
    // contract.on('ModeratorAdded', async (userId, event) => {
    //   await this.syncService.processContractEvent({
    //     type: 'ModeratorAdded',
    //     userId,
    //     blockNumber: event.blockNumber,
    //     transactionHash: event.transactionHash
    //   });
    // });
  }

  /**
   * Stop listening to contract events
   */
  async stopListening(): Promise<void> {
    console.log('Stopping contract event listener...');
    // Implement cleanup logic here
  }
}
