import { container } from "tsyringe";
import RoleInitializationService from "./services/roleInitialization";
import ContractEventListener from "./services/contractEventListener";
import logger from "./config/logger";

export async function initializeRoleSystem(): Promise<void> {
	try {
		logger.info("Initializing role management system...");

		// Initialize role services
		const roleInitService = container.resolve(RoleInitializationService);
		const contractEventListener = container.resolve(ContractEventListener);

		// Migrate existing users if needed
		await roleInitService.migrateExistingUsers();

		// Validate role system integrity
		const validation = await roleInitService.validateRoleSystemIntegrity();
		if (!validation.isValid) {
			logger.warn("Role system validation issues found:", validation.issues);
		} else {
			logger.info("Role system validation passed");
		}

		// Start contract event listener
		if (process.env.ENABLE_CONTRACT_LISTENER !== "false") {
			await contractEventListener.startListening();
		}

		logger.info("Role management system initialized successfully");
	} catch (error: any) {
		logger.error(`Failed to initialize role system: ${error.message}`);
		// Don't throw error to prevent server startup failure
	}
}
